import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourCapability;
import Vino.AI.ScenePoints.ScenePointComponent;

// Note larva hatching is done locally to avoid excessive reliable netmsgs.
// this means we handle some stuff  differently from regular larva behaviors.
class ULarvaBehaviourHatchCapability : ULarvaBehaviourCapability
{
    default State = ELarvaState::Hatching;
	
	float HatchedCountdown = 0.f; // Count down until hatching instead of timestamp, since we expect to be disabled during part of the process 
	bool bWaitingForSync = false;
	UScenepointComponent HatchPoint = nullptr;
	FVector StartLoc;

	FHazeAcceleratedRotator MeshRotation;
	UHazeSkeletalMeshComponentBase Mesh;

	bool bIsLanding = false;
	float LandingDuration = 0.f;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComponent.State != State)
    		return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComponent.State != State)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		StartLoc = Owner.ActorLocation;

		// This is network synced by spawner
		HatchPoint = BehaviourMoveComp.HatchPoint;
		
		FHazeAnimationDelegate OnAnimDone;
		OnAnimDone.BindUFunction(this, n"OnStartAnimDone");
		Owner.PlaySlotAnimation(OnBlendingOut = OnAnimDone, Animation = BehaviourComponent.AnimFeature.Hatch_Start, bLoop = false);

		bIsLanding = false;
		LandingDuration = (BehaviourComponent.AnimFeature.Hatch_Land == nullptr) ? 0.f : BehaviourComponent.AnimFeature.Hatch_Land.GetPlayLength();
		bWaitingForSync = false;

		if (HatchPoint == nullptr)
		{
			// Just leap out of the egg
	        BehaviourMoveComp.LeapTowards(Owner.GetActorLocation() + FVector(0.f, 0.f, 700.f));
			HatchedCountdown = 1.f;
		}
		else
		{
			// Leap towards scenepoint
			BehaviourMoveComp.LaunchToScenepoint(HatchPoint);
			HatchedCountdown = 3.f; // Max launch time
		}

		MeshRotation.SnapTo(BehaviourComponent.HatchRotation);
		Mesh = UHazeSkeletalMeshComponentBase::Get(Owner);
		Mesh.SetWorldRotation(MeshRotation.Value);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BehaviourComponent.CurrentActivePriority = ELarvaPriority::None;
	}

	UFUNCTION()
	void OnStartAnimDone()
	{
		if (IsActive() && !bIsLanding)
			Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Hatch_Mh, bLoop = true, BlendTime = 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HatchedCountdown -= DeltaTime;

		if ((HatchPoint != nullptr) && !bIsLanding && IsDoneLeapingToHatchPoint())
		{
			// Time to land!
			bIsLanding = true;
			HatchedCountdown = LandingDuration;
			FHazeAnimationDelegate OnAnimDone;
			OnAnimDone.BindUFunction(this, n"OnLandAnimDone");
			Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Hatch_Land, bLoop = false, OnBlendingOut = OnAnimDone);
		}

		// Turn mesh towards actor rotation so we'll be aligned when landing
		MeshRotation.AccelerateTo(Owner.ActorRotation, FMath::Max(0.001f, HatchedCountdown), DeltaTime);
		Mesh.SetWorldRotation(MeshRotation.Value);

		// Use full sync point to exit hatching and enter normal behaviour
		if (!bWaitingForSync && (HatchedCountdown <= 0.f))
		{
			bWaitingForSync = true;
			Sync::FullSyncPoint(this, n"HatchComplete");
		}
	}

	UFUNCTION()
	void OnLandAnimDone()
	{
		if (IsActive() && (BehaviourComponent.State == ELarvaState::Hatching))
			Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Idle_Mh, bLoop = true, BlendTime = 0.2f);
	}

	UFUNCTION(NotBlueprintCallable)
	void HatchComplete()
	{
		// This will make larva start using crumbed behaviours again
		// To avoid an extra activation crumb, we allow larva to skip idle state if suitable
        if (BehaviourComponent.CanEatSap())
            BehaviourComponent.State = ELarvaState::Stunned; 
        else if (BehaviourComponent.GetTarget() != nullptr)
            BehaviourComponent.State = ELarvaState::Pursue; 
		else 
			BehaviourComponent.State = ELarvaState::Idle;
		BehaviourMoveComp.CrawlTo(Owner.ActorLocation + Owner.ActorForwardVector * 1.f);
		Mesh.SetWorldRotation(Owner.ActorRotation);
	}

	bool IsDoneLeapingToHatchPoint()
	{
		if (HatchedCountdown < LandingDuration)
			return true;

		if (BehaviourMoveComp.CurrentScenepoint != HatchPoint)
			return true;

		FVector2D ToSpXY = FVector2D(HatchPoint.WorldLocation - Owner.ActorLocation);
		if ((Owner.ActorLocation.Z < HatchPoint.WorldLocation.Z + 200.f) &&
			(ToSpXY.SizeSquared() < FMath::Square(200.f)))
			return true;

		// Check horizontal overshoot
		FVector2D FromStartXY = FVector2D(Owner.ActorLocation - StartLoc);
		if (FromStartXY.DotProduct(ToSpXY) < 0.f)
			return true;

		return false;
	}
}
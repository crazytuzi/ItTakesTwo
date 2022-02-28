import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonIntersectionPoint;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonPathSpline;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboon;
import Peanuts.Animation.Features.PlayRoom.MoonBaboonOnMoon;
import Vino.Movement.Components.MovementComponent;

UCLASS(Abstract)
class UMoonBaboonJetpackJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"MoonBaboonMovement");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	bool bLanding = false;
	bool bLanded = false;

	AMoonBaboonIntersectionPoint TargetLandingPoint;
	UHazeMovementComponent MoveComp;

	UPROPERTY()
	FHazeTimeLike LandingTimeLike;
	default LandingTimeLike.Duration = 1.f;

	FVector StartLocation;
	FVector EndLocation;

	FRotator StartRotation;
	FRotator EndRotation;

	bool bMaxHeightReached = false;

	AActor MoonMid;

	AMoonBaboon MoonBaboon;

	UPROPERTY()
	ULocomotionFeatureMoonBaboonOnMoon Feature;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		LandingTimeLike.SetPlayRate(0.5f);
		LandingTimeLike.BindUpdate(this, n"UpdateLanding");
		LandingTimeLike.BindFinished(this, n"FinishLanding");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"JetpackJumping"))
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bLanded)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetCapabilityActionState(n"JetpackJumping", EHazeActionState::Inactive);
		MoonBaboon = Cast<AMoonBaboon>(GetAttributeObject(n"MoonBaboon"));
		MoonMid = Cast<AActor>(GetAttributeObject(n"MoonMid"));
		TargetLandingPoint = Cast<AMoonBaboonIntersectionPoint>(GetAttributeObject(n"TargetLandingPoint"));

		SetMutuallyExclusive(n"MoonBaboonMovement", true);
		Owner.BlockCapabilities(CapabilityTags::Collision, this);
		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(n"Gravity", this);

		FHazeAnimationDelegate OnHitReactionFinished;
		OnHitReactionFinished.BindUFunction(this, n"StartFlying");
		Owner.PlaySlotAnimation(OnBlendingOut = OnHitReactionFinished, Animation = Feature.HitReaction.Sequence);

		MoonBaboon.SetActorEnableCollision(false);

		// Owner.BlockMovementSyncronization(this);
		MoonBaboon.TriggerMovementTransition(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MoonBaboon.ChangeActorWorldUp(TargetLandingPoint.ActorUpVector);
		bLanding = false;
		bLanded = false;
		bMaxHeightReached = false;
		Owner.SetAnimBoolParam(n"Landing", true);
		SetMutuallyExclusive(n"MoonBaboonMovement", false);
		Owner.UnblockCapabilities(CapabilityTags::Collision, this);
		Owner.UnblockCapabilities(n"Gravity", this);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		MoonBaboon.Landed();
		MoonBaboon.SetActorEnableCollision(true);

		Owner.UnblockMovementSyncronization(this);
	}

	UFUNCTION()
	void StartFlying()
	{
		MoonMid.SetActorRotation(Owner.ActorUpVector.Rotation());
		Owner.AttachToActor(MoonMid, AttachmentRule = EAttachmentRule::KeepWorld);
		FHazeAnimationDelegate OnFlyingStarted;
		OnFlyingStarted.BindUFunction(this, n"FlyingStarted");
		Owner.PlaySlotAnimation(OnBlendingOut = OnFlyingStarted, Animation = Feature.HoveringToFlying.Sequence);
		bMaxHeightReached = true;
	}

	UFUNCTION()
	void FlyingStarted()
	{
		Owner.PlaySlotAnimation(Animation = Feature.JetpackFlyingMH.Sequence, bLoop = true);
	}

	UFUNCTION()
	void UpdateLanding(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		Owner.SetActorLocation(CurLoc);
	}

	UFUNCTION()
	void FinishLanding()
	{
		FHazeAnimationDelegate OnLandingFinished;
		OnLandingFinished.BindUFunction(this, n"LandingFinished");
		Owner.PlaySlotAnimation(OnBlendingOut = OnLandingFinished, Animation = Feature.JetpackLanding.Sequence);
	}

	UFUNCTION()
	void LandingFinished()
	{
		bLanded = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (bMaxHeightReached && !bLanding)
		{
			FRotator CurRot = FMath::RInterpConstantTo(MoonMid.ActorRotation, TargetLandingPoint.ActorUpVector.Rotation(), DeltaTime, 25.f);
			CurRot.Normalize();
			MoonMid.SetActorRotation(CurRot);

			FVector Dif = TargetLandingPoint.ActorUpVector - CurRot.Vector();

			if (Dif.IsNearlyZero())
			{
				bLanding = true;
				StartLanding();
			}
		}
	}

	void StartLanding()
	{
		FHazeAnimationDelegate OnLandingStarted;
		OnLandingStarted.BindUFunction(this, n"LandingMH");
		Owner.PlaySlotAnimation (OnBlendingOut = OnLandingStarted, Animation = Feature.JetpackLanding.Sequence);

		TargetLandingPoint.ChooseNewSpline(Owner);
		Owner.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Owner.SetCapabilityAttributeVector(n"ForcedWorldUp", TargetLandingPoint.ActorUpVector);
		StartLocation = Owner.ActorLocation;
		EndLocation = TargetLandingPoint.ActorLocation;
		LandingTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void LandingMH()
	{
		Owner.PlaySlotAnimation(Animation = Feature.JetpackLandingMH.Sequence, bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{

	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		if(IsActive())
		{
			FString DebugText = "";
			if(HasControl())
			{
				DebugText += "Control Side\n";
			}
			else
			{
				DebugText += "Slave Side\n";
			}
			return DebugText;
		}

		return "Not Active";
	}
}
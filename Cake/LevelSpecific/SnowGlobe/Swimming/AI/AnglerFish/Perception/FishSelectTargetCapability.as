import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Vino.AI.Components.GentlemanFightingComponent;

class UFishSelectTargetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FishBehaviour");
	default TickGroup = ECapabilityTickGroups::GamePlay;

    UFishBehaviourComponent BehaviourComponent = nullptr;
	UHazeCrumbComponent CrumbComp = nullptr;
	UFishComposableSettings Settings = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComponent = UFishBehaviourComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
        ensure((BehaviourComponent != nullptr) && (Settings != nullptr) && (CrumbComp != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Control side only
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate; 

		// Do we need a new target?
		if (BehaviourComponent.HasValidTarget())
			return EHazeNetworkActivation::DontActivate; 

        if (BehaviourComponent.State != EFishState::Idle)
            return EHazeNetworkActivation::DontActivate; 

		if (BehaviourComponent.GetStateDuration() < 1.f)
            return EHazeNetworkActivation::DontActivate; 

		// Cooldown after attack
		if (Time::GetGameTimeSince(BehaviourComponent.SustainedAttackEndTime) < 5.f)
			return EHazeNetworkActivation::DontActivate; 

       	return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (BehaviourComponent.State != EFishState::Idle)
            return EHazeNetworkDeactivation::DeactivateLocal; 
		if (BehaviourComponent.HasValidTarget())
			return EHazeNetworkDeactivation::DeactivateLocal; 
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (!ensure(BehaviourComponent.VisionCone != nullptr))
			Print("WARNING! " + Owner + " does not have a vision cone and will not see anything! Set BehaviourComponent.VisionCone in BP constructionscript.");
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		// Always continue hunting current target while possible
        AHazeActor CurTarget = BehaviourComponent.GetTarget();
        if (!BehaviourComponent.CanHuntTarget(CurTarget))
        {
			AHazeActor NewTarget = SelectTarget();
			if (NewTarget != CurTarget)
			{
				FHazeDelegateCrumbParams CrumbParams;
				CrumbParams.AddObject(n"Target", NewTarget);
				CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbSetTarget"), CrumbParams);
			}
        }
    }

	UFUNCTION()
	void CrumbSetTarget(const FHazeDelegateCrumbData& CrumbData)
	{
		BehaviourComponent.SetTarget(Cast<AHazeActor>(CrumbData.GetObject(n"Target")));
	}	

    AHazeActor SelectTarget()
    {
		if (!ensure(BehaviourComponent.VisionCone != nullptr))
			return nullptr;

		// Check which targets we're allowed to hunt
		TArray<AHazeActor> Targets;
        TArray<AHazePlayerCharacter> PotentialTargets = Game::GetPlayers();
        for (AHazePlayerCharacter PotentialTarget : PotentialTargets)
        {
			if (BehaviourComponent.CanHuntTarget(PotentialTarget))
				Targets.Add(PotentialTarget);
		}

		// Find the best one of these which we can perceive
		AHazeActor BestTarget = GetBestVisionSphereTarget(BehaviourComponent.VisionSphere, Targets);
		if (BestTarget == nullptr)
			BestTarget = GetBestVisionConeTarget(BehaviourComponent.VisionCone, BehaviourComponent.VisionSphere.WorldLocation, Targets);
		return BestTarget;
	}

	AHazeActor GetBestVisionSphereTarget(USphereComponent Sphere, TArray<AHazeActor> Targets)
	{
		if (Sphere == nullptr)
			return nullptr;
		
		// Check for targets within sphere, ignoring of line of sight
		AHazeActor BestTarget = nullptr;
		float ClosestDistSqr = FMath::Square(Sphere.GetScaledSphereRadius());
		FVector Center = Sphere.WorldLocation;
        for (AHazeActor Target : Targets)
        {
			float DistSqr = Target.ActorLocation.DistSquared(Center);
			if (DistSqr < ClosestDistSqr)
			{
				ClosestDistSqr = DistSqr;
				BestTarget = Target;
			}
		}		
		return BestTarget;
	}

	AHazeActor GetBestVisionConeTarget(UStaticMeshComponent VisionCone, const FVector& LineOfSightOrigin, TArray<AHazeActor> Targets)
	{
		if (VisionCone == nullptr)
			return nullptr;

		// Check for targets within vision cone and line of sight
	 	FTransform Transform = VisionCone.WorldTransform;
		float Length = Transform.Scale3D.Z * 100.f;
		float EndRadius = Transform.Scale3D.X * 50.f;
		Transform.ConcatenateRotation(FQuat(FRotator(-90.f,0.f,0.f))); // Point down forward
		FVector Dir = Transform.Rotation.ForwardVector;
		Transform.SetLocation(Transform.Location - Dir * Length * 0.5f); // Place location at point (where lantern is)

		Transform.Scale3D = FVector::OneVector;
		FTransform VisionWorldToLocal = Transform.Inverse();

        AHazeActor BestTarget = nullptr;
		float MinCosAngle = -1.f;
        for (AHazeActor Target : Targets)
        {
			FVector TargetLocalLoc = VisionWorldToLocal.TransformPosition(Target.ActorLocation);
			if ((TargetLocalLoc.X > 0.f) && (TargetLocalLoc.X < Length))
			{
				// In front and not too far away. 
				float DistFromCenterSqr = FMath::Square(TargetLocalLoc.Y) + FMath::Square(TargetLocalLoc.Z);
				float RadiusAtTarget = TargetLocalLoc.X * EndRadius / Length;
				if (FMath::Square(RadiusAtTarget) > DistFromCenterSqr)
				{
					// Target is in vision cone, choose the one closest to actor forward (Note: not vision cone forward!)
					FVector ToTarget = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
					float CosAngle = ToTarget.DotProduct(BehaviourComponent.MawForwardVector);
					if (CosAngle > MinCosAngle)
					{
						if (HasLineOfSight(LineOfSightOrigin, Target))
						{
							BestTarget = Target;
							MinCosAngle = CosAngle;
						}
					}
				}  					  
			}
		}

		// System::DrawDebugLine(Transform.Location, Transform.Location + Dir * Length, FLinearColor::Red, 0.f, 30.f);
		// System::DrawDebugCircle(Transform.Location + Dir * Length, EndRadius, 20, FLinearColor::Red, 0.f, 30.f, Transform.Rotation.RightVector, Transform.Rotation.UpVector);

        return BestTarget;
    }

	bool HasLineOfSight(const FVector& Origin, AHazeActor Target)
	{
		// Check line of sight
		FHazeTraceParams TraceParams;
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		TraceParams.IgnoreActor(Owner);
		TraceParams.From = Origin;
		TraceParams.To = Target.ActorLocation;
		TraceParams.SetToLineTrace();
		FHazeHitResult Hit;
		
		if (!TraceParams.Trace(Hit))
			return true; // No obstructions
		
		if (Hit.Actor == Target)
			return true; // Only obstructed by target
		
		// Something blocks los
		return false;
	}

}

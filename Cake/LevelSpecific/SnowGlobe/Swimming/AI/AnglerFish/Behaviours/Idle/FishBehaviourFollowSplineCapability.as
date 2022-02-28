import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourFollowSplineCapability : UFishBehaviourCapability
{
    default State = EFishState::Idle;
	default SetPriority(EFishBehaviourPriority::Maximum);

	float DistanceAlongSpline = 0.f;
	UHazeSplineComponent Spline = nullptr;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
			return EHazeNetworkActivation::DontActivate;	
		if (BehaviourComponent.FollowSpline == nullptr)
    		return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		// Check if we should still follow the same spline (or should stop follow splines altogether)
		if (BehaviourComponent.FollowSpline != Spline)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Spline", BehaviourComponent.FollowSpline);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// Always start at the beginning for now
		BehaviourComponent.DistanceAlongMoveSpline = 0.f;
		BehaviourComponent.bSnapToMoveSpline = true;
		Spline = Cast<UHazeSplineComponent>(ActivationParams.GetObject(n"Spline"));
		BehaviourComponent.FollowSpline = Spline;
		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
		AnimComp.SetAgitated(false);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		// Don't try to engage something when following spline
		float SplineLength = Spline.GetSplineLength();
		if (BehaviourComponent.DistanceAlongMoveSpline + 10.f > SplineLength)
		{
			// Use a normal move in spline end tangent
			FVector FinishDir = Spline.GetTangentAtDistanceAlongSpline(SplineLength, ESplineCoordinateSpace::World);
			BehaviourComponent.MoveTo(Owner.ActorLocation + FinishDir * 1000.f, Settings.IdleAcceleration, Settings.IdleTurnDuration);
			BehaviourComponent.StopFollowingSpline();
			return;
		}

		// Keep moving along spline
		BehaviourComponent.MoveAlongSpline(Spline, Settings.IdleAcceleration);
    }
}
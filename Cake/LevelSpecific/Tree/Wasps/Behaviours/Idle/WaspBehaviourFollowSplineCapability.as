import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourFollowSplineCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Idle;
	default SetPriority(EWaspBehaviourPriority::High);

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
		// Always start at the beginning for now
		Super::OnActivated(ActivationParams);
		BehaviourComponent.DistanceAlongMoveSpline = 0.f;
		BehaviourComponent.bSnapToMoveSpline = true;
		Spline = Cast<UHazeSplineComponent>(ActivationParams.GetObject(n"Spline"));
		BehaviourComponent.StartFollowingSpline(Spline);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		// Ignore saps, and don't try to engage something when following spline

		if (Settings.bTrackTargetWhenFollowingSpline && BehaviourComponent.HasValidTarget())
			BehaviourComponent.RotateTowards(BehaviourComponent.Target.GetFocusLocation());	

		float SplineLength = Spline.GetSplineLength();
		if (BehaviourComponent.DistanceAlongMoveSpline + 10.f > SplineLength)
		{
			// Use a normal move in spline end tangent
			FVector FinishDir = Spline.GetTangentAtDistanceAlongSpline(SplineLength, ESplineCoordinateSpace::World);
			BehaviourComponent.MoveTo(Owner.ActorLocation + FinishDir * 1000.f, Settings.IdleAcceleration);
			BehaviourComponent.StopFollowingSpline();
			return;
		}

		// Keep moving along spline
		BehaviourComponent.MoveAlongSpline(Spline, Settings.IdleAcceleration);
    }
}
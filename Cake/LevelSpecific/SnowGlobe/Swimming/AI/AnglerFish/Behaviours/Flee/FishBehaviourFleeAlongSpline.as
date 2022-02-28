import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;
import Peanuts.Spline.SplineComponent;

class UFishBehaviourFleeAlongSplineCapability : UFishBehaviourCapability
{
    default State = EFishState::Flee;
    default SetPriority(EFishBehaviourPriority::High);

	UHazeSplineComponent FleeSpline = nullptr;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
			return EHazeNetworkActivation::DontActivate;	

		if (BehaviourComponent.FleeSplines.Num() == 0)
			return EHazeNetworkActivation::DontActivate;	

	  	return EHazeNetworkActivation::ActivateUsingCrumb; 
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;	

		// Check if flee spline is still valid
		if (!System::IsValid(FleeSpline)) 
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 
		if (!BehaviourComponent.FleeSplines.Contains(FleeSpline))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Spline", GetFleeingSpline());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		FleeSpline = Cast<UHazeSplineComponent>(ActivationParams.GetObject(n"Spline")); 
		ensure(FleeSpline != nullptr);
		BehaviourComponent.MovingAlongSpline = FleeSpline;
		BehaviourComponent.DistanceAlongMoveSpline = 0.f;
		BehaviourComponent.bSnapToMoveSpline = true;
		EffectsComp.SetEffectsMode(EFishEffectsMode::Idle);
		AnimComp.SetGapingPercentage(0.f);
		AnimComp.SetAgitated(false);
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		if (BehaviourComponent.DistanceAlongMoveSpline > FleeSpline.GetSplineLength() - 500.f)
		{
			// We're near the end of the line, disable ourselves
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbFlightComplete"), FHazeDelegateCrumbParams());
			return;
		}

		// Keep moving along spline
		BehaviourComponent.MoveAlongSpline(FleeSpline, Settings.FleeAcceleration, true);
    }

	UFUNCTION(NotBlueprintCallable)
	void CrumbFlightComplete(const FHazeDelegateCrumbData& CrumbData)
	{
		BehaviourComponent.bAllowDisable = true;
		Owner.DisableActor(Owner);
		Owner.SetActorHiddenInGame(true); // Since disabling fish might not hide mesh
	}

	UHazeSplineComponent GetFleeingSpline()
	{
		for (UHazeSplineComponent Spline : BehaviourComponent.FleeSplines)
		{
			if (Spline != nullptr)
				return Spline;
		}
		return nullptr;
	}
}

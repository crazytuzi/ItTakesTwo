import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourEntryScenepointCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Idle;
	default SetPriority(EWaspBehaviourPriority::Normal);

	UScenepointComponent Scenepoint = nullptr;
	FVector StartingDir;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
		if (BehaviourComponent.CurrentScenepoint == nullptr)
    		return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() == EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Check if we should still follow the same scenepoint
		if (BehaviourComponent.CurrentScenepoint != Scenepoint)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Scenepoint", BehaviourComponent.CurrentScenepoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Always start at the beginning for now
		Super::OnActivated(ActivationParams);
		Scenepoint = Cast<UScenepointComponent>(ActivationParams.GetObject(n"Scenepoint")); 
		BehaviourComponent.UseScenepoint(Scenepoint);
		StartingDir = (Scenepoint.GetWorldLocation() - Owner.GetActorLocation()).GetSafeNormal();
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		// Ignore saps, and don't try to engage something when moving to entry scenepoint

		if (Settings.bTrackTargetWhenFollowingSpline && BehaviourComponent.HasValidTarget())
			BehaviourComponent.RotateTowards(BehaviourComponent.Target.GetFocusLocation());	

		if (HasReachedScenepoint())
		{
			BehaviourComponent.UseScenepoint(nullptr);

			return;
		}

		// Keep moving along spline
		BehaviourComponent.MoveTo(Scenepoint.GetWorldLocation(), Settings.IdleAcceleration);
    }

	bool HasReachedScenepoint()
	{
		FVector ToSP = Scenepoint.WorldLocation - Owner.ActorLocation;
		if (ToSP.SizeSquared() < FMath::Square(Scenepoint.Radius))
			return true;
		
		// Allow overshooting, just as long as we've passed sp
		if (ToSP.DotProduct(StartingDir) < 0.f)
			return true;

		// Still en route
		return false;
	}
}
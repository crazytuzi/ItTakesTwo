import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Vino.AI.Scenepoints.ScenepointComponent;

class UWaspBehaviourCombatPositioningCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Combat;
    default SetPriority(EWaspBehaviourPriority::High);

	UScenepointComponent Scenepoint = nullptr;
	FVector StartingDir;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
        if (!HasAvailableScenepoints())
            return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

    bool HasAvailableScenepoints() const
    {
        if (BehaviourComponent.CurrentScenepoint != nullptr)
			return true;

		return false;
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Scenepoint", BehaviourComponent.CurrentScenepoint);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Scenepoint = Cast<UScenepointComponent>(ActivationParams.GetObject(n"Scenepoint"));
		BehaviourComponent.UseScenepoint(Scenepoint);
		StartingDir = (Scenepoint.GetWorldLocation() - Owner.GetActorLocation()).GetSafeNormal();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (HealthComp.IsSapped())
        {
            // Sapped!
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

        if (!BehaviourComponent.HasValidTarget() || (Scenepoint == nullptr))
        {
            // Lost target
            BehaviourComponent.State = EWaspState::Idle; 
            return;
        }

        AHazeActor Target = BehaviourComponent.GetTarget();
		if (HasReachedScenepoint())
		{
            // Make sure we're fighting fair by only starting attack if we can claim that privilege
            if (BehaviourComponent.ClaimGentlemanAction(n"WaspAttack", Target))
            {
                // We can start an attack run
                BehaviourComponent.State = EWaspState::Telegraphing;
            }
            // Drift to a stop
            return;
		}

		// Move to scenepoint
        BehaviourComponent.MoveTo(Scenepoint.WorldLocation, Settings.EngageAcceleration);
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


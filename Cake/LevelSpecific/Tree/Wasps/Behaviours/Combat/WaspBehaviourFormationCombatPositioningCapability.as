import Vino.AI.Scenepoints.ScenepointComponent;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspLocalBehaviourCapability;

class UWaspBehaviourFormationCombatPositioningCapability : UWaspLocalBehaviourCapability
{
    default State = EWaspState::Combat;
	UScenepointComponent Scenepoint = nullptr;
	FVector StartingDir;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Scenepoint = BehaviourComponent.CurrentScenepoint;
		ensure(Scenepoint != nullptr);
		StartingDir = (Scenepoint.GetWorldLocation() - Owner.GetActorLocation()).GetSafeNormal();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (HasReachedScenepoint())
		{
            // We can start an attack run
            BehaviourComponent.State = EWaspState::Telegraphing;
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


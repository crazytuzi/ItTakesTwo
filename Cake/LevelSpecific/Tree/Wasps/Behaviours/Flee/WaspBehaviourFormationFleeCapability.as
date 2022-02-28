import Cake.LevelSpecific.Tree.Wasps.Scenepoints.WaspFormationScenepoint;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspLocalBehaviourCapability;

class UWaspBehaviourFormationFleeCapability : UWaspLocalBehaviourCapability
{
    default State = EWaspState::Flee;

	UWaspFormationScenepointComponent Scenepoint = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Scenepoint = Cast<UWaspFormationScenepointComponent>(BehaviourComponent.CurrentScenepoint);
		BehaviourComponent.UseScenepoint(Scenepoint);
		HealthComp.RemoveHealthBars();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		// Have we passed flee location?
		FVector FleeDestination = Scenepoint.GetFormationFleeLocation();
		FVector ToFleeLoc = Scenepoint.GetFormationFleeLocation() - Owner.ActorLocation;
		FVector FleeDir = FleeDestination - Scenepoint.GetFormationDestination();
		if ((ToFleeLoc.DotProduct(FleeDir) < 0.f) && (HasControl()))
		{
			NetDisable();	
			return;
		}

        BehaviourComponent.MoveTo(FleeDestination, Settings.FleeAcceleration);
    }

	UFUNCTION(NetFunction)
	void NetDisable()
	{
        Owner.DisableActor(Owner);
	}
}

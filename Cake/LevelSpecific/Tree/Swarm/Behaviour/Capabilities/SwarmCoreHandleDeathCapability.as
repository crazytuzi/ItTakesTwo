
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.Weapons.Sap.SapManager;

class USwarmCoreHandleDeathCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmCoreHandleDeath");

	// It is probably better to handle this at the end 
	default TickGroup = ECapabilityTickGroups::PostWork;

	ASwarmActor SwarmActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SwarmActor.IsAboutToDie())
 			return EHazeNetworkActivation::DontActivate;

		// OnAboutToDie is networked
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SwarmActor.AreParticlesAlive())
			return EHazeNetworkDeactivation::DontDeactivate;

		// OnDie isn't networked.
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.OnAboutToDie.Broadcast(SwarmActor);
 	}

 	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAudio();

		// We broadcast before disabling in order to ensure 
		// that components are active and actor references are valid.
		SwarmActor.OnDie.Broadcast(SwarmActor);

//		PrintToScreenScaled("SwarmWallDestroyed", 1.f);
		UHazeAkComponent::HazePostEventFireForget(SwarmActor.SwarmWallDestroyedEvent, SwarmActor.GetActorTransform());

		SwarmActor.DisableActor(nullptr);
//		SwarmActor.DestroyActor();
	}

}

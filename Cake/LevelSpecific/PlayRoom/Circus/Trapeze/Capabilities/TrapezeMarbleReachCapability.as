import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Peanuts.Network.MeshPhysicsReplicationComponent;

class UTrapezeMarbleReachCapability : UHazeCapability
{
	default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::MarbleReach);

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	AHazePlayerCharacter PlayerOwner;
	UTrapezeComponent TrapezeComponent;

	ATrapezeActor Trapeze;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);

		Trapeze = Cast<ATrapezeActor>(TrapezeComponent.TrapezeActor);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TrapezeComponent.ShouldReachForMarble(Trapeze.Marble, Trapeze.bIsCatchingEnd))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		ATrapezeActor TrapezeActor = Cast<ATrapezeActor>(TrapezeComponent.TrapezeActor);

		if(Network::IsNetworked())
			UMeshPhysicsReplicationComponent::Get(TrapezeActor).RequestInstantReplicationForFrame();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Trapeze = Cast<ATrapezeActor>(TrapezeComponent.TrapezeActor);
		Trapeze.AnimationDataComponent.bIsReaching = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TrapezeComponent.ShouldReachForMarble(Trapeze.Marble, Trapeze.bIsCatchingEnd))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Trapeze.AnimationDataComponent.bIsReaching = false;
	}
}
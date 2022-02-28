import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;

class UTreeBeetleRidingLockCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"BeetleRiding";

	default CapabilityTags.Add(n"BeetleRiding");

	UTreeBeetleRidingComponent BeetleRidingComponent;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!BeetleRidingComponent.Beetle.bIsMayOn || !BeetleRidingComponent.Beetle.bIsCodyOn)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BeetleRidingComponent.Beetle == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BeetleRidingComponent.Beetle.BeginRide();
		Player.BlockCapabilities(n"BeetleRidingCancel", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"BeetleRidingCancel", this);
	}
}
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunPlayerComponent;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager;

class UPlungerGunPlayerGiveUpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 90;

	AHazePlayerCharacter Player;
	UPlungerGunPlayerComponent GunComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GunComp = UPlungerGunPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GunComp.Gun == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!PlungerGunGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// This capability doesn't actually leave, it just requests a give up
		// If the request is granted, the game will end naturally, assuring a safe exit
		PlungerGunManager.NetRequestGiveUp(Player);
	}
}
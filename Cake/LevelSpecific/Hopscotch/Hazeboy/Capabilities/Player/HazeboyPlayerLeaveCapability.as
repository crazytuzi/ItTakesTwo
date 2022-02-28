import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyPlayerComponent;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class UHazeboyPlayerLeaveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UHazeboyPlayerComponent HazeboyComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeboyComp = UHazeboyPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HazeboyComp.CurrentDevice == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::DontActivate;

		auto Manager = GetHazeboyManager();
		if (!Manager.DoubleInteract.CanPlayerCancel(Player))
			return EHazeNetworkActivation::DontActivate;

		if (Manager.State != EHazeboyGameState::Title)
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
		auto Manager = GetHazeboyManager();
		Manager.DoubleInteract.CancelInteracting(Player);

		HazeboyComp.bHasCancelled = true;
	}
}
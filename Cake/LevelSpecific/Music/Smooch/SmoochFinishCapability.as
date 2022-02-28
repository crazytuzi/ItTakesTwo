import Cake.LevelSpecific.Music.Smooch.Smooch;
import Cake.LevelSpecific.Music.Smooch.SmoochNames;

class USmoochFinishCapability : UHazeCapability
{
	default CapabilityTags.Add(Smooch::Smooch);
	default CapabilityDebugCategory = n"Smooch";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	USmoochUserComponent SmoochComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// May handles finishing
		if (!Player.IsMay())
			return EHazeNetworkActivation::DontActivate;

		if (GetSmoochNumPlayersHolding() != 2)
			return EHazeNetworkActivation::DontActivate;

		if (!HasBothPlayersFinishedSmooch())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SmoochComp.FinishProgress();
	}
}

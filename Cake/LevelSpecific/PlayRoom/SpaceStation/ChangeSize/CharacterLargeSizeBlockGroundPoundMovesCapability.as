import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;

class UCharacterLargeSizeBlockGroundPoundMovesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;
	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterGroundPoundComponent GroundPoundComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GroundPoundComp = UCharacterGroundPoundComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Landing))
   			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Landing))
		{
			if (!GroundPoundComp.IsCurrentState(EGroundPoundState::StandingUp))
				return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementDash);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
	}
}

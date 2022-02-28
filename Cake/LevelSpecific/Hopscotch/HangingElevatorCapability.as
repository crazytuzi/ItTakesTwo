import Cake.LevelSpecific.Hopscotch.HangingElevator;
import Vino.Interactions.InteractionComponent;

class UHangingElevatorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UInteractionComponent InteractionComp;
	AHangingElevator HangingElevator;

	UPROPERTY()
	UAnimSequence HangAnimCody;
	
	UPROPERTY()
	UAnimSequence HangAnimMay;

	bool bCanExitCapability;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (HangingElevator != nullptr)
			return EHazeNetworkActivation::ActivateFromControl;

		else
        	return EHazeNetworkActivation::DontActivate;
        // return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (HangingElevator == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		else
			return EHazeNetworkDeactivation::DontDeactivate;
		// return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::TotemMovement, this);
		Player.BlockCapabilities(CapabilityTags::LevelSpecific, this);
		Player.TriggerMovementTransition(this);

		UAnimSequence AnimToPlay = Game::GetCody() == Player ? HangAnimCody : HangAnimMay;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimToPlay, true);

		InteractionComp = Cast<UInteractionComponent>(GetAttributeObject(n"InteractionComponent"));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);
		Player.UnblockCapabilities(CapabilityTags::LevelSpecific, this);

		Player.StopAllSlotAnimations();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject HangTemp;
		if (ConsumeAttribute(n"HangingElevator", HangTemp))
		{
			HangingElevator = Cast<AHangingElevator>(HangTemp);
			Print("HEEH", 2.f);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Print("ACTIVE");

		if (IsActioning(ActionNames::Cancel))
		{	
			HangingElevator.DetachPlayerFromActor(Player, InteractionComp);
			HangingElevator = nullptr;
		}
	}
}
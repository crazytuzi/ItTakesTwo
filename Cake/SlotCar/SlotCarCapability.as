import Vino.Interactions.DoubleInteractionActor;
import Cake.SlotCar.SlotCarActor;
import Cake.SlotCar.SlotCarTrackActor;

class USlotCarCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"SlotCar";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	
    ASlotCarTrackActor SlotCarTrack;
	AHazePlayerCharacter Player;

   	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SlotCarTrack == nullptr)
			SlotCarTrack = Cast<ASlotCarTrackActor>(GetAttributeObject(n"SlotCarInteraction"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SlotCarTrack == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SlotCarTrack.RaceStage == ESlotCarRaceStage::Idle)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SlotCarTrack == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SlotCarTrack.RaceStage == ESlotCarRaceStage::Idle)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SlotCarTrack.bEnterAnimationComplete[Player] = false;

		const FSlotCarPlayerAnimations& Animations = SlotCarTrack.GetAnimations(Player);
		Owner.PlaySlotAnimation(
			Animation = Animations.Enter,
			OnBlendingOut = FHazeAnimationDelegate(this, n"OnEnterAnimationFinished")
		);

		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);

		Player.TriggerMovementTransition(this);
		Player.AttachRootComponentTo(SlotCarTrack.ActiveInteractions[Player], AttachLocationType = EAttachLocation::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.StopAllSlotAnimations();

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		SlotCarTrack.bEnterAnimationComplete[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (SlotCarTrack.RaceStage == ESlotCarRaceStage::Practice && SlotCarTrack.BothPlayersInteracting())
		{
			if (WasActionStarted(ActionNames::InteractionTrigger) && SlotCarTrack.bEnterAnimationComplete[Player] == true)
				SlotCarTrack.NetRequestReadyCheck();
		}
	}

	UFUNCTION()
	void OnEnterAnimationFinished()
	{
		const FSlotCarPlayerAnimations& Animations = SlotCarTrack.GetAnimations(Player);
		Owner.PlayBlendSpace(BlendSpace = Animations.BS);

		SlotCarTrack.bEnterAnimationComplete[Player] = true;
	}
}
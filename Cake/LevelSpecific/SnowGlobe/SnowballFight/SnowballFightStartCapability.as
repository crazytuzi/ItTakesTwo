import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightArenaInteraction;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightArenaVolume;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightNames;

class USnowballFightStartCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(SnowballFightTags::MiniGameStart);
	default CapabilityTags.Add(n"SnowballFight");

	default CapabilityDebugCategory = n"GamePlay";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	ASnowballFightArenaInteraction InteractionActor;
	ASnowballFightArenaVolume ArenaVolumeActor;

	UPROPERTY()
	TPerPlayer<UAnimSequence> HoldAnimation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		InteractionActor = Cast<ASnowballFightArenaInteraction>(GetAttributeObject(n"InteractionActor"));
		ArenaVolumeActor = Cast<ASnowballFightArenaVolume>(GetAttributeObject(n"ArenaActor"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (InteractionActor != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	//Simplify exit states based on gamestate enum?
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && !ArenaVolumeActor.CountdownActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		if (ArenaVolumeActor.GameActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SmoothSetLocationAndRotation(InteractionActor.InteractRoot.WorldLocation, InteractionActor.Root.RelativeRotation);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(n"SnowGlobeSideContent", this);
		Player.TriggerMovementTransition(this);
		Player.ShowCancelPrompt(this);
		CancelPromptActive = true;
		Player.PlaySlotAnimation(Animation = Player.IsMay() ? HoldAnimation[0] : HoldAnimation[1], bLoop = true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
		InteractionActor.OnDeactivatedInteraction(Player);
		// ArenaVolumeActor.PlayerCancel(Player);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(n"SnowGlobeSideContent", this);
		ArenaVolumeActor.CountdownActive = false;
		
		if(CancelPromptActive)
			Player.RemoveCancelPromptByInstigator(this);

		Player.StopAllSlotAnimations();
		InteractionActor = nullptr;
	}

	bool CancelPromptActive = false;
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// PrintToScreen("ArenaVolumeActor.CountdownActive: " + ArenaVolumeActor.CountdownActive);
		// PrintToScreen("ArenaVolumeActor.GameActive: " + ArenaVolumeActor.GameActive);
		
		if(CancelPromptActive && ArenaVolumeActor != nullptr && ArenaVolumeActor.CountdownActive)
		{
			Player.RemoveCancelPromptByInstigator(this);
			CancelPromptActive = false;
		}
	}
}
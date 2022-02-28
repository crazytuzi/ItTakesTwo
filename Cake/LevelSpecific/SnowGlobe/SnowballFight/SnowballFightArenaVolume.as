import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightManagerComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightResponseComponent;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightArenaStartingArea;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightArenaInteraction;
import Vino.Interactions.DoubleInteractionActor;

event void FOnSnowballFightFinishedEventSignature();

class ASnowballFightArenaVolume : ADoubleInteractionActor
{
	default ExclusiveMode = EDoubleInteractionExclusiveMode::LeftSideMayRightSideCody;

	UPROPERTY(DefaultComponent, ShowOnActor)
	USnowballFightManagerComponent ManagerComp;

	UPROPERTY(Category = "Setup")
	TPerPlayer<UAnimSequence> PlayerActionAnims;

	UPROPERTY(Category = "Setup")
	TPerPlayer<ASnowballFightArenaInteraction> snowballFightInteraction;

	UPROPERTY(DefaultComponent, Category = "Setup", ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::SnowWarfare;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UHazeCapability> CameraCapability;

	bool GameActive = false;
	bool CountdownActive = false;

	FOnSnowballFightFinishedEventSignature FinishedEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ManagerComp.RoundCompletedEvent.AddUFunction(this, n"RoundCompleted");
		ManagerComp.CountdownCompletedEvent.AddUFunction(this, n"CountdownCompleted");
		
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"PlayerTutorialCancelled");

		OnDoubleInteractionCompleted.AddUFunction(this, n"PlayersDoubleInteracted");

		LeftInteraction.OnActivated.AddUFunction(this, n"LeftInteracted");
		RightInteraction.OnActivated.AddUFunction(this, n"RightInteracted");

		OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnPlayerCancelledInteraction");
	}

	UFUNCTION()
	void LeftInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		snowballFightInteraction[0].OnInteracted(Player);
	}		

	UFUNCTION()
	void RightInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		snowballFightInteraction[1].OnInteracted(Player);
	}

	UFUNCTION()
	void PlayerTutorialCancelled()
	{
		EnableAfterFullSyncPoint(n"TutorialInUse");

		Game::May.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::Cody.UnblockCapabilities(CapabilityTags::Movement, this);

		Game::May.UnblockCapabilities(SnowballFightTags::Aim, this);
		Game::May.UnblockCapabilities(SnowballFightTags::Hit, this);
		Game::May.UnblockCapabilities(SnowballFightTags::Throw, this);
		Game::Cody.UnblockCapabilities(SnowballFightTags::Aim, this);
		Game::Cody.UnblockCapabilities(SnowballFightTags::Hit, this);
		Game::Cody.UnblockCapabilities(SnowballFightTags::Throw, this);

		snowballFightInteraction[0].OnDeactivatedInteraction(Game::May);
		snowballFightInteraction[1].OnDeactivatedInteraction(Game::Cody);

		Game::May.RemoveCapability(CameraCapability);
		Game::Cody.RemoveCapability(CameraCapability);

		Game::May.StopAllSlotAnimations(0.3f);
		Game::Cody.StopAllSlotAnimations(0.3f);
	}

	UFUNCTION()
	void OnPlayerCancelledInteraction(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		if (Interaction == LeftInteraction)
			snowballFightInteraction[0].OnDeactivatedInteraction(Player);
		else
			snowballFightInteraction[1].OnDeactivatedInteraction(Player);

		Player.StopAllSlotAnimations(0.3f);
	}

	UFUNCTION()
	void PlayersDoubleInteracted()
	{
		Disable(n"TutorialInUse");

		CountdownActive = true;

		Game::May.SetCapabilityAttributeObject(n"ArenaActor", this);
		Game::Cody.SetCapabilityAttributeObject(n"ArenaActor", this);

		Game::May.BlockCapabilities(CapabilityTags::Movement, this);
		Game::Cody.BlockCapabilities(CapabilityTags::Movement, this);

		Game::May.BlockCapabilities(SnowballFightTags::Aim, this);
		Game::May.BlockCapabilities(SnowballFightTags::Hit, this);
		Game::May.BlockCapabilities(SnowballFightTags::Throw, this);
		Game::Cody.BlockCapabilities(SnowballFightTags::Aim, this);
		Game::Cody.BlockCapabilities(SnowballFightTags::Hit, this);
		Game::Cody.BlockCapabilities(SnowballFightTags::Throw, this);

		Game::May.TriggerMovementTransition(this);
		Game::Cody.TriggerMovementTransition(this);

		Game::May.AddCapability(CameraCapability);
		Game::Cody.AddCapability(CameraCapability);

		Game::May.PlaySlotAnimation(Animation = PlayerActionAnims[0], BlendTime = 0.3f, bLoop = true);
		Game::Cody.PlaySlotAnimation(Animation = PlayerActionAnims[1], BlendTime = 0.3f, bLoop = true);

		MinigameComp.ActivateTutorial();
	}

	UFUNCTION(NetFunction)
	void RoundCompleted()
	{
		StopSnowballFight();
		EnableAfterFullSyncPoint(n"TutorialInUse");
	}

	UFUNCTION()
	void CountdownCompleted()
	{
		GameActive = true;
		CountdownActive = false;
		
		snowballFightInteraction[0].bIsGameActive = true;
		snowballFightInteraction[1].bIsGameActive = true;
		
		snowballFightInteraction[0].OnDeactivatedInteraction(Game::May);
		snowballFightInteraction[1].OnDeactivatedInteraction(Game::Cody);
	
		Game::May.UnblockCapabilities(CapabilityTags::Movement, this);
		Game::Cody.UnblockCapabilities(CapabilityTags::Movement, this);

		Game::May.UnblockCapabilities(SnowballFightTags::Aim, this);
		Game::May.UnblockCapabilities(SnowballFightTags::Hit, this);
		Game::May.UnblockCapabilities(SnowballFightTags::Throw, this);
		Game::Cody.UnblockCapabilities(SnowballFightTags::Aim, this);
		Game::Cody.UnblockCapabilities(SnowballFightTags::Hit, this);
		Game::Cody.UnblockCapabilities(SnowballFightTags::Throw, this);

		Game::May.StopAllSlotAnimations(0.3f);
		Game::Cody.StopAllSlotAnimations(0.3f);

		Game::May.RemoveCapability(CameraCapability);
		Game::Cody.RemoveCapability(CameraCapability);
	}

	UFUNCTION(NetFunction)
	void StopSnowballFight()
	{
		GameActive = false;
		CountdownActive = false;

		snowballFightInteraction[0].bIsGameActive = false;
		snowballFightInteraction[1].bIsGameActive = false;

		snowballFightInteraction[0].ReenableInteractions();
		snowballFightInteraction[1].ReenableInteractions();

		ManagerComp.StopSnowballFight();
	}
}
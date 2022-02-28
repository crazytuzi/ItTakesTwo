import void InitGardenSwinging(AHazePlayerCharacter Player, AGardenSwingsActor Swings, UGardenSingleSwingComponent PlayerSwing, ULocomotionFeatureSwingingMinigame AnimationFeature) from "Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingPlayerComponent";
import Vino.Interactions.InteractionComponent;
import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenSwing;
import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenSwingingMinigame;

import Vino.MinigameScore.ScoreHud;
import Vino.Movement.Capabilities.Sliding.ForceCharacterSlidingVolume;
import Vino.MinigameScore.MinigameComp;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraDetacherComponent;
import Vino.Interactions.DoubleInteractComponent;
import Vino.Interactions.DoubleInteractionActor;

event void FOnPlayerFinishedAnimationsOfGardenSwing(AHazePlayerCharacter Player);
event void FOnBeforeAnnouncingSwingWinner();
event void FOnGardenSwingStart();
event void FOnGardenSwingStop();

UCLASS(Abstract)
class AGardenSwingsActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USkeletalMeshComponent GardenSwing;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MayScoreRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CodyScoreRoot;

	UPROPERTY(DefaultComponent, Attach = GardenSwing, AttachSocket = "LeftSwing")
	USceneComponent MaySwingRoot;

	UPROPERTY(DefaultComponent, Attach = GardenSwing, AttachSocket = "RightSwing")
	USceneComponent CodySwingRoot;

	// UPROPERTY(DefaultComponent, Attach = RootComp)
	// UInteractionComponent MayInteraction;

	// UPROPERTY(DefaultComponent, Attach = RootComp)
	// UInteractionComponent CodyInteraction;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent, Attach = MaySwingRoot)
	UCameraDetacherComponent MayDetacher;
	default MayDetacher.bFollowRotation = false;

	UPROPERTY(DefaultComponent, Attach = MayDetacher)
	UCameraSpringArmComponent MaySpringArm;

	UPROPERTY(DefaultComponent, Attach = MaySpringArm)
	UHazeCameraComponent MaySwingCamera;

	UPROPERTY(DefaultComponent, Attach = CodySwingRoot)
	UCameraDetacherComponent CodyDetacher;
	default CodyDetacher.bFollowRotation = false;

	UPROPERTY(DefaultComponent, Attach = CodyDetacher)
	UCameraSpringArmComponent CodySpringArm;

	UPROPERTY(DefaultComponent, Attach = CodySpringArm)
	UHazeCameraComponent CodySwingCamera;


	// UPROPERTY(DefaultComponent)
	// UHazeDisableComponent DisableComp;
	// default DisableComp.bAutoDisable = true;
	// default DisableComp.AutoDisableRange = 20000.f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WinnerCameraRoot;

	UPROPERTY(DefaultComponent, Attach = WinnerCameraRoot)
	UHazeCameraComponent WinnerCamera;

	UPROPERTY(DefaultComponent)
	UGardenSingleSwingComponent MaySwing;
	UPROPERTY(DefaultComponent)
	UGardenSingleSwingComponent CodySwing;
	

	UPROPERTY(DefaultComponent)
	UHazeAkComponent MayGardenSwingAkComp;
	UPROPERTY(DefaultComponent)
	UHazeAkComponent CodyGardenSwingAkComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.ScoreData.Timer = 20.f;
	default MinigameComp.ScoreData.ShowTimer = true;
	default MinigameComp.MinigameTag = EMinigameTag::GardenSwings;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartWindAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopWindAudioEvent;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	ULocomotionFeatureGardenSwing AnimFeature;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	ULocomotionFeatureSwingingMinigame CodyAnimFeature;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	ULocomotionFeatureSwingingMinigame MayAnimFeature;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerSlideOverlap;
	default PlayerSlideOverlap.SetCollisionProfileName(n"OverlapOnlyPawn");

	// UPROPERTY(Category = "Setup", EditDefaultsOnly)
	// UAnimSequence MayEnterAnimation;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence MayReadyAnimation;
	// UPROPERTY(Category = "Setup", EditDefaultsOnly)
	// UAnimSequence MayExitAnimation;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence MayStartAnimation;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence MayStartWaitingAnimation;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence MayWaitingMHAnimation;

	// UPROPERTY(Category = "Setup", EditDefaultsOnly)
	// UAnimSequence CodyEnterAnimation;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence CodyReadyAnimation;
	// UPROPERTY(Category = "Setup", EditDefaultsOnly)
	// UAnimSequence CodyExitAnimation;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence CodyStartAnimation;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence CodyStartWaitingAnimation;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UAnimSequence CodyWaitingMHAnimation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent CodyInputSyncFloat;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent MayInputSyncFloat;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent CodySwingSyncFloat;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent MaySwingSyncFloat;
	
	FOnPlayerFinishedAnimationsOfGardenSwing OnPlayerFinishedAnimationsOfGardenSwing;

	FOnBeforeAnnouncingSwingWinner OnBeforeAnnouncingSwingWinner;

	UPROPERTY()
	FOnGardenSwingStart OnGardenSwingStart;
	UPROPERTY()
	FOnGardenSwingStop OnGardenSwingStop;

	float MaxPitchValue = 130.0f;

	UPROPERTY(NotEditable)
	bool bStartingMiniGame = false;
	
	UPROPERTY(NotEditable)
	bool bMiniGameIsOn = false;

	TPerPlayer<bool> bCompletedJump;

	bool bBothPlayersHaveJumped = false;

	bool bCodyScoreSet = false;
	bool bMayScoreSet = false;
	
	// bool bMayFinishedAnimations = false;
	// bool bCodyFinishedAnimations = false;

	bool bShowScore = false;
	float ShowScoreDuration = 3.0f;
	float ShowScoreTimer = 0.0f;

	bool bCountingDown = false;

	bool bMayIsReady = false;
	bool bCodyIsReady = false;

	bool bTutorialCancelled = false;

	bool bCapabilitiesAdded = false;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteractActor;

	AHazePlayerCharacter Winner;

	float DurationBeforeAwaitingScoreScreenSize = 2.0f;
	float TimerAwaitingScoreScreenSize = 0.0f;
	bool bAwaitingScoreScreenSized = false;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UForceFeedbackEffect ShortRumble;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UForceFeedbackEffect GroundedRumble;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UForceFeedbackEffect JumpRumble;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"GardenSwingingCapability");
		AddCapability(n"GardenSwingAnnounceWinCapability");
		
		// MayInteraction.DisableForPlayer(Game::GetCody(), n"Other Player's Swing");
		// CodyInteraction.DisableForPlayer(Game::GetMay(), n"Other Player's Swing");

		// MayInteraction.OnActivated.AddUFunction(this, n"OnInteracted");
		// CodyInteraction.OnActivated.AddUFunction(this, n"OnInteracted");

		DoubleInteractActor.OnLeftInteractionReady.AddUFunction(this, n"OnLeftInteracted");
		DoubleInteractActor.OnRightInteractionReady.AddUFunction(this, n"OnRightInteracted");
		DoubleInteractActor.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnInteractionCancelled");
		DoubleInteractActor.OnDoubleInteractionCompleted.AddUFunction(this, n"DoubleInteractFinished");

		CodyGardenSwingAkComp.AttachTo(GardenSwing, n"RightSwing");
		CodyGardenSwingAkComp.SetTrackVelocity(true, 2000.f);

		MayGardenSwingAkComp.AttachTo(GardenSwing, n"LeftSwing");
		MayGardenSwingAkComp.SetTrackVelocity(true, 2000.f);

		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"StopSwingMiniGame");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"TutorialWasCancelled");

		CodyInputSyncFloat.OverrideControlSide(Game::GetCody());
		CodySwingSyncFloat.OverrideControlSide(Game::GetCody());
		MayInputSyncFloat.OverrideControlSide(Game::GetMay());
		MaySwingSyncFloat.OverrideControlSide(Game::GetMay());

		MayScoreRoot.SetRelativeLocation(MaySwingRoot.RelativeLocation);
		CodyScoreRoot.SetRelativeLocation(CodySwingRoot.RelativeLocation);

		if(HasControl())
			MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"TutorialFinished");
	}

	UFUNCTION()
	void DoubleInteractFinished()
	{
		DoubleInteractActor.DisableActor(this);
		MinigameComp.ActivateTutorial();

		bStartingMiniGame = true;

		FHazeAnimationDelegate OnBlendedIn;
		FHazeAnimationDelegate OnBlendingOut;

		Game::GetCody().PlaySlotAnimation(OnBlendedIn, OnBlendingOut, CodyReadyAnimation, true);
		Game::GetMay().PlaySlotAnimation(OnBlendedIn, OnBlendingOut, MayReadyAnimation, true);
	}

	UFUNCTION()
	void TutorialWasCancelled()
	{
		DoubleInteractActor.EnableActor(this);
		bStartingMiniGame = false;
		bTutorialCancelled = true;
	}

	UFUNCTION()
	void OnInteractionCancelled(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		if(Player.HasControl())
		{
			NetCancelInteraction(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetCancelInteraction(AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
				MaySwing.bCancelledInteraction = true;
			else
				CodySwing.bCancelledInteraction = true;
	}

	UFUNCTION()
	void OnLeftInteracted(AHazePlayerCharacter Player)
	{
		AddPlayerToSwing(Player, MaySwing);
		//MayGardenSwingAkComp.HazePostEvent(StartWindAudioEvent);
	
		MinigameComp.AddPlayerCapabilitySheets();

		Player.BlockCapabilities(n"LevelSpecific", this);
	}
	
	UFUNCTION()
	void OnRightInteracted(AHazePlayerCharacter Player)
	{
		AddPlayerToSwing(Player, CodySwing);		
		//CodyGardenSwingAkComp.HazePostEvent(StartWindAudioEvent);

		MinigameComp.AddPlayerCapabilitySheets();
		
		Player.BlockCapabilities(n"LevelSpecific", this);
	}

	UFUNCTION()
	void AddPlayerToSwing(AHazePlayerCharacter Player, UGardenSingleSwingComponent Swing)
	{
		Swing.CurrentPlayer = Player;
		
		if(bTutorialCancelled)
			bTutorialCancelled = false;

		if(!bCapabilitiesAdded)
		{
			InitGardenSwinging(Game::GetMay(), this, MaySwing, MayAnimFeature);
			InitGardenSwinging(Game::GetCody(), this, CodySwing, CodyAnimFeature);

			// if(Player.IsMay())
			// 	InitGardenSwinging(Player, this, MaySwing, MayAnimFeature);
			// else
			// 	InitGardenSwinging(Player, this, CodySwing, CodyAnimFeature);
			
			// Player.AddCapability(n"GardenSwingEnterCapability");
			// Player.AddCapability(n"GardenSwingPlayerSwingingCapability");
			// Player.AddCapability(n"GardenSwingInAirCapability");
			// Player.AddCapability(n"GardenSwingScoreCapability");
			// Player.AddCapability(n"GardenSwingPlayerAnimationCapability");
			bCapabilitiesAdded = true;
		}
	}

	UFUNCTION()
	void ResetSwing(UGardenSingleSwingComponent Swing)
	{
		if(Swing.CurrentPlayer.IsMay())
		{
			//MayInteraction.Enable(NAME_None);		
			MayGardenSwingAkComp.HazePostEvent(StopWindAudioEvent);
			bMayIsReady = false;
		}
		else
		{
			CodyGardenSwingAkComp.HazePostEvent(StopWindAudioEvent);
			//CodyInteraction.Enable(NAME_None);	
			bCodyIsReady = false;
		}

		if(Swing.CurrentPlayer.IsPlayingAnyAnimationOnSlot(EHazeSlotAnimType::SlotAnimType_Default))
			Swing.CurrentPlayer.StopAllSlotAnimations();

		Swing.CurrentPlayer.UnblockCapabilities(n"LevelSpecific", this);

		Swing.CurrentPlayer = nullptr;
		Swing.bPlayerIsOnSwing = false;
		Swing.bPlayerHasJumped = false;
		Swing.bCancelledInteraction = false;
		Swing.Angle = 0.0f;

		Swing.bSwinging = false;
		Swing.bRequestLocomotionFromPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bMiniGameIsOn && !bCountingDown)
			return;

		if(MaySwing.bPlayerHasJumped && !bCompletedJump[0] && !bMayScoreSet)
		{
			float ScoreDistance2 = (MaySwing.CurrentPlayer.ActorLocation - MayScoreRoot.WorldLocation).DotProduct(ActorForwardVector);
			int IntScore = ScoreDistance2 / 100;
			MinigameComp.SetScore(Game::May, IntScore);
			//bMayScoreSet = true;
		}

		if(CodySwing.bPlayerHasJumped && !bCompletedJump[1] && !bCodyScoreSet)
		{
			float ScoreDistance1 = (CodySwing.CurrentPlayer.ActorLocation - CodyScoreRoot.WorldLocation).DotProduct(ActorForwardVector);
			int IntScore = ScoreDistance1 / 100;
			MinigameComp.SetScore(Game::Cody, IntScore);
			//bCodyScoreSet = true;
		}

		if(!bAwaitingScoreScreenSized)
		{
			if(!bShowScore && (MaySwing.bPlayerHasJumped != CodySwing.bPlayerHasJumped))
			{
				TimerAwaitingScoreScreenSize += DeltaTime;

				if(TimerAwaitingScoreScreenSize >= DurationBeforeAwaitingScoreScreenSize)
				{
					if(MaySwing.bPlayerHasJumped)
						Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Small);
					else if(CodySwing.bPlayerHasJumped)
						Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Small);

					bAwaitingScoreScreenSized = true;
				}
			}
		}
	}

	UFUNCTION()
	void PlayerIsReady(AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
			bMayIsReady = true;
		else
			bCodyIsReady = true;
	}

	UFUNCTION()
	void TutorialFinished()
	{
		NetStartCountDown();

		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"StartSwingMiniGame");
	}

	UFUNCTION(NetFunction)
	void NetStartCountDown()
	{
		bCountingDown = true;

		MinigameComp.StartCountDown();

		FHazeAnimationDelegate OnBlendedIn;

		FHazeAnimationDelegate OnMayBlendingOut;
		FHazeAnimationDelegate OnCodyBlendingOut;

		OnMayBlendingOut.BindUFunction(this, n"MayStartAnimationFinished");
		OnCodyBlendingOut.BindUFunction(this, n"CodyStartAnimationFinished");
		
		Game::GetMay().PlaySlotAnimation(OnBlendedIn, OnMayBlendingOut, MayStartAnimation, false);
		Game::GetCody().PlaySlotAnimation(OnBlendedIn, OnCodyBlendingOut, CodyStartAnimation, false);

		bMayIsReady = false;
		bCodyIsReady = false;
	}

	UFUNCTION()
	void MayStartAnimationFinished()
	{
		MaySwing.bPlayerIsOnSwing = true;
		MaySwing.bRequestLocomotionFromPlayer = true;
	}

	UFUNCTION()
	void CodyStartAnimationFinished()
	{
		CodySwing.bPlayerIsOnSwing = true;
		CodySwing.bRequestLocomotionFromPlayer = true;
	}

	UFUNCTION()
	void PlayersJumpedOffSwing(AHazePlayerCharacter Player)
	{
		if(MaySwing.bPlayerHasJumped && CodySwing.bPlayerHasJumped)
		{
			bBothPlayersHaveJumped = true;
		}
	}

	UFUNCTION()
	void PlayerLanded(AHazePlayerCharacter Player)
	{
		if(Player.IsMay())
		{
			float ScoreDistance = (MaySwing.CurrentPlayer.ActorLocation - MayScoreRoot.WorldLocation).DotProduct(ActorForwardVector);
			int IntScore = ScoreDistance / 100;
			
			if(Player.HasControl())
				NetSetMayScore(IntScore);
		}

		if(Player.IsCody())
		{
			float ScoreDistance = (CodySwing.CurrentPlayer.ActorLocation - CodyScoreRoot.WorldLocation).DotProduct(ActorForwardVector);
			int IntScore = ScoreDistance / 100;

			if(Player.HasControl())
				NetSetCodyScore(IntScore);
		}
	} 

	UFUNCTION(NetFunction)
	void NetSetMayScore(int MayScore)
	{
		MinigameComp.SetScore(Game::May, MayScore);
		bMayScoreSet = true;
	}

	UFUNCTION(NetFunction)
	void NetSetCodyScore(int CodyScore)
	{
		MinigameComp.SetScore(Game::Cody, CodyScore);
		bCodyScoreSet = true;
	}

	UFUNCTION()
	void StartSwingMiniGame()
	{
		if(HasControl())
		{
			NetStartMiniGames();
		}
	}

	UFUNCTION(NetFunction)
	void NetStartMiniGames()
	{
		bCountingDown = false;
		bStartingMiniGame = false;

		MinigameComp.StartTimer();

		MayGardenSwingAkComp.HazePostEvent(StartWindAudioEvent);
		CodyGardenSwingAkComp.HazePostEvent(StartWindAudioEvent);

		bMiniGameIsOn = true;
		GardenSwing.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		OnGardenSwingStart.Broadcast();
	}

	UFUNCTION()
	void StopSwingMiniGame()
	{
		if(HasControl())
		{
			NetStopMiniGame();
		}
	}

	UFUNCTION(NetFunction)
	void NetStopMiniGame()
	{
		MinigameComp.StopTimer();

		GardenSwing.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		bMiniGameIsOn = false;

		if(Winner != nullptr)
			Winner.DeactivateCamera(WinnerCamera);

		OnGardenSwingStop.Broadcast();
		ResetManager();
	}


	void ResetManager()
	{
		bCodyScoreSet = false;
		bMayScoreSet = false;

		MinigameComp.ResetScoreBoth();

		bBothPlayersHaveJumped = false;

		bCompletedJump[0] = false;
		bCompletedJump[1] = false;

		// bMayFinishedAnimations = false;
		// bCodyFinishedAnimations = false;

		ShowScoreTimer = 0.0f;
		bShowScore = false;

		TimerAwaitingScoreScreenSize = 0.0f;
		bAwaitingScoreScreenSized = false;

		Winner = nullptr;

		DoubleInteractActor.EnableActor(this);

		MinigameComp.RemovePlayerCapabilitySheets();

		CodySwingSyncFloat.Value = 0;
		MaySwingSyncFloat.Value = 0;


		bStartingMiniGame = false;
		
		bMayIsReady = false;
		bCodyIsReady = false;

		bTutorialCancelled = false;

		bCapabilitiesAdded = false;
	}
}

class UGardenSingleSwingComponent : UActorComponent
{
	AHazePlayerCharacter CurrentPlayer;

	UPROPERTY(NotEditable)
	float Angle = 0.0f;

	bool bPlayerIsOnSwing = false;
	bool bSwinging = false;
	bool bPlayerHasJumped = false;
	bool bCancelledInteraction = false;

	bool bRequestLocomotionFromPlayer = false;

	float DesiredAngle = 10.0f;
	float LastFrameTimeSin = 0.0f;
	float TargetAngle = 10.0f;
	float LastFrameAngle = 0.0f;
	float CurrentAngle = 10.0f;
}
import Peanuts.Spline.SplineActor;
import Vino.Camera.Actors.KeepInViewCameraActor;
import Vino.Interactions.DoubleInteractionActor;
import Vino.Audio.Music.MusicManagerActor;
import Vino.Audio.Music.MusicCallbackSubscriberComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.TrackRunnerObstacle;
import Vino.MinigameScore.ScoreHud;
import Peanuts.Animation.Features.Music.LocomotionFeatureMusicTrackRunner;
import Peanuts.Triggers.PlayerTrigger;
import Peanuts.Spline.SplineMesh;
import Peanuts.Spline.SplineComponentActor;
import Vino.MinigameScore.MinigameComp;
import Vino.Camera.Actors.StaticCamera;
import Peanuts.Fades.FadeStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;

event void FOnPlayerHitByObstacleForAnimation(AHazePlayerCharacter Player);
event void FOnManagerActivated();
event void FOnManagerDeactivated();
event void FOnStartFinishMiniGame();
event void FOnStartSpawningObstacles();
event void FOnSpawnObstacle());

void ReturnTrackRunnerObstacleToPool(ATrackRunnerObstacle Obstacle)
{
	auto ObstacleComp = Cast<UMusicObstacleComponent>(Obstacle.ObstaclePool);
	if (ObstacleComp != nullptr)
	{
		if (Obstacle.bObstaclePoolLeft)
			ObstacleComp.LeftPoolAvailable.AddUnique(Obstacle);
		else
			ObstacleComp.RightPoolAvailable.AddUnique(Obstacle);
	}
}

class UMusicObstacleComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<ATrackRunnerObstacle>  TypeToSpawn;

	TArray<ATrackRunnerObstacle> LeftContainer;
	TArray<ATrackRunnerObstacle> RightContainer;

	TArray<ATrackRunnerObstacle> LeftPoolAvailable;
	TArray<ATrackRunnerObstacle> RightPoolAvailable;

	int LeftSpawnIndex = 0;
	int RightSpawnIndex = 0;

	void Setup(ATrackRunnerManager TrackRunnerManager)
	{
	}

	ATrackRunnerObstacle GetAvailableFromPool(bool bLeftSide)
	{
		ATrackRunnerObstacle Obstacle = nullptr;
		if (bLeftSide)
		{
			if (LeftPoolAvailable.Num() != 0)
			{
				Obstacle = LeftPoolAvailable[0];
				LeftPoolAvailable.RemoveAt(0);
			}
		}
		else
		{
			if (RightPoolAvailable.Num() != 0)
			{
				Obstacle = RightPoolAvailable[0];
				RightPoolAvailable.RemoveAt(0);
			}
		}

		return Obstacle;
	}

	ATrackRunnerObstacle SpawnNewObstacle(ATrackRunnerManager TrackRunnerManager, bool LeftSide)
	{
		ATrackRunnerObstacle ProjectileSpawned = Cast<ATrackRunnerObstacle>(SpawnActor(TypeToSpawn, Level = Owner.GetLevel(), bDeferredSpawn = true));
		ProjectileSpawned.ObstaclePool = this;
		ProjectileSpawned.bObstaclePoolLeft = LeftSide;

		if(LeftSide)
		{
			ProjectileSpawned.MakeNetworked(this, n"Left", LeftSpawnIndex);
			LeftSpawnIndex ++;
			LeftContainer.Add(ProjectileSpawned);
		}
		else
		{
			ProjectileSpawned.MakeNetworked(this, n"Right", RightSpawnIndex);
			RightSpawnIndex ++;
			RightContainer.Add(ProjectileSpawned);
		}
			
		FinishSpawningActor(ProjectileSpawned);
		ProjectileSpawned.OnPlayerHitObstacle.AddUFunction(TrackRunnerManager, n"PlayerHitObstacle");
		ProjectileSpawned.DisableActor(nullptr);

		return ProjectileSpawned;
	}

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
	{
		/*
		for(int i = 0 ; i < AmountToSpawn ; ++i)
		{
			if(LeftContainer[i] != nullptr)
				LeftContainer[i].DestroyActor();

			if(RightContainer[i] != nullptr)
				RightContainer[i].DestroyActor();
		}

		LeftContainer.Empty();
		RightContainer.Empty();
		*/
	}
}


class ATrackRunnerManager : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;
	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MiniGameComp;
	default MiniGameComp.MinigameTag = EMinigameTag::TrackRunner;

	UPROPERTY()
	ATextRenderActor TextRenderer;

	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleSmallContainer;
	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleMediumLeftContainer;
	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleMediumRightContainer;
	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleJumpBigContainer;
	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleSmallMovingLeft;
	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleSmallMovingRight;
	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleBigMovingLeft;
	UPROPERTY(DefaultComponent)
	UMusicObstacleComponent ObstacleBigMovingRight;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GameEnterAudioEvent;
	
	UPROPERTY()
	AStaticMeshActor TrackRunnerMeshLeftSide;
	UPROPERTY()
	AStaticMeshActor TrackRunnerMeshRightSide;
	UPROPERTY()
	AHazeNiagaraActor SmokeLeftSide1;
	UPROPERTY()
	AHazeNiagaraActor SmokeLeftSide2;
	UPROPERTY()
	AHazeNiagaraActor SmokeLeftSide3;
	UPROPERTY()
	AHazeNiagaraActor SmokeLeftSide4;
	UPROPERTY()
	AHazeNiagaraActor SmokeRightSide1;
	UPROPERTY()
	AHazeNiagaraActor SmokeRightSide2;
	UPROPERTY()
	AHazeNiagaraActor SmokeRightSide3;
	UPROPERTY()
	AHazeNiagaraActor SmokeRightSide4;
	UPROPERTY()
	AHazeNiagaraActor ConfettiVictory;
	UPROPERTY()
	AHazeNiagaraActor FireworkVictory1;
	UPROPERTY()
	AHazeNiagaraActor FireworkVictory2;

	UPROPERTY()
	AHazeNiagaraActor FireworkLeftSide1;
	UPROPERTY()
	AHazeNiagaraActor FireworkLeftSide2;
	UPROPERTY()
	AHazeNiagaraActor FireworkLeftSide3;
	UPROPERTY()
	AHazeNiagaraActor FireworkLeftSide4;
	UPROPERTY()
	AHazeNiagaraActor FireworkRightSide1;
	UPROPERTY()
	AHazeNiagaraActor FireworkRightSide2;
	UPROPERTY()
	AHazeNiagaraActor FireworkRightSide3;
	UPROPERTY()
	AHazeNiagaraActor FireworkRightSide4;

	UPROPERTY()
	AHazeNiagaraActor EnterMachineEffectLeftSide;
	UPROPERTY()
	AHazeNiagaraActor EnterMachineEffectRightSide;

	UPROPERTY()
	AStaticMeshActor MayHair;
	UPROPERTY()
	AStaticMeshActor MaySpineOne;
	UPROPERTY()
	AStaticMeshActor MaySpineTwo;
	UPROPERTY()
	AStaticMeshActor MayHips;
	UPROPERTY()
	AStaticMeshActor MayLeftArm;
	UPROPERTY()
	AStaticMeshActor MayLeftFoot;
	UPROPERTY()
	AStaticMeshActor MayLeftForeArm;
	UPROPERTY()
	AStaticMeshActor MayLeftHand;
	UPROPERTY()
	AStaticMeshActor MayLeftLeg;
	UPROPERTY()
	AStaticMeshActor MayLeftToeBase;
	UPROPERTY()
	AStaticMeshActor MayLeftUpLeg;
	UPROPERTY()
	AStaticMeshActor MayRightArm;
	UPROPERTY()
	AStaticMeshActor MayRightFoot;
	UPROPERTY()
	AStaticMeshActor MayRightForeArm;
	UPROPERTY()
	AStaticMeshActor MayRightHand;
	UPROPERTY()
	AStaticMeshActor MayRightLeg;
	UPROPERTY()
	AStaticMeshActor MayRightToeBase;
	UPROPERTY()
	AStaticMeshActor MayRightUpLeg;

	UPROPERTY()
	AStaticMeshActor CodySpineOne;
	UPROPERTY()
	AStaticMeshActor CodySpineTwo;
	UPROPERTY()
	AStaticMeshActor CodyHips;
	UPROPERTY()
	AStaticMeshActor CodyLeftArm;
	UPROPERTY()
	AStaticMeshActor CodyLeftFoot;
	UPROPERTY()
	AStaticMeshActor CodyLeftForeArm;
	UPROPERTY()
	AStaticMeshActor CodyLeftHand;
	UPROPERTY()
	AStaticMeshActor CodyLeftLeg;
	UPROPERTY()
	AStaticMeshActor CodyLeftToeBase;
	UPROPERTY()
	AStaticMeshActor CodyLeftUpLeg;
	UPROPERTY()
	AStaticMeshActor CodyRightArm;
	UPROPERTY()
	AStaticMeshActor CodyRightFoot;
	UPROPERTY()
	AStaticMeshActor CodyRightForeArm;
	UPROPERTY()
	AStaticMeshActor CodyRightHand;
	UPROPERTY()
	AStaticMeshActor CodyRightLeg;
	UPROPERTY()
	AStaticMeshActor CodyRightToeBase;
	UPROPERTY()
	AStaticMeshActor CodyRightUpLeg;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactForceFeedback;

	float SmokeTimer;
	float SmokeTimerOriginal = 7.f;
	bool SmokeActive = false;
	float CodyTimesHitObstacle = 0;
	float MayTimesHitObstacle = 0;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent CodyProgressNetworked;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent MayProgressNetworked;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UMusicCallbackSubscriberComponent MusicCallBackComponent;

	UPROPERTY()
	FOnPlayerHitByObstacleForAnimation OnPlayerHitByObstacleForAnimation;
	UPROPERTY()
	ULocomotionFeatureMusicTrackRunner CodyFeature;
	UPROPERTY()
	ULocomotionFeatureMusicTrackRunner MayFeature;
	UPROPERTY()
	FOnManagerActivated OnManagerActivated;
	UPROPERTY()
	FOnManagerDeactivated OnManagerDeactivated;
	UPROPERTY()
	FOnStartFinishMiniGame OnStartFinishMiniGame;
	UPROPERTY()
	FOnStartSpawningObstacles OnStartSpawningObstacles;
	UPROPERTY()
	FOnSpawnObstacle OnSpawnObstacle;
	UPROPERTY()
	TSubclassOf<UHazeCapability> TrackRunnerCapability;

	AActor ProjectileSpawned;
	ASplineActor SplineToFollow;
	FVector LeftSideCurrentTrackSpawnLocation;
	FRotator LeftSideCurrentTrackSpawnRotation;
	FVector RightSideCurrentTrackSpawnLocation;
	FRotator RightSideCurrentTrackSpawnRotation;
	UPROPERTY()
	APlayerTrigger PlayerTriggerCheckLeftForPlayer;
	UPROPERTY()
	APlayerTrigger PlayerTriggerCheckRightForPlayer;
	UPROPERTY()
	APlayerTrigger PlayerTriggerGoalTrigger;
	UPROPERTY()
	ADoubleInteractionActor DoubleInteraction;
	UPROPERTY()
	AMusicManagerActor MusicManagerTrackRunner;
	UPROPERTY()
	AHazeNiagaraActor P1Trail;
	UPROPERTY()
	AHazeNiagaraActor P2Trail;

	UPROPERTY()
	ASplineActor SplineLeftSide1;
	UPROPERTY()
	ASplineActor SplineLeftSide2;
	UPROPERTY()
	ASplineActor SplineLeftSide3;
	UPROPERTY()
	ASplineActor SplineRightSide1;
	UPROPERTY()
	ASplineActor SplineRightSide2;
	UPROPERTY()
	ASplineActor SplineRightSide3;

	UPROPERTY()
	ASplineActor SplineRightSideObstacle1;
	UPROPERTY()
	ASplineActor SplineRightSideObstacle2;
	UPROPERTY()
	ASplineActor SplineRightSideObstacle3;
	UPROPERTY()
	ASplineActor SplineLeftSideObstacle1;
	UPROPERTY()
	ASplineActor SplineLeftSideObstacle2;
	UPROPERTY()
	ASplineActor SplineLeftSideObstacle3;

	AHazePlayerCharacter Cody;
	AHazePlayerCharacter May;
	AHazePlayerCharacter LeftSidePlayer;
	AHazePlayerCharacter RightSidePlayer;
	AHazePlayerCharacter PlayerWinner;
	bool bMiniGameActive;
	bool bStartFinishMiniGameTriggerd = false;
	bool bStartRunAnimation = false;

	bool bFirstSmokeActivated = false;
	bool bSecondSmokeActivated = false;

	float ActivateSmokeTimer;
	int NetWorkedProjectileSpawned = 0;
	UPROPERTY()
	float ProjectileVelocity = 900.f;
	UPROPERTY()
	float ProjectileDuration = 6.0f;
	int MayHighScore = 0;
	int CodyHighScore = 0;
	float ScoreTimerOriginal = 99;

	default MiniGameComp.ScoreData.DefaultHighscoreTimer = 0.f;

	float ScoreTimer;
	float ObstacleSpawnRate = 0.72f;
	float ObstacleSpawnRateTimer = 0.65f;
	float MayFinishTime;
	float CodyFinishTime;
	bool  bStartCountingScore = false;
	bool bAllowSpawning = false;
	UPROPERTY()
	int MayDifficulty = 1;
	UPROPERTY()
	int CodyDifficulty = 1;
	float CurrentFloorMaterialValue = 0;
	
	UPROPERTY()
	AActor LeftPlayerStartLocation;
	UPROPERTY()
	AActor RightPlayerStartLocation;
	UPROPERTY()
	AActor LeftPlayerInteractionStart;
	UPROPERTY()
	AActor RightPlayerInteractionStart;

	UPROPERTY()
	AKeepInViewCameraActor LeftInGameCameraActor;
	UPROPERTY()
	AKeepInViewCameraActor RightInGameCameraActor;

	UPROPERTY()
	AStaticCamera LeftGameIntroOne;
	UPROPERTY()
	AStaticCamera LeftGameIntroTwo;
	UPROPERTY()
	AStaticCamera RightGameIntroOne;
	UPROPERTY()
	AStaticCamera RightGameIntroTwo;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VODataBankAssetLevelSpecific;
	UPROPERTY()
	UFoghornVOBankDataAssetBase VODataBankAssetGeneric;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		Cody = Game::GetCody();
		May = Game::GetMay();
		ScoreTimer = ScoreTimerOriginal;
		DoubleInteraction.OnBothPlayersLockedIntoInteraction.AddUFunction(this, n"DoubleInteractionLockedIn");
		DoubleInteraction.OnDoubleInteractionCompleted.AddUFunction(this, n"StartedEnteringMiniGame");
		
		MiniGameComp.OnMinigameTutorialComplete.AddUFunction(this, n"StartCountDown");
		MiniGameComp.OnTutorialCancel.AddUFunction(this, n"PlayerCanceledMiniGame");
		MiniGameComp.OnEndMinigameReactionsComplete.AddUFunction(this, n"BeginStartEndMiniGame");
		
		ObstacleSmallContainer.Setup(this);
		ObstacleMediumLeftContainer.Setup(this);
		ObstacleMediumRightContainer.Setup(this);
		ObstacleJumpBigContainer.Setup(this);
		ObstacleSmallMovingLeft.Setup(this);
		ObstacleSmallMovingRight.Setup(this);
		ObstacleBigMovingLeft.Setup(this);
		ObstacleBigMovingRight.Setup(this);

		if(PlayerTriggerCheckLeftForPlayer != nullptr && PlayerTriggerCheckRightForPlayer != nullptr && PlayerTriggerGoalTrigger != nullptr)
		{
			PlayerTriggerCheckLeftForPlayer.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterLeftTrigger");
			PlayerTriggerCheckRightForPlayer.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnterRightTrigger");
			PlayerTriggerGoalTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerReachedGoal");
		}
	}

	//networked through DoubleInteractionActor
	UFUNCTION()
	void DoubleInteractionLockedIn()
	{
		Game::GetCody().ActivateCamera(RightGameIntroOne.Camera, FHazeCameraBlendSettings(2.f), this, EHazeCameraPriority::Script);
		Game::GetMay().ActivateCamera(LeftGameIntroOne.Camera, FHazeCameraBlendSettings(2.f), this, EHazeCameraPriority::Script);
		Game::GetMay().BlockCapabilities(n"PowerfulSong", this);
		Game::GetMay().BlockCapabilities(n"Songoflife", this);
		Game::GetMay().AddCapabilitySheet(MiniGameComp.PlayerBlockMovementCapabilitySheet);
		Game::GetMay().TriggerMovementTransition(this);
		Game::GetMay().BlockMovementSyncronization();
		Game::GetMay().BlockCapabilities(n"PlayerMarker", this);
		Game::GetCody().BlockCapabilities(n"Cymbal", this);
		Game::GetCody().AddCapabilitySheet(MiniGameComp.PlayerBlockMovementCapabilitySheet);
		Game::GetCody().TriggerMovementTransition(this);
		Game::GetCody().BlockMovementSyncronization();
		Game::GetCody().BlockCapabilities(n"PlayerMarker", this);

		System::SetTimer(this, n"UnPreventFromCompleting", 3.f, false);
	}
	UFUNCTION()
	void PreventFromCompleting()
	{
		DoubleInteraction.bPreventInteractionFromCompleting = true;
	}
	UFUNCTION()
	void UnPreventFromCompleting()
	{
		DoubleInteraction.bPreventInteractionFromCompleting = false;
	}
	UFUNCTION()
	void StartedEnteringMiniGame()
	{
		DoubleInteraction.DisableActor(this);
		PreventFromCompleting();
		EnterMachineEffectLeftSide.NiagaraComponent.Activate(true);
		EnterMachineEffectRightSide.NiagaraComponent.Activate(true);
		Game::GetMay().Mesh.SetHiddenInGame(true);
		Game::GetCody().Mesh.SetHiddenInGame(true);
		SetCymbalVisible(false);
		System::SetTimer(this, n"SwitchCamera", 1.5f, false);
		System::SetTimer(this, n"FadeToBlack", 3.5f, false);
		System::SetTimer(this, n"SetUpMiniGame", 5.0f, false);
		UHazeAkComponent::HazePostEventFireForget(GameEnterAudioEvent, FTransform());
	}
	UFUNCTION()
	void SwitchCamera()
	{
		Game::GetCody().ActivateCamera(RightGameIntroTwo.Camera, FHazeCameraBlendSettings(0.95f), this, EHazeCameraPriority::Script);
		Game::GetMay().ActivateCamera(LeftGameIntroTwo.Camera, FHazeCameraBlendSettings(0.95f), this, EHazeCameraPriority::Script);
	}
	UFUNCTION()
	void FadeToBlack()
	{
		FadeOutFullscreen(1.5f, 0.5f, 1.f);
	}

	UFUNCTION()
	void TutorialScreenSetupExample()
	{
		MiniGameComp.ActivateTutorial();
	}

	UFUNCTION()
	void PreRefTrackRunner()
	{
		May.SetCapabilityAttributeObject(n"TrackRunner", this);
		Cody.SetCapabilityAttributeObject(n"TrackRunner", this);
	}

	UFUNCTION() 
	void SetUpMiniGame()
	{
		Game::GetMay().Mesh.SetHiddenInGame(false);
		Game::GetCody().Mesh.SetHiddenInGame(false);
		Game::GetMay().TeleportActor(LeftPlayerStartLocation.GetActorLocation(), LeftPlayerStartLocation.GetActorRotation());
		Game::GetCody().TeleportActor(RightPlayerStartLocation.GetActorLocation(), RightPlayerStartLocation.GetActorRotation());

		AttachPlayerMeshes();

	    Cody.AddCapability(TrackRunnerCapability);
		May.AddCapability(TrackRunnerCapability);
//		May.SetCapabilityAttributeObject(n"TrackRunner", this);
//		Cody.SetCapabilityAttributeObject(n"TrackRunner", this);
		bMiniGameActive = true;

		Game::GetCody().ActivateCamera(RightInGameCameraActor.Camera, FHazeCameraBlendSettings(0.f), this, EHazeCameraPriority::Script);
		Game::GetMay().ActivateCamera(LeftInGameCameraActor.Camera, FHazeCameraBlendSettings(0.f), this, EHazeCameraPriority::Script);

		FText GameTimerText = Text::Conv_FloatToText(00.00f, ERoundingMode::ERoundingMode_MAX, false, true, 2, 4,2,2);
		TextRenderer.TextRender.SetText(GameTimerText);

		P1Trail.AttachToActor(Game::GetMay(), n"NAME_None", EAttachmentRule::SnapToTarget);
		P2Trail.AttachToActor(Game::GetCody(), n"NAME_None", EAttachmentRule::SnapToTarget);
		P1Trail.NiagaraComponent.Activate(true);
		P2Trail.NiagaraComponent.Activate(true);
		CodyProgressNetworked.Value = Cody.GetActorLocation();
		MayProgressNetworked.Value = May.GetActorLocation();
		SmokeTimer = SmokeTimerOriginal;
		ActivateSmokeTimer = ScoreTimer;
		bStartCountingScore = false;
		bSecondSmokeActivated = false;
		bFirstSmokeActivated = false;
		CodyTimesHitObstacle = 0;
		MayTimesHitObstacle = 0;
	
		MayDifficulty = 1;
		CodyDifficulty = 1;
		
		PlayerWinner = nullptr;
        MiniGameComp.ResetScoreBoth();


	/*	if(CodyHighScore == 0)
		{
			CodyHighScore = ScoreTimerOriginal;
		}
		if(MayHighScore == 0)
		{
			MayHighScore = ScoreTimerOriginal;
		}
	*/
	
		// MiniGameComp.SetHighScore(Game::GetCody(), CodyHighScore);
		// MiniGameComp.SetHighScore(Game::GetMay(), MayHighScore);
		MiniGameComp.SetTimer(ScoreTimer);
        System::SetTimer(this, n"ActivateTutorial", 1.5f, false);
	}
	UFUNCTION()
	void ActivateTutorial()
	{
        MiniGameComp.ActivateTutorial();
	}
	UFUNCTION()
	void StartCountDown()
	{
		bAllowSpawning = true;
		bStartFinishMiniGameTriggerd = false;
		OnManagerActivated.Broadcast();
		OnStartSpawningObstacles.Broadcast();
				

		MiniGameComp.StartCountDown();
		MiniGameComp.OnCountDownCompletedEvent.AddUFunction(this, n"ActivateMiniGame");
		System::SetTimer(this, n"OnStartSmoke", 15.f, false);
		System::SetTimer(this, n"OnStartSmoke", 45.f, false);
	}
	UFUNCTION()
	void ActivateMiniGame()
	{
		bStartRunAnimation = true;
		bStartCountingScore = true;
		MiniGameComp.OnTimerCompletedEvent.AddUFunction(this, n"StartFinishMiniGame");
		FireworkLeftSide1.NiagaraComponent.Activate();
		FireworkLeftSide2.NiagaraComponent.Activate();
		FireworkLeftSide3.NiagaraComponent.Activate();
		FireworkLeftSide4.NiagaraComponent.Activate();
		FireworkRightSide1.NiagaraComponent.Activate();
		FireworkRightSide2.NiagaraComponent.Activate();
		FireworkRightSide3.NiagaraComponent.Activate();
		FireworkRightSide4.NiagaraComponent.Activate();
	}

	//networked through DoubleInteractionActor
	UFUNCTION()
	void OnPlayerEnterLeftTrigger(AHazePlayerCharacter Player)
	{
		LeftSidePlayer = Player;
	}
	UFUNCTION()
	void OnPlayerEnterRightTrigger(AHazePlayerCharacter Player)
	{
		RightSidePlayer = Player;
	}

	UFUNCTION(NetFunction)
	void ChangeDifficulty(AHazePlayerCharacter Player, int Difficulty)
	{
		if(Player == May)
		{
			MayDifficulty = Difficulty;
		}
		if(Player == Cody)
		{
			CodyDifficulty = Difficulty;
		}
	}


	UFUNCTION()
	void SpawnObstacles(EObstacles TypeOfObstacle, int Track, AHazePlayerCharacter Player)
	{
		if(Player.HasControl())
		{	
			if (!bAllowSpawning)
				return;

			const bool bLeftSide = (Player == LeftSidePlayer);
			ATrackRunnerObstacle PooledObstacle = GetObstaclePool(TypeOfObstacle).GetAvailableFromPool(bLeftSide);
			NetSpawnObstacle(TypeOfObstacle, Track, bLeftSide, PooledObstacle);
		}
	}

	UMusicObstacleComponent GetObstaclePool(EObstacles TypeOfObstacle)
	{
		UMusicObstacleComponent ObstacleChosen;
		if(TypeOfObstacle == EObstacles::Small)
			ObstacleChosen = ObstacleSmallContainer;
		if(TypeOfObstacle == EObstacles::MediumLeft)
			ObstacleChosen = ObstacleMediumLeftContainer;
		if(TypeOfObstacle == EObstacles::MediumRight)
			ObstacleChosen = ObstacleMediumRightContainer;
		if(TypeOfObstacle == EObstacles::JumpBig)
			ObstacleChosen = ObstacleJumpBigContainer;
		if(TypeOfObstacle == EObstacles::SmallMovingLeft)
			ObstacleChosen = ObstacleSmallMovingLeft;
		if(TypeOfObstacle == EObstacles::SmallMovingRight)
			ObstacleChosen = ObstacleSmallMovingRight;
		if(TypeOfObstacle == EObstacles::BigMovingLeft)
			ObstacleChosen = ObstacleBigMovingLeft;
		if(TypeOfObstacle == EObstacles::BigMovingRight)
			ObstacleChosen = ObstacleBigMovingRight;
		return ObstacleChosen;
	}

	UFUNCTION(NetFunction)
	void NetSpawnObstacle(EObstacles TypeOfObstacle, int Track, bool bLeftSide, ATrackRunnerObstacle PooledObstacle)
	{
		UMusicObstacleComponent ObstacleChosen = GetObstaclePool(TypeOfObstacle);
		if (bLeftSide)
		{
			if(Track == 1)
				SplineToFollow = SplineLeftSideObstacle1;
			if(Track == 2)
				SplineToFollow = SplineLeftSideObstacle2;
			if(Track == 3)
				SplineToFollow = SplineLeftSideObstacle3;
		}
		else
		{
			if(Track == 1)
				SplineToFollow = SplineRightSideObstacle1;
			if(Track == 2)
				SplineToFollow = SplineRightSideObstacle2;
			if(Track == 3)
				SplineToFollow = SplineRightSideObstacle3;
		}

		ATrackRunnerObstacle NewProjectile;
		if (PooledObstacle != nullptr)
		{
			NewProjectile = PooledObstacle;
		}
		else
		{
			NewProjectile = ObstacleChosen.SpawnNewObstacle(this, bLeftSide);
		}

		NewProjectile.EnableActor(nullptr);
		if (PooledObstacle != nullptr)
			PooledObstacle.OnReuseFromPool();
		NewProjectile.BreakableComponent.Reset();
		NewProjectile.BreakableComponent.SetHiddenInGame(true);
		NewProjectile.UpDownTimer = NewProjectile.UpDownTimerOriginal;
		NewProjectile.bIsDown = true;
		NewProjectile.WallMesh.SetHiddenInGame(false);
		NewProjectile.DistanceAlongSpline = 0;
		NewProjectile.bShouldImpactPlayer = true;
		NewProjectile.bMiniGameEnded = false;
		NewProjectile.SplineToFollow = SplineToFollow;
		NewProjectile.LifeTimeEnded = false;
		NewProjectile.PlayerSide = LeftSidePlayer;
		NewProjectile.Velocity = ProjectileVelocity;
		NewProjectile.LifeSpanTimer = ProjectileDuration;
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerHitObstacle(ATrackRunnerObstacle Obstacle, AHazePlayerCharacter Player, bool bTimedOut)
	{
		if(PlayerWinner == nullptr)
		{
			NetDestroyObstacle(Obstacle, Player, bTimedOut, true);
		}
		else
		{
			NetDestroyObstacle(Obstacle, Player, bTimedOut, false);
		}
	}
	UFUNCTION(NetFunction)
	void NetDestroyObstacle(ATrackRunnerObstacle Obstacle, AHazePlayerCharacter Player, bool bTimedOut, bool bShouldPushBackPlayer)
	{
		if(Obstacle != nullptr)
		{
			if(bTimedOut == false)
			{
				if(bMiniGameActive == false)
					return;
				
				if(Player == May)
				{
					Obstacle.DestroyObstacle(Player);
					if(bShouldPushBackPlayer)
					{
						OnPlayerHitByObstacleForAnimation.Broadcast(Player);
						MayTimesHitObstacle ++;


						if(May.HasControl())
						{
							FVector	GoalLocation = PlayerTriggerGoalTrigger.GetActorLocation();
							float MayDistanceFromGoal = GoalLocation.DistXY(May.ActorLocation);
							float CodyDistanceFromGoal = GoalLocation.DistXY(Cody.ActorLocation);

							if(MayDistanceFromGoal > CodyDistanceFromGoal)
							{
								NetPlayTauntVOLine(Cody);
							}
							else
							{
								NetPlayFailVO(May);
							}
						}
					}	
				}
				else if(Player == Cody)
				{
					Obstacle.DestroyObstacle(Player);
					if(bShouldPushBackPlayer)
					{
						OnPlayerHitByObstacleForAnimation.Broadcast(Player);
						CodyTimesHitObstacle ++;

						if(Cody.HasControl())
						{
							FVector	GoalLocation = PlayerTriggerGoalTrigger.GetActorLocation();
							float MayDistanceFromGoal = GoalLocation.DistXY(May.ActorLocation);
							float CodyDistanceFromGoal = GoalLocation.DistXY(Cody.ActorLocation);

							if(CodyDistanceFromGoal > MayDistanceFromGoal)
							{
								NetPlayTauntVOLine(May);
							}
							else
							{
								NetPlayFailVO(Cody);
							}
						}
					}
				}
			}

			Obstacle.WallMesh.SetHiddenInGame(true);
			Obstacle.bShouldImpactPlayer = false;
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayTauntVOLine(AHazePlayerCharacter PlayerTaunting)
	{
		if(PlayerTaunting == Cody)
		{
			//Print("Cody Taunt", 3.f);
			//UFoghornVOBankDataAssetBase VOBank = VODataBankAssetLevelSpecific;
			//FName EventName = n"FoghornDBMusicConcerthallTrackRunnerTauntCody";
			//PlayFoghornVOBankEvent(VOBank, EventName);
			MiniGameComp.PlayTauntAllVOBark(Cody);
		}
		else if(PlayerTaunting == May)
		{
			//Print("May Taunt", 3.f);
			//UFoghornVOBankDataAssetBase VOBank = VODataBankAssetLevelSpecific;
			//FName EventName = n"FoghornDBMusicConcerthallTrackRunnerTauntMay";
			//PlayFoghornVOBankEvent(VOBank, EventName);
			MiniGameComp.PlayTauntAllVOBark(May);
		}
	}
	UFUNCTION(NetFunction)
	void NetPlayFailVO(AHazePlayerCharacter PlayerFailing)
	{
		if(PlayerFailing == Cody)
		{
			//Print("Cody Failed", 3.f);
			UFoghornVOBankDataAssetBase VOBank = VODataBankAssetGeneric;
			FName EventName = n"FoghornDBGameplayGlobalMinigameGenericFailCody";
			PlayFoghornVOBankEvent(VOBank, EventName);

		}
		else if(PlayerFailing == May)
		{
			//Print("May failed", 3.f);
			UFoghornVOBankDataAssetBase VOBank = VODataBankAssetGeneric;
			FName EventName = n"FoghornDBGameplayGlobalMinigameGenericFailMay";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}
	}

	UFUNCTION()
	void OnPlayerReachedGoal(AHazePlayerCharacter Player)
	{
		if(bMiniGameActive)
		{
			if(PlayerWinner != nullptr)
				return;

			ConfettiVictory.NiagaraComponent.Activate();
			FireworkVictory1.NiagaraComponent.Activate();
			FireworkVictory2.NiagaraComponent.Activate();

			///if one of the players does a flawless run	
			if(CodyTimesHitObstacle < 1 or MayTimesHitObstacle < 1)
			{
				if(CodyTimesHitObstacle < 1 && MayTimesHitObstacle >= 1)
				{
					if(HasControl())
						NetPlayerWin(Game::GetCody(), 26.09);
				}
				else if(MayTimesHitObstacle < 1 && CodyTimesHitObstacle >= 1)
				{
					if(HasControl())
						NetPlayerWin(Game::GetMay(), 26.09);
				}
				else if(HasControl())
				{
					NetPlayerWin(nullptr, 26.09);
				}
			} 
			else
			{
			if(HasControl())
				{
					NetPlayerWin(Player, MiniGameComp.GetTimerValue());
				}
				else
				{
					NetRequestWin(Player);
				}
			}
		}
	}

	UFUNCTION()
	void StartFinishMiniGame()
	{
		if(HasControl())
		{
			NetPlayerWin(nullptr, MiniGameComp.GetTimerValue());
		}
	}

	void NetRequestWin(AHazePlayerCharacter Winner)
	{
		if(!HasControl())
			return;
		if(bMiniGameActive)
			NetPlayerWin(Winner, MiniGameComp.GetTimerValue());
	}

	UFUNCTION(NetFunction)
	void NetPlayerWin(AHazePlayerCharacter Winner, float TimeScore)
	{
		if(bStartFinishMiniGameTriggerd)
			return;

		Cody.RemoveCapability(TrackRunnerCapability);
		May.RemoveCapability(TrackRunnerCapability);

		SetObstacleMiniGameEnded();
		ScoreTimer = TimeScore;
		float GameTimer = TimeScore;
		FText GameTimerText = Text::Conv_FloatToText(GameTimer, ERoundingMode::FromZero, false, true, 2, 4,2,2);
		TextRenderer.TextRender.SetText(GameTimerText);

		PlayerWinner = Winner;

		bStartFinishMiniGameTriggerd = true;
		bAllowSpawning = false;	

		if (PlayerWinner != nullptr)
			MiniGameComp.SetScore(PlayerWinner, TimeScore);

		if (PlayerWinner == Game::Cody)
			MiniGameComp.SetScore(Game::May, MiniGameComp.ScoreData.MayHighScore);
		else
			MiniGameComp.SetScore(Game::Cody, MiniGameComp.ScoreData.CodyHighScore);

		System::SetTimer(this, n"DelayedAnnounceWinner", 0.3f, false);
	}

	UFUNCTION()
	void DelayedAnnounceWinner()
	{
		if(PlayerWinner != nullptr)
		{
			MiniGameComp.AnnounceWinner(PlayerWinner);
		}
		else
		{
			MiniGameComp.AnnounceWinner(EMinigameWinner::Draw);
		}

		OnStartFinishMiniGame.Broadcast();
	}

	UFUNCTION()
	void PlayerCanceledMiniGame()
	{
        FadeToBlack();
		System::SetTimer(this, n"DeactiveManager", 1.f, false);
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	//	PrintToScreen("bAllowSpawning " + bAllowSpawning);
		
		if(bAllowSpawning)
		{
			TrackRunnerMeshLeftSide.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"SpeedParam", Time::GetGameTimeSeconds());
			TrackRunnerMeshRightSide.StaticMeshComponent.SetScalarParameterValueOnMaterials(n"SpeedParam", Time::GetGameTimeSeconds());

			ObstacleSpawnRateTimer -= DeltaTime;
			if(ObstacleSpawnRateTimer <= 0)
			{
				ObstacleSpawnRateTimer = ObstacleSpawnRate;
				OnSpawnObstacle.Broadcast();
			}
		
			float GameTimer = MiniGameComp.GetTimerValue();
			FText GameTimerText = Text::Conv_FloatToText(GameTimer, ERoundingMode::FromZero, false, true, 2, 4,2,2);
			TextRenderer.TextRender.SetText(GameTimerText);
		}
		
		ActivateSmokeTimer -= DeltaTime;
		if(ActivateSmokeTimer <= 47)
		{
			if(!bFirstSmokeActivated)
			{
				if(this.HasControl())
				{
					bFirstSmokeActivated = true;
					OnStartSmoke();
				}
			}
		}
		if(ActivateSmokeTimer <= 17)
		{
			if(!bSecondSmokeActivated)
			{
				if(this.HasControl())
				{
					bSecondSmokeActivated = true;
					OnStartSmoke();
				}
			}
		}
		
		if(SmokeActive == true)
		{
			SmokeTimer -= DeltaTime;
			if(SmokeTimer <= 0)
			{
				if(this.HasControl())
				{
					DeactiveSmoke();
				}
			}
		}
	}

    UFUNCTION()
	void BeginStartEndMiniGame()
	{
		FadeToBlack();
		System::SetTimer(this, n"DeactiveManager", 1.0f, false);
	}

	UFUNCTION()
	void DeactiveManager()
	{
     	P1Trail.NiagaraComponent.Deactivate();
		P2Trail.NiagaraComponent.Deactivate();
		P1Trail.DetachFromActor();
		P2Trail.DetachFromActor();
		bStartRunAnimation = false;
		PlayerWinner = nullptr;
		bMiniGameActive = false;
		SetObstacleManualDisable();
		OnManagerDeactivated.Broadcast();
		ScoreTimer = ScoreTimerOriginal;
		SetCymbalVisible(true);
		MiniGameComp.ResetScoreBoth();
		// MiniGameComp.EndGameHud();
		DoubleInteraction.EnableActor(this);

		DettachPlayerMeshes();

		Game::GetMay().TriggerMovementTransition(this);
		//Game::GetMay().RemoveLocomotionFeature(MayFeature);
		Game::GetMay().TeleportActor(LeftPlayerInteractionStart.GetActorLocation(), LeftPlayerInteractionStart.GetActorRotation());
		Game::GetMay().SnapCameraBehindPlayer();
		Game::GetCody().TriggerMovementTransition(this);
		//Game::GetCody().RemoveLocomotionFeature(CodyFeature);
		Game::GetCody().TeleportActor(RightPlayerInteractionStart.GetActorLocation(), RightPlayerInteractionStart.GetActorRotation());
		Game::GetCody().SnapCameraBehindPlayer();

		//Game::GetMay().SetCapabilityAttributeObject(n"TrackRunner", nullptr);
		Game::GetMay().UnblockCapabilities(n"PowerfulSong", this);
		Game::GetMay().UnblockCapabilities(n"Songoflife", this);
		Game::GetMay().DeactivateCameraByInstigator(this);
		Game::GetMay().RemoveCapabilitySheet(MiniGameComp.PlayerBlockMovementCapabilitySheet);
		Game::GetMay().UnblockMovementSyncronization();
		Game::GetMay().UnblockCapabilities(n"PlayerMarker", this);

		//Game::GetCody().SetCapabilityAttributeObject(n"TrackRunner", nullptr);
		Game::GetCody().UnblockCapabilities(n"Cymbal", this);
		Game::GetCody().DeactivateCameraByInstigator(this);
		Game::GetCody().RemoveCapabilitySheet(MiniGameComp.PlayerBlockMovementCapabilitySheet);
		Game::GetCody().UnblockMovementSyncronization();
		Game::GetCody().UnblockCapabilities(n"PlayerMarker", this);

		Game::GetCody().DeactivateCamera(RightInGameCameraActor.Camera, 0);
		Game::GetMay().DeactivateCamera(LeftInGameCameraActor.Camera, 0);
	}

	UFUNCTION()
	void AttachPlayerMeshes()
	{
		MayHair.AttachToActor(May, n"Hair2", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MaySpineOne.AttachToActor(May, n"Spine1", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MaySpineTwo.AttachToActor(May, n"Spine2", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayHips.AttachToActor(May, n"Hips", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayLeftArm.AttachToActor(May, n"LeftArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayLeftFoot.AttachToActor(May, n"LeftFoot", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayLeftForeArm.AttachToActor(May, n"LeftForeArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayLeftHand.AttachToActor(May, n"LeftHand", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayLeftLeg.AttachToActor(May, n"LeftLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayLeftToeBase.AttachToActor(May, n"LeftToeBase", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayLeftUpLeg.AttachToActor(May, n"LeftUpLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayRightArm.AttachToActor(May, n"RightArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayRightFoot.AttachToActor(May, n"RightFoot", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayRightForeArm.AttachToActor(May, n"RightForeArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayRightHand.AttachToActor(May, n"RightHand", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayRightLeg.AttachToActor(May, n"RightLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayRightToeBase.AttachToActor(May, n"RightToeBase", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		MayRightUpLeg.AttachToActor(May, n"RightUpLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);

		CodySpineOne.AttachToActor(Cody, n"Spine1", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodySpineTwo.AttachToActor(Cody, n"Spine2", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyHips.AttachToActor(Cody, n"Hips", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyLeftArm.AttachToActor(Cody, n"LeftArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyLeftFoot.AttachToActor(Cody, n"LeftFoot", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyLeftForeArm.AttachToActor(Cody, n"LeftForeArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyLeftHand.AttachToActor(Cody, n"LeftHand", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyLeftLeg.AttachToActor(Cody, n"LeftLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyLeftToeBase.AttachToActor(Cody, n"LeftToeBase", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyLeftUpLeg.AttachToActor(Cody, n"LeftUpLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyRightArm.AttachToActor(Cody, n"RightArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyRightFoot.AttachToActor(Cody, n"RightFoot", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyRightForeArm.AttachToActor(Cody, n"RightForeArm", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyRightHand.AttachToActor(Cody, n"RightHand", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyRightLeg.AttachToActor(Cody, n"RightLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyRightToeBase.AttachToActor(Cody, n"RightToeBase", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CodyRightUpLeg.AttachToActor(Cody, n"RightUpLeg", EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
	}
	UFUNCTION()
	void DettachPlayerMeshes()
	{
		MayHair.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MaySpineOne.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MaySpineTwo.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayHips.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayLeftArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayLeftFoot.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayLeftForeArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayLeftHand.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayLeftLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayLeftToeBase.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayLeftUpLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayRightArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayRightFoot.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayRightForeArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayRightHand.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayRightLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayRightToeBase.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		MayRightUpLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		CodySpineOne.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodySpineTwo.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyHips.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyLeftArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyLeftFoot.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyLeftForeArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyLeftHand.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyLeftLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyLeftToeBase.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyLeftUpLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyRightArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyRightFoot.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyRightForeArm.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyRightHand.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyRightLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyRightToeBase.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		CodyRightUpLeg.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}


	UFUNCTION(NetFunction)
	void OnStartSmoke()
	{
		if(!bMiniGameActive)
			return;

		SmokeActive = true;
		SmokeLeftSide1.NiagaraComponent.Activate();
		SmokeLeftSide2.NiagaraComponent.Activate();
		SmokeLeftSide3.NiagaraComponent.Activate();
		SmokeLeftSide4.NiagaraComponent.Activate();
		SmokeRightSide1.NiagaraComponent.Activate();
		SmokeRightSide2.NiagaraComponent.Activate();
		SmokeRightSide3.NiagaraComponent.Activate();
		SmokeRightSide4.NiagaraComponent.Activate();
	}
	UFUNCTION(NetFunction)
	void DeactiveSmoke()
	{
		SmokeActive = false;
		SmokeTimer = SmokeTimerOriginal;
		SmokeRightSide1.NiagaraComponent.Deactivate();
		SmokeRightSide2.NiagaraComponent.Deactivate();
		SmokeRightSide3.NiagaraComponent.Deactivate();
		SmokeRightSide4.NiagaraComponent.Deactivate();
		SmokeLeftSide1.NiagaraComponent.Deactivate();
		SmokeLeftSide2.NiagaraComponent.Deactivate();
		SmokeLeftSide3.NiagaraComponent.Deactivate();
		SmokeLeftSide4.NiagaraComponent.Deactivate();
	}


	UFUNCTION()
	void SetObstacleMiniGameEnded()
	{
		for(auto Obstacle: ObstacleSmallContainer.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleSmallContainer.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleMediumLeftContainer.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleMediumLeftContainer.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleMediumRightContainer.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleMediumRightContainer.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleJumpBigContainer.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleJumpBigContainer.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}


		for(auto Obstacle: ObstacleSmallMovingLeft.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleSmallMovingLeft.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleSmallMovingRight.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleSmallMovingRight.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleBigMovingLeft.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleBigMovingLeft.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleBigMovingRight.RightContainer)
		{
			Obstacle.OnMiniGameEnded();
		}
		for(auto Obstacle: ObstacleBigMovingRight.LeftContainer)
		{
			Obstacle.OnMiniGameEnded();
		}		
	}

	UFUNCTION()
	void SetObstacleManualDisable()
	{
		for(auto Obstacle: ObstacleSmallContainer.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleSmallContainer.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleMediumLeftContainer.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleMediumLeftContainer.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleMediumRightContainer.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleMediumRightContainer.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleJumpBigContainer.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleJumpBigContainer.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}


		for(auto Obstacle: ObstacleSmallMovingLeft.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleSmallMovingLeft.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleSmallMovingRight.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleSmallMovingRight.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleBigMovingLeft.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleBigMovingLeft.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleBigMovingRight.RightContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}
		for(auto Obstacle: ObstacleBigMovingRight.LeftContainer)
		{
			Obstacle.OnManualDisable(bForceImmediate = true);
		}		
	}
}

enum EObstacles
{
	Small,
	MediumLeft,
	MediumRight,
	JumpBig,
	SmallMovingLeft,
	SmallMovingRight,
	BigMovingLeft,
	BigMovingRight
}


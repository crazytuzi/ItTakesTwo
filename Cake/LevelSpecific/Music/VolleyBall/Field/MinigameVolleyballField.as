
import Cake.LevelSpecific.Music.VolleyBall.Field.MinigameVolleyballJudge;
import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;
import Vino.MinigameScore.MinigameComp;

import void InitializeNewGame(AHazePlayerCharacter Player, AMinigameVolleyballField) from "Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer";
import void SpawnBall(FVolleyballSpawnBallData) from "Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer";
import void ClearVolleyballPlayerComponents(AMinigameVolleyballField) from "Cake.LevelSpecific.Music.VolleyBall.Player.MinigameVolleyballPlayer";

struct FVolleyballSpawnBallData
{
	UPROPERTY()
	EHazePlayer ForPlayer;

	UPROPERTY()
	TSubclassOf<AMinigameVolleyballBall> Class;

	UPROPERTY()
	bool bBallIsGood = true;

	UPROPERTY()
	AMinigameVolleyballBall SpawnFromBall;

	UPROPERTY()
	int MainBallBouncesToNewBall = -1;

	UPROPERTY()
	AMinigameVolleyballBall BallToApplyTo;

	UPROPERTY()
	UMinigameVolleyballJudge FromJudge;
}

UCLASS(Abstract)
class UMinigameVolleyballWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly)
	int MaxScore = 0;

	UPROPERTY(BlueprintReadOnly)
	int CodyCurrentScore = 0;

	UPROPERTY(BlueprintReadOnly)
	int MayCurrentScore = 0;

	UFUNCTION(BlueprintEvent)
	void OnScoreUpdate()
	{
		Log("Blueprint did not override this event.");
	}
}

UCLASS(Abstract)
class AMinigameVolleyballField : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BallBounds;
	default BallBounds.bGenerateOverlapEvents = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent NetCollision;
	default NetCollision.bGenerateOverlapEvents = false;
	default NetCollision.SetCollisionProfileName(n"BlockAll");

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlayerOneStartLocation;
	default PlayerOneStartLocation.SetRelativeLocation(FVector(1000, 0, 0));

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlayerTwoStartLocation;
	default PlayerTwoStartLocation.SetRelativeLocation(FVector(-1000, 0, 0));

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComponent;
	// default MinigameComponent.TambourineSpawnRelativeOffset = FVector(1540, 1540, 200);
	default MinigameComponent.MinigameTag = EMinigameTag::Volleyball;

	UPROPERTY(Category = "Default")
	int ScoreToWin = 12;

	UPROPERTY(EditDefaultsOnly, Category = "Default")
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY(EditConst, Category = "Default")
	TArray<AHazeActor> Balls;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMinigameVolleyballJudge AngelJudge;

	UPROPERTY(DefaultComponent, Attach = Root)
	UMinigameVolleyballJudge DevilJudge;

	private int _BallNetworkIndex = 0;
	private TPerPlayer<int> _PlayerScore;
	private EHazePlayer _StartingPlayerType = EHazePlayer::MAX;
	
	float ActiveBallTime = 0;
	int GoodBallSpawnsSinceEvilBall = 0;
	int MainBallSwappedSide = 0;

	bool bGameHasStarted = false;

	int RVoPlayer;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{	
		NetCollision.SetRelativeLocation(FVector(0.f, 0.f, NetCollision.GetScaledBoxExtent().Z));
	}

	UFUNCTION(NotBlueprintCallable)
    protected void OnLeftBounds(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		if(!OtherActor.HasControl())
			return;

 		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			FHazeDelegateCrumbParams CrumbData;
			CrumbData.AddObject(n"WinningPlayer", Player.GetOtherPlayer());
			UHazeCrumbComponent::Get(Player).LeaveAndTriggerDelegateCrumb(
				FHazeCrumbDelegate(this, n"Crumb_EndGame"),
				CrumbData);
		}
		else
		{
			RemovePotentialOutsideBall(OtherActor);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void Crumb_EndGame(FHazeDelegateCrumbData CrumbData)
	{
		auto Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"WinningPlayer"));
		EndVolleyballGame(Player);
	}

	UFUNCTION()
	void StartGame(AHazePlayerCharacter StartingPlayer)
	{
		if(_StartingPlayerType !=  EHazePlayer::MAX)
			return;

		_StartingPlayerType = StartingPlayer.Player;
		_PlayerScore[0] = 0;
		_PlayerScore[1] = 0;
		MinigameComponent.SetScore(StartingPlayer, 0);
		MinigameComponent.SetScore(StartingPlayer.GetOtherPlayer(), 0);

		ActiveBallTime = 0;
		GoodBallSpawnsSinceEvilBall = 0;
		MainBallSwappedSide = 0;
		bGameHasStarted = false;

		MinigameComponent.OnMinigameTutorialComplete.AddUFunction(this, n"OnTutorialAccepted");
		MinigameComponent.OnTutorialCancel.AddUFunction(this, n"OnTutorialCanceled");
		MinigameComponent.ActivateTutorial();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTutorialAccepted()
	{
		auto StartingPlayer = Game::GetPlayer(_StartingPlayerType);
		auto SecondPlayer = StartingPlayer.GetOtherPlayer();

		InitializeNewGame(StartingPlayer, this);
		InitializeNewGame(SecondPlayer, this);

		// Since the players can leave the area during the countdown, we need to block them
		for(auto Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(CapabilityTags::StickInput, this);
			Player.BlockCapabilities(MovementSystemTags::Dash, this);
			Player.BlockCapabilities(MovementSystemTags::AirDash, this);
			Player.BlockCapabilities(n"LongJump", this);
		}

		BallBounds.OnComponentEndOverlap.AddUFunction(this, n"OnLeftBounds");

		AngelJudge.SetVisibility(true);
		AngelJudge.PlayIdleAnimation();
		Niagara::SpawnSystemAtLocation(AngelJudge.ShowUpEffect, AngelJudge.GetWorldLocation(), AngelJudge.GetWorldRotation());

		DevilJudge.SetVisibility(true);
		DevilJudge.PlayIdleAnimation();
		Niagara::SpawnSystemAtLocation(DevilJudge.ShowUpEffect, DevilJudge.GetWorldLocation(), DevilJudge.GetWorldRotation());

		MinigameComponent.OnCountDownCompletedEvent.AddUFunction(this, n"StartGameInternal");
		MinigameComponent.StartCountDown();
	}
	
	UFUNCTION(NotBlueprintCallable)
	private void OnTutorialCanceled()
	{
		bGameHasStarted = false;
		_StartingPlayerType = EHazePlayer::MAX;
	}

	UFUNCTION(NotBlueprintCallable)
	private void StartGameInternal()
	{
		if(_StartingPlayerType ==  EHazePlayer::MAX)
			return;

		for(auto Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(CapabilityTags::StickInput, this);
			Player.UnblockCapabilities(MovementSystemTags::Dash, this);
			Player.UnblockCapabilities(MovementSystemTags::AirDash, this);
			Player.UnblockCapabilities(n"LongJump", this);
		}

		// Setup the orignal ball
		bGameHasStarted = true;
		FVolleyballSpawnBallData RegularBall;
		RegularBall.ForPlayer = _StartingPlayerType;
		AngelJudge.GetBallTypeToSpawn(RegularBall.Class);
		RegularBall.bBallIsGood = true;
		RegularBall.FromJudge = AngelJudge;
		RegularBall.MainBallBouncesToNewBall = 4;
		SpawnBall(RegularBall);
	}

	UFUNCTION()
	void EndVolleyballGame(AHazePlayerCharacter WinningPlayer)
	{
		if(_StartingPlayerType ==  EHazePlayer::MAX)
			return;

		bGameHasStarted = false;
		BallBounds.OnComponentEndOverlap.Clear();
		_StartingPlayerType = EHazePlayer::MAX;
		ClearVolleyballPlayerComponents(this);

		AngelJudge.SetVisibility(false);
		Niagara::SpawnSystemAtLocation(AngelJudge.DisappearEffect, AngelJudge.GetWorldLocation(), AngelJudge.GetWorldRotation());

		DevilJudge.SetVisibility(false);
		Niagara::SpawnSystemAtLocation(DevilJudge.DisappearEffect, DevilJudge.GetWorldLocation(), DevilJudge.GetWorldRotation());

		if(HasControl())
			NetEndVolleyballGame(WinningPlayer);
	}

	UFUNCTION(NetFunction)
	private void NetEndVolleyballGame(AHazePlayerCharacter WinningPlayer)
	{
		MinigameComponent.AnnounceWinner(WinningPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(Balls.Num() > 0)
		{
			ActiveBallTime += DeltaTime;
		}
	}

	void GiveScoreToPlayer(EHazePlayer Player)
	{
		_PlayerScore[int(Player)]++;
		MinigameComponent.AdjustScore(Game::GetPlayer(Player));

		int RPlay = FMath::RandRange(0, 1);

		if (RVoPlayer == 0)
		{
			if (Player == EHazePlayer::Cody)
			{
				if (RPlay == 0)
					MinigameComponent.PlayTauntAllVOBark(Game::Cody);
				else
					MinigameComponent.PlayFailGenericVOBark(Game::May);
			}
			else
			{
				if (RPlay == 0)
					MinigameComponent.PlayTauntAllVOBark(Game::May);
				else
					MinigameComponent.PlayFailGenericVOBark(Game::Cody);				
			}

			RVoPlayer = FMath::RandRange(1, 2);
		}
		else
		{
			RVoPlayer--;
		}

		// The winner!!
		if(_PlayerScore[int(Player)] >= ScoreToWin)
		{
			EndVolleyballGame(Game::GetPlayer(Player));
		}
	}

	void ShowWorldScoreWidget(AHazePlayerCharacter Player, AActor SpawnLocation)
	{
		FMinigameWorldWidgetSettings MinigameWorldSettings;

		MinigameWorldSettings.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
		MinigameWorldSettings.TextJuice = EInGameTextJuice::BigChange;
		MinigameWorldSettings.MoveSpeed = 30.f;
		MinigameWorldSettings.TimeDuration = 0.5f;
		MinigameWorldSettings.FadeDuration = 0.6f;
		MinigameWorldSettings.TargetHeight = 140.f;
		MinigameWorldSettings.MinigameTextColor = Player.IsMay() ? EMinigameTextColor::May : EMinigameTextColor::Cody;
	
		MinigameComponent.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "1", SpawnLocation.ActorLocation, MinigameWorldSettings);
	}

	UFUNCTION(BlueprintPure)
	int GetPlayerScore(AHazePlayerCharacter ForPlayer) const
	{
		return _PlayerScore[int(ForPlayer.Player)];
	}

	int GetBallNetworkIndexWithIncrement()
	{
		_BallNetworkIndex++;
		return _BallNetworkIndex;
	}

	bool IsStartingPlayer(AHazePlayerCharacter Player) const
	{
		return Player.Player == _StartingPlayerType;
	}

	void GetGoodBallTypeToSpawn(FVolleyballSpawnBallData& OutData)
	{
		AngelJudge.GetBallTypeToSpawn(OutData.Class);
		OutData.bBallIsGood = true;
		OutData.FromJudge = AngelJudge;

		if(Balls.Num() > 1)
			OutData.FromJudge = DevilJudge;

		GoodBallSpawnsSinceEvilBall++;	
	}

	void GetEvilBallTypeToSpawn(FVolleyballSpawnBallData& OutData)
	{
		AngelJudge.GetBallTypeToSpawn(OutData.Class);
		OutData.bBallIsGood = false;
		OutData.FromJudge = DevilJudge;
		GoodBallSpawnsSinceEvilBall = 0;
	}
	
	FVector ClosestPositionOnNet(FVector FromLocation)
	{
		FVector ClosestPoint;
		NetCollision.GetClosestPointOnCollision(FromLocation, ClosestPoint);
		return ClosestPoint;
	}

	USceneComponent GetTargetLocation(AHazePlayerCharacter ForPlayer) const
	{
		if(ForPlayer.Player == _StartingPlayerType)
			return PlayerOneStartLocation;
		else
			return PlayerTwoStartLocation;
	}

	FTransform GetFieldTransformForPlayer(AHazePlayerCharacter ForPlayer) const
	{
		if(ForPlayer.Player != _StartingPlayerType)
		{
			return GetActorTransform();
		}
		else
		{
			return FTransform((-GetActorForwardVector()).ToOrientationRotator(), GetActorLocation());
		}
	}
}

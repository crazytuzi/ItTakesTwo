
import Cake.LevelSpecific.Music.VolleyBall.Field.MinigameVolleyballField;
import Cake.LevelSpecific.Music.VolleyBall.Field.MinigameVolleyballJudge;
import Cake.LevelSpecific.Music.VolleyBall.Ball.MinigameVollyeballBall;
import Vino.Movement.Dash.CharacterDashSettings;


void InitializeNewGame(AHazePlayerCharacter Player, AMinigameVolleyballField Field)
{
	// This will add the component
	Player.AddCapabilitySheet(Field.PlayerSheet, EHazeCapabilitySheetPriority::OverrideAll);

	auto Comp = UMinigameVolleyballPlayerComponent::Get(Player);
	if(Comp != nullptr)
	{
		Comp.Field = Field;	
	}
}

void ClearVolleyballPlayerComponents(AMinigameVolleyballField Field)
{
	auto& Players = Game::GetPlayers();
	for(AHazePlayerCharacter Player : Players)
	{
		auto Comp = UMinigameVolleyballPlayerComponent::Get(Player);
		if(Comp != nullptr)
		{
			Comp.Balls.Reset();
			Player.RemoveCapabilitySheet(Field.PlayerSheet);	
		}
	}

	for(int i = Field.Balls.Num() - 1; i >= 0; --i)
	{
		Field.Balls[i].DestroyActor();
	}

	Field.Balls.Reset();
}

void SpawnBall(FVolleyballSpawnBallData Data)
{
	ensure(Data.ForPlayer != EHazePlayer::MAX);
	AHazePlayerCharacter Player = Game::GetPlayer(Data.ForPlayer);		

	auto Comp = UMinigameVolleyballPlayerComponent::Get(Player);
	if(Comp != nullptr)
	{		
		FVector StartLocation = Data.FromJudge.GetWorldLocation();
		StartLocation += FVector(0.f, 0.f, 200.f);
	
		auto Ball = Cast<AMinigameVolleyballBall>(SpawnActor(Data.Class, StartLocation, bDeferredSpawn = true, Level = Player.GetLevel()));
		Ball.MakeNetworked(Comp.Field, Comp.Field.GetBallNetworkIndexWithIncrement());

		if(Player.IsMay())
		{
			Ball._TargetLocations.Add(Comp.Field.GetTargetLocation(Player));
			Ball._TargetLocations.Add(Comp.Field.GetTargetLocation(Player.GetOtherPlayer()));
		}
		else
		{
			Ball._TargetLocations.Add(Comp.Field.GetTargetLocation(Player.GetOtherPlayer()));
			Ball._TargetLocations.Add(Comp.Field.GetTargetLocation(Player));
		}

		Ball.SetControlSide(Player);
		Ball._ControllingPlayer = Player.Player;
		Ball._CenterLocation = Comp.Field.Root;
		Ball._Net = Comp.Field.NetCollision;
		Ball._GroundZ = Comp.Field.GetActorLocation().Z;
		if(Data.BallToApplyTo != nullptr)
		{
			Data.BallToApplyTo.MainBallBouncsesLeftToNewBall = Data.MainBallBouncesToNewBall;
		}
		else
		{
			Ball.MainBallBouncsesLeftToNewBall = Data.MainBallBouncesToNewBall;
			Ball.bIsMainBall = Ball.MainBallBouncsesLeftToNewBall >= 0;
		}
		FinishSpawningActor(Ball);

		Comp.Balls.Add(Ball);
		Comp.Field.Balls.Add(Ball);
		Comp.Field.ActiveBallTime = 0;

		if(Data.bBallIsGood)
			Comp.Field.GoodBallSpawnsSinceEvilBall++;
		else
			Comp.Field.GoodBallSpawnsSinceEvilBall = 0;

		Ball.AddSpawnForce(Data.bBallIsGood);
		Data.FromJudge.PlayThrowAnimation();
	}
}

void AddBallToPlayerComponent(AHazePlayerCharacter Player, AMinigameVolleyballBall Ball)
{
	auto Comp = UMinigameVolleyballPlayerComponent::Get(Player);
	if(Comp != nullptr)
		Comp.Balls.Add(Ball);
}


void RemoveBallFromPlayerComponent(AHazePlayerCharacter Player, AMinigameVolleyballBall Ball)
{
	auto Comp = UMinigameVolleyballPlayerComponent::Get(Player);
	if(Comp != nullptr)
		Comp.Balls.RemoveSwap(Ball);
}

void DestroyBall(AMinigameVolleyballBall Ball)
{
	auto Comp = UMinigameVolleyballPlayerComponent::Get(Game::GetMay());
	if(Comp != nullptr)
	{
		Comp.Balls.RemoveSwap(Ball);
		Comp.Field.Balls.RemoveSwap(Ball);
	}

	auto OtherComp = UMinigameVolleyballPlayerComponent::Get(Game::GetCody());
	if(OtherComp != nullptr)
	{
		OtherComp.Balls.RemoveSwap(Ball);
	}

	Ball.DestroyActor();
}

void ApplyPlayerAnimation(AHazePlayerCharacter Player, EMinigameVolleyballMoveType MoveType)
{
	auto VolleyBallComp = UMinigameVolleyballPlayerComponent::Get(Player);
	if(MoveType == EMinigameVolleyballMoveType::Smash)
	{
		Player.PlayForceFeedback(VolleyBallComp.SmashForceFeedback, false, true, n"VolleyBallSmash");
		Player.PlaySlotAnimation(VolleyBallComp.SmashAnimation);
	}
	else if(MoveType == EMinigameVolleyballMoveType::UpAndOver)
	{
		Player.PlayForceFeedback(VolleyBallComp.HitForceFeedback, false, true, n"VolleyBallHit");
		Player.PlaySlotAnimation(VolleyBallComp.ShootUpWardsAnimation);
	}
	else if(MoveType == EMinigameVolleyballMoveType::Serve)
	{
		Player.PlayForceFeedback(VolleyBallComp.HitForceFeedback, false, true, n"VolleyBallHit");
		Player.PlaySlotAnimation(VolleyBallComp.ShootUpWardsAnimation);
	}
}

UCLASS(Abstract, HideCategories = "ComponentTick Activation Cooking ComponentReplication Variable Tags AssetUserData Collision")
class UMinigameVolleyballPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Camera")
	UHazeCameraSettingsDataAsset CameraSettings;

	UPROPERTY(EditDefaultsOnly, Category = "Effect")
	UNiagaraSystem GiveScoreEffectType;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams ShootUpWardsAnimation;

	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySlotAnimationParams SmashAnimation;

	UPROPERTY()
	UForceFeedbackEffect HitForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect SmashForceFeedback;

	UPROPERTY(Transient, EditConst, Category = "Default")
	AMinigameVolleyballField Field;

	UPROPERTY(Transient, EditConst, Category = "Default")
	TArray<AMinigameVolleyballBall> Balls;
}


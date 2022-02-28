import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTileEffect;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;

class ACastleChessBossExplodingOrb : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Orb1;
	default Orb1.SetRelativeRotation(FRotator(0.f, 0.f, 0.f));

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Orb2;
	default Orb2.SetRelativeRotation(FRotator(0.f, 90.f, 0.f));

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Orb3;
	default Orb3.SetRelativeRotation(FRotator(0.f, 180.f, 0.f));

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Orb4;
	default Orb4.SetRelativeRotation(FRotator(0.f, 270.f, 0.f));

	float OrbSpeed = 1000.f;

	TArray<UArrowComponent> Orbs;
	TArray<FVector2D> AffectedTiles;

	AChessboard Chessboard;
	FVector2D TileLocation;	
	FVector StartLocation;
	FVector EndLocation;

	UPROPERTY()
	TSubclassOf<ACastleChessTileEffect> TileEffectType;

	UPROPERTY()
	FHazeTimeLike EnterTimelike;
	default EnterTimelike.Duration = 1.f;
	float EnterPeakHeight = 800.f;

	const float IdleDuration = 2.5f;
	float IdleDurationCurrent = 0.f;

	const float ActiveDuration = 4.5f;
	float CurrentActiveDuration = 0.f;	

	bool bActive = false;

	void StartOrb(AChessboard InChessboard, FVector2D InTileLocation)
	{
		Chessboard = InChessboard;
		TileLocation = InTileLocation;
		StartLocation = ActorLocation;
		EndLocation = Chessboard.GetSquareCenter(InTileLocation);

		EnterTimelike.PlayFromStart();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Orbs.Add(Orb1);
		Orbs.Add(Orb2);
		Orbs.Add(Orb3);
		Orbs.Add(Orb4);

		EnterTimelike.BindUpdate(this, n"OnEnterUpdate");
		EnterTimelike.BindFinished(this, n"OnEnterFinished");
	}

	UFUNCTION()
	void OnEnterUpdate(float Value)
	{
		FVector TargetLocation = FMath::Lerp(StartLocation, EndLocation, Value);
		TargetLocation += FVector::UpVector * EnterPeakHeight * FMath::Sin(Value * PI);

		SetActorLocation(TargetLocation);
	}

	UFUNCTION()
	void OnEnterFinished()
	{
		SetActorLocation(EndLocation);
		bActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		if (IdleDurationCurrent < IdleDuration)
			IdleDurationCurrent += DeltaTime;
		else if (CurrentActiveDuration >= ActiveDuration)
			DestroyActor();
		else
		{	
			CurrentActiveDuration += DeltaTime;
			MoveOrbs(DeltaTime);			
		}
	}

	void MoveOrbs(float DeltaTime)
	{
		TArray<UArrowComponent> OrbsToDestroy;

		for (UArrowComponent Orb : Orbs)
		{
			FVector MoveDirection = Orb.ForwardVector;
			FVector DeltaMove = MoveDirection * OrbSpeed * DeltaTime;

			Orb.AddWorldOffset(DeltaMove);

			if (!CheckAndDamageUniqueTile(Orb.WorldLocation))
				OrbsToDestroy.Add(Orb);
		}

		for (UArrowComponent Orb : OrbsToDestroy)
		{
			DestroyOrb(Orb);
		}
	}

	bool CheckAndDamageUniqueTile(FVector WorldLocation)
	{
		FVector2D TileCoordinate;
		if (Chessboard.GetGridPosition(WorldLocation, TileCoordinate))
		{
			if (!AffectedTiles.Contains(TileCoordinate))
			{
				SpawnActor(TileEffectType, Chessboard.GetSquareCenter(TileCoordinate));
				AffectedTiles.Add(TileCoordinate);

			}
			return true;
		}

		return false;			
	}

	void DestroyOrb(UArrowComponent Orb)
	{
		Orb.SetHiddenInGame(true, true);
		Orbs.Remove(Orb);
	}
}
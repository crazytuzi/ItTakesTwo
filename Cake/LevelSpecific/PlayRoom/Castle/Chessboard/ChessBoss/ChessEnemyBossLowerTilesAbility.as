import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

class UCastleEnemyChessBossAbilityLowerTiles : UChessBossAbility
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	default Cooldown = 18.f;
	default BossAbility.Priority = EBossAbilityPriority::Medium;

	TArray<FTileSquareTimer> TilesToLower;

	const float TileStaggerTime = 0.075f;
	const float LoweredTime = 7.5f;

	TArray<FVector2D> JumpLocations;
	default JumpLocations.Add(FVector2D(1.f, 1.f));
	default JumpLocations.Add(FVector2D(1.f, 6.f));
	default JumpLocations.Add(FVector2D(6.f, 1.f));
	default JumpLocations.Add(FVector2D(6.f, 6.f));

	UPROPERTY()
	FHazeTimeLike JumpTimelike;
	default JumpTimelike.Duration = 1.6f;
	const float JumpHeight = 1200.f;
	bool bLanded = false;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> JumpLandCameraShake;
	UPROPERTY()
	FRuntimeFloatCurve VerticalMovement;

	FVector2D TargetJumpTileCoordinate;
	FVector TargetJumpLocation;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		JumpTimelike.BindUpdate(this, n"OnJumpUpdate");
		JumpTimelike.BindFinished(this, n"OnJumpFinished");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Owner.BlockCapabilities(n"ChessboardMovement", this);
		Owner.BlockCapabilities(n"CastleEnemyFalling", this);

		
		bLanded = false;
		StartLocation = Owner.ActorLocation;

		int LocationInt = FMath::RandRange(0, JumpLocations.Num() - 1);
		TargetJumpTileCoordinate = JumpLocations[LocationInt];
		TargetJumpLocation = PieceComp.Chessboard.GetSquareCenter(TargetJumpTileCoordinate);

		JumpTimelike.PlayFromStart();

		UpdateTilesToLower();
		NormalizeTileDurations();
		TelegraphTilesToLower();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"ChessboardMovement", this);
		Owner.UnblockCapabilities(n"CastleEnemyFalling", this);


		AbilitiesComp.AbilityFinished();
		CurrentCooldown = Cooldown;
	}

	UFUNCTION()
	void OnJumpUpdate(float Value)
	{
		FVector NewLocation = FMath::Lerp(StartLocation, TargetJumpLocation, Value);
		NewLocation.Z += VerticalMovement.GetFloatValue(Value) * JumpHeight;
		//NewLocation.Z += JumpHeight * FMath::Sin(Value * PI);	

		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnJumpFinished()
	{
		Owner.SetActorLocation(TargetJumpLocation);
		PieceComp.LandOnPosition(TargetJumpTileCoordinate);

		if (JumpLandCameraShake.IsValid())
			Game::GetMay().PlayCameraShake(JumpLandCameraShake, 10.f);

		bLanded = true;		
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		if (!bLanded)
			return false;

		if (TilesToLower.Num() == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (TilesToLower.Num() > 0 && bLanded)
			UpdateAndLowerTiles(DeltaTime);
	}

	void UpdateAndLowerTiles(float DeltaTime)
	{
		for (int Index = TilesToLower.Num() - 1; Index >= 0; Index --)
		{
			TilesToLower[Index].Duration -= DeltaTime;

			if (TilesToLower[Index].Duration <= 0.f)
			{
				LowerTile(TilesToLower[Index].TileCoordinate);
				TilesToLower.RemoveAt(Index);
			}
		}	
	}

	void UpdateTilesToLower()
	{
		TilesToLower.Empty();

		int RandomInt = FMath::RandRange(0, 2);
		bool MirrorDirection = FMath::RandBool();

		if (RandomInt == 0)
		{
			for (int Index = 0; Index <= 7; Index++)
			{
				int DirectionIndex = MirrorDirection ? 7 - Index : Index;

				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(3.f, DirectionIndex));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(4.f, DirectionIndex));
			}
		}
		else if (RandomInt == 1)
		{
			for (int Index = 0; Index <= 7; Index++)
			{
				int DirectionIndex = MirrorDirection ? 7 - Index : Index;
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(DirectionIndex, 3.f));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(DirectionIndex, 4.f));
			}
		}
		else if (RandomInt == 2)
		{
			for (int Index = 0; Index <= 7; Index++)
			{
				int DirectionIndex = MirrorDirection ? 7 - Index : Index;
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(3.f, Index));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(4.f, Index));
			}
			for (int Index = 0; Index <= 1; Index++)
			{
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(0.f, 3.f + Index));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(1.f, 3.f + Index));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(2.f, 3.f + Index));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(5.f, 3.f + Index));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(6.f, 3.f + Index));
				AddTileToLowerAndCalculateDuration(TilesToLower, FVector2D(7.f, 3.f + Index));
			}
		}

	
		// FString Tiles = 	"	X  X  Y  Y  X  X  X  X
		// 						X  X  X  X  X  X  X  X
		// 						X  X  X  X  X  X  X  X
		// 						X  X  X  X  X  X  X  X
		// 						X  X  X  X  X  X  X  X
		// 						X  X  X  X  X  X  X  X
		// 						X  X  X  X  X  X  X  X
		// 						X  X  X  X  X  X  X  X ";
	}

	void NormalizeTileDurations()
	{
		FVector2D NearestCoordinate;
		float Distance = BIG_NUMBER;
		float ExcessDuration = 0.f;

		for (FTileSquareTimer TileToLower :  TilesToLower)
		{
			float DistanceToKing = (PieceComp.Chessboard.GetSquareCenter(TileToLower.TileCoordinate) - Owner.ActorLocation).Size();

			if (DistanceToKing < Distance)
			{
				Distance = DistanceToKing;
				NearestCoordinate = TileToLower.TileCoordinate;
				ExcessDuration = TileToLower.Duration;
			}
		}

		for (FTileSquareTimer& TileToLower :  TilesToLower)
		{
			TileToLower.Duration -= ExcessDuration;
		}
	}

	void AddTileToLowerAndCalculateDuration(TArray<FTileSquareTimer>& TilesToLower, FVector2D TileCoordinate)
	{
		FVector TileLocation = PieceComp.Chessboard.GetTileActor(TileCoordinate).ActorLocation;
		float Distance = (TileLocation - TargetJumpLocation).Size();
		
		float Duration = 0.f;
		if (Distance != 0.f)
			Duration = (Distance / PieceComp.Chessboard.SquareSize.X) * TileStaggerTime;

		TilesToLower.Add(FTileSquareTimer(TileCoordinate, Duration));
	}

	void TelegraphTilesToLower()
	{
		for (FTileSquareTimer SquareTimer : TilesToLower)
			PieceComp.Chessboard.GetTileActor(SquareTimer.TileCoordinate).TelegraphTile(SquareTimer.Duration + JumpTimelike.Duration);
	}

	UFUNCTION()
	void LowerTile(FVector2D TileCoordinate)
	{
		PieceComp.Chessboard.GetTileActor(TileCoordinate).DropTile(LoweredTime);

		//bFinished = true;
	}
}
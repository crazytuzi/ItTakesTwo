import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleChessBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.CastleChessBossSpawn;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessBossManager;

class UCastleChessBossSpawnWaveCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");
    default CapabilityTags.Add(n"SpawnWave");

	default CapabilityDebugCategory = n"Gameplay";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 120;

	ACastleEnemy OwningBoss;
	UChessPieceComponent PieceComp;
	UCastleChessBossAbilitiesComponent AbilitiesComp;

	UPROPERTY()
	float CooldownMax = 11.f;
	float CooldownMin = 7.f;
	float CooldownCurrent = 5.f;
	int QueueRefreshCount = 0;
	int TotalNumberOfWaves = 0;

	float Duration = 1.5f;

	// float DamageSinceSpawn = 0.f;
	// float DamageRequiredForSpawn = 450.f;
	// bool bSpawnDueToDamage = false;

	// All of the chess pieces to choose between
	UPROPERTY(Category = Waves)
	TArray<FCastleChessPieceType> ChessPieceTypes;

	// The spawn will go through these waves sequentially
	UPROPERTY(Category = Waves)
	TArray<TSubclassOf<ACastleEnemy>> QueuedWaves;

	// The last wave that was spawned. Used to avoid duplicate waves
	TSubclassOf<ACastleEnemy> LastWave;

	ACastleChessBossManager BossManager;

	UChessPieceComponent KingChessPieceComp;
	UChessPieceComponent QueenChessPieceComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningBoss = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		AbilitiesComp = UCastleChessBossAbilitiesComponent::Get(Owner);
		BossManager = Cast<ACastleChessBossManager>(GetAttributeObject(n"BossManager"));
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (BossManager == nullptr)
			BossManager = Cast<ACastleChessBossManager>(GetAttributeObject(n"BossManager"));

		if (PieceComp.State == EChessPieceState::Fighting)
			CooldownCurrent += DeltaTime;

		//PrintToScreenScaled("Cooldown = " + CooldownCurrent);

		// if (DamageSinceSpawn >= DamageRequiredForSpawn)
		// 	bSpawnDueToDamage = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
        	return EHazeNetworkActivation::DontActivate;

		if (PieceComp.Chessboard != nullptr && PieceComp.Chessboard.bChessboardDisabled)
        	return EHazeNetworkActivation::DontActivate;

		if (PieceComp.State != EChessPieceState::Fighting)
        	return EHazeNetworkActivation::DontActivate;

		// if (PieceComp.bIsMoving)
		// 	return EHazeNetworkActivation::DontActivate;

		// if (bSpawnDueToDamage)
		// 	return EHazeNetworkActivation::ActivateUsingCrumb;

		if (CooldownCurrent < GetCooldownLength())
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (PieceComp.Chessboard.bChessboardDisabled)
        	EHazeNetworkDeactivation::DeactivateLocal;

		if (ActiveDuration < Duration)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	float GetCooldownLength() const
	{
		float HealthPercentage = FMath::Clamp(float(OwningBoss.Health) / float(OwningBoss.MaxHealth), 0.f, 1.f);
		return FMath::Lerp(CooldownMin, CooldownMax, HealthPercentage);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		CooldownCurrent = 0.f;
		PieceComp.Chessboard.bSpawningWaves = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PieceComp.Chessboard.bSpawningWaves = false;
		PieceComp.Chessboard.bBarkPlayed = false;

		// Don't spawn if the chessboard is disabled
		if (PieceComp.Chessboard.bChessboardDisabled)
        	return;		

		FCastleChessPieceType PieceType = GetSpawnType();
		if (!PieceType.Type.IsValid())
			return;

		switch (PieceType.SpawnType)
		{
		case ECastleChessSpawnType::Pawn:
			SpawnPawns();
		break;
		case ECastleChessSpawnType::Bishop:
			SpawnBishops();
		break;
		case ECastleChessSpawnType::Rook:
			SpawnRooks();
		break;
		case ECastleChessSpawnType::Knight:
			SpawnKnights();
		break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (OwningBoss.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleChessPiece";
			Request.SubAnimationTag = n"Summon";

			OwningBoss.Mesh.RequestLocomotion(Request);
		}

		if (BossManager.King.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleChessPiece";
			Request.SubAnimationTag = n"Summon";

			BossManager.King.Mesh.RequestLocomotion(Request);
		}
	}

	FCastleChessPieceType GetSpawnType()
	{
		FCastleChessPieceType SpawnSelection;

		if (QueuedWaves.Num() > 0)
		{
			SpawnSelection.Type = QueuedWaves[0];
			SpawnSelection.SpawnType = GetSpawnTypeFromType(SpawnSelection.Type);
			QueuedWaves.RemoveAt(0);
		}
		else
		{
			QueueRefreshCount += 1;

			/* Create a 'random' queue of 4 unique pieces.
				- Pieces cannot spawn two waves in a row (first of next can't be same as last of last)
				- Knights cannot succeed Rooks
			*/

			// Create the next queue
			TArray<TSubclassOf<ACastleEnemy>> PieceTypes;
			for (FCastleChessPieceType PieceType : ChessPieceTypes)
			{
				PieceTypes.Add(PieceType.Type);
			}

			if (LastWave.IsValid() && PieceTypes.Num() > 1)
			{
				// Make an array of the 3 pieces that werent the last wave
				PieceTypes.Remove(LastWave);				

				// Shuffle and take the first
				PieceTypes.Shuffle();
				QueuedWaves.Add(PieceTypes[0]);
				PieceTypes.RemoveAt(0);

				// Add back the last wave and shuffle
				PieceTypes.Add(LastWave);
				PieceTypes.Shuffle();			
			}
			QueuedWaves.Append(PieceTypes);

			SpawnSelection.Type = QueuedWaves[0];
			SpawnSelection.SpawnType = GetSpawnTypeFromType(SpawnSelection.Type);
			QueuedWaves.RemoveAt(0);
		}

		LastWave = SpawnSelection.Type;

		return SpawnSelection;
	}

	void SpawnFromData(TArray<FCastleChessPieceSpawnData> Data)
	{
		TArray<FCastleChessPieceSpawnData> FinalData;

		for (int Index = 0; Index < Data.Num(); Index++)
		{
			if (!PieceComp.Chessboard.IsGridPositionValid(Data[Index].Coordinate))
				continue;

			if (PieceComp.Chessboard.IsSquareOccupied(Data[Index].Coordinate))
				continue;
			
			FinalData.Add(Data[Index]);
		}

		TArray<ACastleEnemy> FinalSpawnedPieces;
		NetSpawnFromData(FinalData, FinalSpawnedPieces);
	}

	UFUNCTION(NetFunction)
	void NetSpawnFromData(TArray<FCastleChessPieceSpawnData> Data, TArray<ACastleEnemy>& OutSpawnedPieces)
	{
		TotalNumberOfWaves++;
		
		TArray<ACastleEnemy> SpawnedPieces;
		for (int Index = 0; Index < Data.Num(); Index++)
		{
			SpawnPiece(Data[Index], Index, SpawnedPieces);
		}

		OutSpawnedPieces = SpawnedPieces;

		if(Data.Num() > 0)
			BossManager.BossAudioManager.PrepareNewSpawnAudio(GetSpawnTypeFromType(Data[0].Type), OutSpawnedPieces);
	}

	void SpawnPiece(FCastleChessPieceSpawnData Data, int Index, TArray<ACastleEnemy>& SpawnedPieces)
	{
		FVector TargetLocation = PieceComp.Chessboard.GetSquareCenter(Data.Coordinate);
		FVector SpawnLocation = TargetLocation + FVector(0.f, 0.f, 1000.f);

		ACastleEnemy SpawnedPiece = Cast<ACastleEnemy>(SpawnActor(Data.Type, SpawnLocation, Data.Rotation, NAME_None, true, Owner.Level));
		SpawnedPiece.MakeNetworked(this, Index, TotalNumberOfWaves);
		FinishSpawningActor(SpawnedPiece);
		
		UChessPieceAbilityComponent PieceAbilityComp = UChessPieceAbilityComponent::Get(SpawnedPiece);
		float InitialHeight = PieceAbilityComp.SummonHeight;
		if (PieceAbilityComp.VerticalCurve != nullptr)
			InitialHeight = PieceAbilityComp.VerticalCurve.GetFloatValue(0.f);
		FVector InitialLocation = TargetLocation + FVector(0.f, 0.f, InitialHeight);

		SpawnedPiece.SetActorLocation(InitialLocation);
		PieceAbilityComp.Setup(PieceComp.Chessboard, Data.Coordinate, InitialLocation, TargetLocation);

		SpawnedPieces.Add(SpawnedPiece);
		//Chessboard.AllPieces.AddUnique(Cast<ACastleEnemy>(Owner));
	}

	void SpawnPawns()
	{
		TSubclassOf<ACastleEnemy> Type = GetPieceTypeFromEnum(ECastleChessSpawnType::Pawn);

		int AmountToSpawn = 4;
		if (QueueRefreshCount == 0)
			AmountToSpawn = 3;

		// Get the player coordinates;
		TArray<FVector2D> PlayerCoordinates;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector2D Coordinate = PieceComp.Chessboard.GetClosestGridPosition(Player.ActorLocation);
			PlayerCoordinates.Add(Coordinate);
		}

		TArray<FCastleChessPieceSpawnData> PieceSpawnData;
		int TileDistanceFromPlayer = 2;
		for (int Index = 0; Index < AmountToSpawn; Index++)
		{
			int MaximumTests = 16;
			for (int TestIndex = 0; TestIndex < MaximumTests; TestIndex++)
			{
				int TargetPlayer = FMath::RandRange(0, 1);				
				FVector2D SpawnCoordinate = PlayerCoordinates[TargetPlayer];

				SpawnCoordinate.X += FMath::RandRange(-TileDistanceFromPlayer, TileDistanceFromPlayer);
				SpawnCoordinate.Y += FMath::RandRange(-TileDistanceFromPlayer, TileDistanceFromPlayer);

				SpawnCoordinate.X = FMath::Clamp(SpawnCoordinate.X, 1, 6);
				SpawnCoordinate.Y = FMath::Clamp(SpawnCoordinate.Y, 1, 6);

				if (PieceComp.Chessboard.IsGridPositionValid(SpawnCoordinate) && !PieceComp.Chessboard.IsSquareOccupied(SpawnCoordinate))
				{
					FCastleChessPieceSpawnData SpawnData;
					SpawnData.Type = Type;
					SpawnData.Coordinate = SpawnCoordinate;
					SpawnData.Rotation = FRotator::ZeroRotator;

					PieceSpawnData.Add(SpawnData);
					break;
				}
			}
		}

		SpawnFromData(PieceSpawnData);
	}

	void SpawnBishops()
	{
		TSubclassOf<ACastleEnemy> Type = GetPieceTypeFromEnum(ECastleChessSpawnType::Bishop);

		int AmountToSpawn = 2;
		if (QueueRefreshCount <= 0)
			AmountToSpawn = 1;

		// Get the player coordinates;
		// TArray<FVector2D> PlayerCoordinates;
		// for (AHazePlayerCharacter Player : Game::Players)
		// {
		// 	FVector2D Coordinate = PieceComp.Chessboard.GetClosestGridPosition(Player.ActorLocation);
		// 	PlayerCoordinates.Add(Coordinate);
		// }

		TArray<FCastleChessPieceSpawnData> PieceSpawnData;
		for (int Index = 0; Index < AmountToSpawn; Index++)
		{
			int MaximumTests = 16;
			for (int TestIndex = 0; TestIndex < MaximumTests; TestIndex++)
			{
				FVector2D SpawnCoordinate = PieceComp.RandomCoordinate;
				if (PieceComp.Chessboard.IsGridPositionValid(SpawnCoordinate) && !PieceComp.Chessboard.IsSquareOccupied(SpawnCoordinate))
				{
					FCastleChessPieceSpawnData SpawnData;
					SpawnData.Type = Type;
					SpawnData.Coordinate = SpawnCoordinate;
					SpawnData.Rotation = FRotator::ZeroRotator;

					PieceSpawnData.Add(SpawnData);
					break;
				}
			}
		}

		SpawnFromData(PieceSpawnData);
	}

	void SpawnRooks()
	{
		TSubclassOf<ACastleEnemy> Type = GetPieceTypeFromEnum(ECastleChessSpawnType::Rook);

		int AmountToSpawn = 1;
		if (QueueRefreshCount <= 0)
			AmountToSpawn = 1;

		if (KingChessPieceComp == nullptr)
			KingChessPieceComp = UChessPieceComponent::Get(BossManager.King);
		if (QueenChessPieceComp == nullptr)
			QueenChessPieceComp = UChessPieceComponent::Get(BossManager.Queen);

		/*
			Each rook should overlap with the player in 1 axis
		*/

		// Get the player coordinates;
		TPerPlayer<FVector2D> PlayerCoordinates;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			FVector2D Coordinate = PieceComp.Chessboard.GetClosestGridPosition(Player.ActorLocation);
			PlayerCoordinates[Player] = Coordinate;
		}
		
		FVector2D QueenCoordinate = PieceComp.Chessboard.GetClosestGridPosition(Owner.ActorLocation);
		FVector2D QueenDestinationCoordinate = QueenChessPieceComp.CurrentDestination;
		FVector2D KingCoordinate = PieceComp.Chessboard.GetClosestGridPosition(BossManager.King.ActorLocation);
		FVector2D KingDestinationCoordinate = KingChessPieceComp.CurrentDestination;

		TArray<FCastleChessPieceSpawnData> PieceSpawnData;
		for (int Index = 0; Index < AmountToSpawn; Index++)
		{
			int MaximumTests = 36;
			for (int TestIndex = 0; TestIndex < MaximumTests; TestIndex++)
			{
				FVector2D RandomCoordinate = PieceComp.RandomCoordinate;

				if (FMath::IsNearlyEqual(RandomCoordinate.X, QueenCoordinate.X, 0.5f))
					continue;
				if (FMath::IsNearlyEqual(RandomCoordinate.X, QueenDestinationCoordinate.X, 0.5f))
					continue;
				if (FMath::IsNearlyEqual(RandomCoordinate.X, KingCoordinate.X, 0.5f))
					continue;
				if (FMath::IsNearlyEqual(RandomCoordinate.X, KingDestinationCoordinate.X, 0.5f))
					continue;

				if (FMath::IsNearlyEqual(RandomCoordinate.Y, QueenCoordinate.Y, 0.5f))
					continue;
				if (FMath::IsNearlyEqual(RandomCoordinate.Y, QueenDestinationCoordinate.Y, 0.5f))
					continue;
				if (FMath::IsNearlyEqual(RandomCoordinate.Y, KingCoordinate.Y, 0.5f))
					continue;
				if (FMath::IsNearlyEqual(RandomCoordinate.Y, KingDestinationCoordinate.Y, 0.5f))
					continue;

				// Don't care about it lining up to a player if you have done a lot of attempts
				if (TestIndex < (MaximumTests * 0.7f))
				{
					// If one axis isn't over at least one player
					if (!FMath::IsNearlyEqual(RandomCoordinate.X, PlayerCoordinates[0].X, 0.5f) &&
						!FMath::IsNearlyEqual(RandomCoordinate.X, PlayerCoordinates[1].X, 0.5f) &&
						!FMath::IsNearlyEqual(RandomCoordinate.Y, PlayerCoordinates[0].Y, 0.5f) &&
						!FMath::IsNearlyEqual(RandomCoordinate.Y, PlayerCoordinates[1].Y, 0.5f))
					continue;
				}

				if (!PieceComp.Chessboard.IsGridPositionValid(RandomCoordinate))
					continue;

				if (PieceComp.Chessboard.IsSquareOccupied(RandomCoordinate))
					continue;		

				FCastleChessPieceSpawnData SpawnData;
				SpawnData.Type = Type;
				SpawnData.Coordinate = RandomCoordinate;
				SpawnData.Rotation = FRotator::ZeroRotator;

				PieceSpawnData.Add(SpawnData);
				break;				
			}
		}

		SpawnFromData(PieceSpawnData);
	}

	void SpawnKnights()
	{
		TSubclassOf<ACastleEnemy> Type = GetPieceTypeFromEnum(ECastleChessSpawnType::Knight);

		TArray<FVector2D> Coordinates;
		FRotator Rotation;

		int Selection = FMath::RandRange(0, 3);
		switch (Selection)
		{
			case 0:
			{
				Rotation = FRotator(0.f, 0.f, 0.f);
				
				Coordinates.Add(FVector2D(0.f, 0.f));
				Coordinates.Add(FVector2D(0.f, 1.f));
				Coordinates.Add(FVector2D(0.f, 2.f));
				Coordinates.Add(FVector2D(0.f, 3.f));
				Coordinates.Add(FVector2D(0.f, 4.f));
				Coordinates.Add(FVector2D(0.f, 5.f));
				Coordinates.Add(FVector2D(0.f, 6.f));
				Coordinates.Add(FVector2D(0.f, 7.f));
			}
			break;
			case 1:
			{
				Rotation = FRotator(0.f, 90.f, 0.f);
				
				Coordinates.Add(FVector2D(0.f, 0.f));
				Coordinates.Add(FVector2D(1.f, 0.f));
				Coordinates.Add(FVector2D(2.f, 0.f));
				Coordinates.Add(FVector2D(3.f, 0.f));
				Coordinates.Add(FVector2D(4.f, 0.f));
				Coordinates.Add(FVector2D(5.f, 0.f));
				Coordinates.Add(FVector2D(6.f, 0.f));
				Coordinates.Add(FVector2D(7.f, 0.f));
			}
			break;
			case 2:
			{
				Rotation = FRotator(0.f, 180.f, 0.f);

				Coordinates.Add(FVector2D(7.f, 0.f));
				Coordinates.Add(FVector2D(7.f, 1.f));
				Coordinates.Add(FVector2D(7.f, 2.f));
				Coordinates.Add(FVector2D(7.f, 3.f));
				Coordinates.Add(FVector2D(7.f, 4.f));
				Coordinates.Add(FVector2D(7.f, 5.f));
				Coordinates.Add(FVector2D(7.f, 6.f));
				Coordinates.Add(FVector2D(7.f, 7.f));

			}
			break;
			case 3:
			{
				Rotation = FRotator(0.f, 270.f, 0.f);
				
				Coordinates.Add(FVector2D(0.f, 7.f));
				Coordinates.Add(FVector2D(1.f, 7.f));
				Coordinates.Add(FVector2D(2.f, 7.f));
				Coordinates.Add(FVector2D(3.f, 7.f));
				Coordinates.Add(FVector2D(4.f, 7.f));
				Coordinates.Add(FVector2D(5.f, 7.f));
				Coordinates.Add(FVector2D(6.f, 7.f));
				Coordinates.Add(FVector2D(7.f, 7.f));
			}
			break;
		}

		if (QueueRefreshCount == 0)
		{
			Coordinates.RemoveAt(7);
			Coordinates.RemoveAt(1);
		}		
		Coordinates.RemoveAt(FMath::RandRange(0, Coordinates.Num() - 1));

		TArray<FCastleChessPieceSpawnData> PieceSpawnData;
		for (FVector2D Coordinate : Coordinates)
		{
			FCastleChessPieceSpawnData SpawnData;
			SpawnData.Type = Type;
			SpawnData.Coordinate = Coordinate;
			SpawnData.Rotation = Rotation;

			PieceSpawnData.Add(SpawnData);
		}

		SpawnFromData(PieceSpawnData);
	}

	ECastleChessSpawnType GetSpawnTypeFromType(TSubclassOf<ACastleEnemy> Type)
	{
		for (FCastleChessPieceType PieceType : ChessPieceTypes)
		{
			if (PieceType.Type.Get() == Type.Get())
				return PieceType.SpawnType;
		}
		return ECastleChessSpawnType::Pawn;
	}

	TSubclassOf<ACastleEnemy> GetPieceTypeFromEnum(ECastleChessSpawnType Type)
	{
		for (FCastleChessPieceType PieceType : ChessPieceTypes)
		{
			if (PieceType.SpawnType == Type)
				return PieceType.Type;
		}
		return TSubclassOf<ACastleEnemy>();
	}

	// UFUNCTION()
	// void OnQueenTakeDamage(ACastleEnemy Enemy, FCastleEnemyDamageEvent Event)
	// {
	// 	DamageSinceSpawn += Event.DamageDealt;
	// }
}

struct FCastleChessSpawnSelection
{
	UPROPERTY()
	TSubclassOf<ACastleEnemy> PieceType;

	UPROPERTY()
	TArray<FVector2D> Coordinates;

	UPROPERTY()
	FRotator Rotation;
}
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleChessBossAbilitiesComponent;

class UCastleEnemyQueenSpawnChessPiecesCapability : UHazeCapability
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 101;

	ACastleEnemy OwningBoss;
	UChessPieceComponent PieceComp;
	UCastleChessBossAbilitiesComponent AbilitiesComp;

	UPROPERTY()
	const float Cooldown = 16.f;

	const int MaximumActiveSpawns = 3;

	bool bSpawnCompleted = false;	

	UPROPERTY()
	TArray<FChessPieceSpawnAmount> UnitsToSpawn;
	//TArray<FChessPieceGroup> SpawnedChessPieceGroups;
	TMap<TSubclassOf<ACastleEnemy>, int> SpawnedUnits;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningBoss = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		AbilitiesComp = UCastleChessBossAbilitiesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PieceComp.State != EChessPieceState::Fighting)
        	return EHazeNetworkActivation::DontActivate;

		if (PieceComp.bIsMoving)
			return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < Cooldown)
			return EHazeNetworkActivation::DontActivate;

		if (AbilitiesComp.CooldownBetweenAbilitiesCurrent > 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (SpawnedUnits.Num()  >= MaximumActiveSpawns)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bSpawnCompleted)		
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{


	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"ChessboardMovement", this);

		bSpawnCompleted = false;

		TSubclassOf<ACastleEnemy> ClassToSpawn = GetTypeToSpawn();
		if (ClassToSpawn.IsValid())
			SpawnChessPiece(ClassToSpawn);

		AbilitiesComp.AbilityActivated();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"ChessboardMovement", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			

	}

	TSubclassOf<ACastleEnemy> GetTypeToSpawn()
	{
		TArray<TSubclassOf<ACastleEnemy>> PotentialClasses;
		for (int Index = 0, Count = UnitsToSpawn.Num(); Index < Count; ++Index)
		{
			int UnitCount = 0;
			bool bFound = SpawnedUnits.Find(UnitsToSpawn[Index].ChessPiece, UnitCount);

			if (!bFound && UnitCount <= 0)			
				PotentialClasses.AddUnique(UnitsToSpawn[Index].ChessPiece);
		}

		PotentialClasses.Shuffle();

		return PotentialClasses[0];
	}

	void SpawnChessPiece(TSubclassOf<ACastleEnemy> Type)
	{
		FChessPieceSpawnAmount SpawnAmount;
		for (int Index = 0, Count = UnitsToSpawn.Num(); Index < Count; ++Index)
		{
			if (UnitsToSpawn[Index].ChessPiece.Get() == Type)
			{
				SpawnAmount = UnitsToSpawn[Index];
				break;
			}
		}

		int SpawnedCount = 0;
		for (int Index = 0, Count = SpawnAmount.AmountToSpawn; Index < Count; ++Index)
		{
			int TestAmount = 5;
			for (int TestIndex = 0; TestIndex < TestAmount; ++TestIndex)
			{
				FVector2D GridLocation = SpawnAmount.GridLocation;

				if (SpawnAmount.bRandomizeRow)
				{
					float RandomRow = FMath::RandRange(0, FMath::FloorToInt(PieceComp.Chessboard.GridSize.Y - 1));
					GridLocation.Y = RandomRow;
				}

				if (SpawnAmount.bRandomizeColumn)
				{
					float RandomColumn = FMath::RandRange(0, FMath::FloorToInt(PieceComp.Chessboard.GridSize.X - 1));
					GridLocation.X = RandomColumn;
				}

				if (!PieceComp.Chessboard.IsSquareOccupied(GridLocation, Owner) && PieceComp.Chessboard.IsGridPositionValid(GridLocation))
				{
					ACastleEnemy SpawnedCastleEnemy = NetSpawnChessPiece(SpawnAmount.ChessPiece, GridLocation);
					SpawnedCastleEnemy.bUnhittable = false;
					SpawnedCastleEnemy.OnKilled.AddUFunction(this, n"OnCastleEnemyKilled");
					SpawnedCount += 1;
					break;
				}
				else if (!SpawnAmount.bRandomizeColumn || SpawnAmount.bRandomizeRow)
				{
					// break if its not random, no point trying to spawn in a loc that works
					break;
				}		
			}
		}
		if (SpawnedCount > 0)
			SpawnedUnits.Add(Type, SpawnedCount);		

		bSpawnCompleted = true;
	}

	UFUNCTION()
	void OnCastleEnemyKilled(ACastleEnemy Enemy, bool bKilledByDamage)
	{
		TSubclassOf<ACastleEnemy> Type = Enemy.Class;
		SpawnedUnits[Type] -= 1;

		if (SpawnedUnits[Type] == 0)
			SpawnedUnits.Remove(Type);

		// for (int Index = 0; Index < SpawnedChessPieceGroups.Num() - 1; Index++)
		// {
		// 	FChessPieceGroup ChessPieceGroup = SpawnedChessPieceGroups[Index];

		// 	for (ACastleEnemy CastleEnemy : ChessPieceGroup.CastleEnemies)
		// 	{
		// 		if (CastleEnemy == Enemy)
		// 		{
		// 			ChessPieceGroup.CastleEnemies.Remove(Enemy);

		// 			if (ChessPieceGroup.CastleEnemies.Num() == 0)
		// 				SpawnedChessPieceGroups.RemoveAt(Index);					

		// 			return;
		// 		}
		// 	}
		// }
	}

	UFUNCTION(NetFunction)
	ACastleEnemy NetSpawnChessPiece(TSubclassOf<ACastleEnemy> ChessPiece, FVector2D GridLocation)
	{
		return PieceComp.Chessboard.SpawnChessPiece(ChessPiece, GridLocation);
	}
}

struct FChessPieceGroup
{
	UPROPERTY()
	TArray<ACastleEnemy> CastleEnemies;
}

struct FChessPieceSpawnAmount
{
	UPROPERTY()	
	TSubclassOf<ACastleEnemy> ChessPiece;

	UPROPERTY()	
	FVector2D GridLocation;

	UPROPERTY()	
	bool bRandomizeRow;

	UPROPERTY()	
	bool bRandomizeColumn;

	UPROPERTY()	
	int AmountToSpawn;
}
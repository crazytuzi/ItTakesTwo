import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.CastleEnemyBossAbilitiesComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

class UCastleEnemyChessBossAbilityRetreatHeal : UChessBossAbility
{
	default CapabilityTags.Add(n"BossAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	default BossAbility.Priority = EBossAbilityPriority::High;

	AChessboard Chessboard;

	bool bActivated = false;
	bool bFinished = false;

	UPROPERTY()
	FHazeTimeLike RetreatTimelike;
	default RetreatTimelike.Duration = 1.5f;

	const float RetreatJumpHeight = 1000.f;

	FVector StartRetreatLocation;
	FVector TargetRetreatLocation;
	FVector2D RetreatCoordinate;

	TArray<FVector2D> RetreatLocations;
	default RetreatLocations.Add(FVector2D(1.f, 1.f));
	default RetreatLocations.Add(FVector2D(1.f, 6.f));
	default RetreatLocations.Add(FVector2D(6.f, 1.f));
	default RetreatLocations.Add(FVector2D(6.f, 6.f));

	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		RetreatTimelike.BindUpdate(this, n"OnStartRetreatUpdate");
		RetreatTimelike.BindFinished(this, n"OnStartRetreatFinished");
	}

	UFUNCTION()
	bool ShouldActivateAbility() const
	{
		if (bActivated)
			false;

		return true;
	}

	UFUNCTION()
	bool ShouldDeactivateAbility() const
	{
		if (bFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		Chessboard = PieceComp.Chessboard;

		bActivated = true;

		// FVector2D GridSize = Chessboard.GridSize;
		// FVector2D TopLeftTileCoordinate = FVector2D(GridSize.X - 1.f, GridSize.Y - 1.f);
		// FVector2D TopRightTileCoordinate = FVector2D(0.f, GridSize.Y - 1.f);

		// StartSlamLocation = Owner.ActorLocation;
		// EndSlamLocation = (Chessboard.GetSquareCenter(TopLeftTileCoordinate) + Chessboard.GetSquareCenter(TopRightTileCoordinate)) / 2.f;

	}

	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AbilitiesComp.AbilityFinished();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			

	}

	UFUNCTION()
	void OnStartRetreatUpdate(float Value)
	{
		FVector NewLocation = FMath::Lerp(StartRetreatLocation, TargetRetreatLocation, Value);
		NewLocation.Z += RetreatJumpHeight * FMath::Sin(Value * PI);	

		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnStartRetreatFinished()
	{
		Owner.SetActorLocation(TargetRetreatLocation);
	}

	void SetRetreatLolcation()
	{
		TPerPlayer<FVector2D> PlayerGridPositions;

		FVector2D MayGridLocation;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FVector2D PlayerGridPosition;
			PieceComp.Chessboard.GetGridPosition(Player.ActorLocation, PlayerGridPosition);
			PlayerGridPositions[Player] = PlayerGridPosition;
		}

		for (FVector2D PossibleRetreatLocation : RetreatLocations)
		{
			for (auto PlayerLocation : PlayerGridPositions)
			{
				float X = FMath::Abs(PossibleRetreatLocation.X - PlayerLocation.X);
				float Y = FMath::Abs(PossibleRetreatLocation.Y - PlayerLocation.Y);

				//if (X > PieceComp.Chessboard.)
			//if (PossibleRetreatLocation.X - )

			}
		}
	}
}


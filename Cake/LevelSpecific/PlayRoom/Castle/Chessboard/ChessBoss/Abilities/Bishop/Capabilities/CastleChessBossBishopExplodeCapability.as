import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.Bishop.CastleChessBossBishopExplosion;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.Bishop.CastleChessBossBishopExplosionFire;

class UCastleChessBossBishopExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ChessPiece");
	default CapabilityTags.Add(n"ChessPieceAction");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	UPROPERTY()
	TSubclassOf<ACastleChessBossBishopExplosion> ExplosionType;

	UPROPERTY()
	TSubclassOf<ACastleChessBossBishopExplosionFire> ExplosionFireType;

	ACastleEnemy Piece;
	UChessPieceComponent PieceComp;
	UChessPieceAbilityComponent PieceAbilityComp;
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UAkAudioEvent AudioEvent;

	TArray<FTileSquareTimer> TileSpawnTimers;
	TArray<FTileSquareTimer> TileEffectTimers;

	const float FireDuration = 6.f;
	const float TimePerTile = 0.3f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Piece = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		PieceAbilityComp = UChessPieceAbilityComponent::GetOrCreate(Owner);
		HazeAkComp = UHazeAkComponent::Create(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Piece.bKilled)
        	return EHazeNetworkActivation::DontActivate;

		if (PieceAbilityComp.State != ECastleChessBossPieceState::TelegraphComplete)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (TileSpawnTimers.Num() > 0)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (TileEffectTimers.Num() > 0)
			return EHazeNetworkDeactivation::DontDeactivate;			

		// if (ActiveDuration >= 5.6f)
		// 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PieceAbilityComp.State = ECastleChessBossPieceState::Action;

		if (AudioEvent != nullptr)
			HazeAkComp.HazePostEvent(AudioEvent, EventTag = n"BishopExplode");

		// Spawn diagonal explosion effect
		if (ExplosionType.IsValid())
		{
			float DiagonalTileDistance = FMath::Sqrt(FMath::Square(PieceComp.Chessboard.SquareSize.X) + FMath::Square(PieceComp.Chessboard.SquareSize.Y));
			float MoveSpeed = DiagonalTileDistance / TimePerTile;

			ACastleChessBossBishopExplosion Explosion = Cast<ACastleChessBossBishopExplosion>(SpawnActor(ExplosionType, Owner.ActorLocation, bDeferredSpawn = true));
			Explosion.Chessboard = PieceComp.Chessboard;
			Explosion.MoveSpeed = MoveSpeed;
			Explosion.Lifetime = 10.f;
			FinishSpawningActor(Explosion);
		}

		// Calculate the spawn locations and timers
		FVector2D OriginTileCooridinate = PieceComp.Chessboard.GetClosestGridPosition(Owner.ActorLocation);
		AddTileAndCalculateDuration(TileSpawnTimers, OriginTileCooridinate, OriginTileCooridinate);		
		for (int Index = -8; Index <= 7; Index++)
		{
			FVector2D Coordinate = OriginTileCooridinate + Index;
			if (PieceComp.Chessboard.IsGridPositionValid(Coordinate) && Coordinate != OriginTileCooridinate)
				AddTileAndCalculateDuration(TileSpawnTimers, OriginTileCooridinate, Coordinate);

			FVector2D Coordinate2 = FVector2D(OriginTileCooridinate.X + Index, OriginTileCooridinate.Y - Index);
			if (PieceComp.Chessboard.IsGridPositionValid(Coordinate2) && Coordinate2 != OriginTileCooridinate)
				AddTileAndCalculateDuration(TileSpawnTimers, OriginTileCooridinate, Coordinate2);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PieceAbilityComp.State = ECastleChessBossPieceState::ActionComplete;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if (Piece.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"CastleEnemyPiece";

			Piece.Mesh.RequestLocomotion(Request);
		}

		UpdateAndEffectTiles(DeltaTime);
	}

	void AddTileAndCalculateDuration(TArray<FTileSquareTimer>& TileTimers, FVector2D OriginTileCoordinate, FVector2D TileCoordinate)
	{
		FVector2D VectorDelta = OriginTileCoordinate - TileCoordinate;
		float Delta = VectorDelta.X;
		
		float Duration = FMath::Abs(Delta) * TimePerTile;

		TileSpawnTimers.Add(FTileSquareTimer(TileCoordinate, Duration));
	}

	void UpdateAndEffectTiles(float DeltaTime)
	{
		for (int Index = TileSpawnTimers.Num() - 1; Index >= 0; Index--)
		{
			TileSpawnTimers[Index].Duration -= DeltaTime;

			if (TileSpawnTimers[Index].Duration <= 0.f)
			{
				if (ExplosionType.IsValid())
				{
					FVector Location = PieceComp.Chessboard.GetSquareCenter(TileSpawnTimers[Index].TileCoordinate);
					AChessTile Tile = PieceComp.Chessboard.GetTileActor(TileSpawnTimers[Index].TileCoordinate);

					ACastleChessBossBishopExplosionFire ExplosionFire = Cast<ACastleChessBossBishopExplosionFire>(SpawnActor(ExplosionFireType, Location, bDeferredSpawn = true));
					ExplosionFire.Setup(PieceComp.Chessboard, PieceAbilityComp, TileSpawnTimers[Index].TileCoordinate, 0.f, FireDuration);
					ExplosionFire.AttachToComponent(Tile.TileMesh);
					FinishSpawningActor(ExplosionFire);
				}

				//System::DrawDebugPlane(FPlane(Location, FVector::UpVector), Location, 50.f, FLinearColor::Red, FireDuration);

				TileSpawnTimers.RemoveAt(Index);
			}
		}	
	}
}
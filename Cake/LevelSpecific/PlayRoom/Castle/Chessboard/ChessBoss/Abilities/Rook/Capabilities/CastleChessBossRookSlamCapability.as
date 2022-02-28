import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.Rook.Capabilities.CastleChessBossRookSlam;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.Rook.CastleChessBossRookComponent;

class UCastleChessBossRookSlamCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ChessPiece");
	default CapabilityTags.Add(n"ChessPieceAction");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	ACastleEnemy Piece;
	UChessPieceComponent PieceComp;
	UCastleChessBossRookComponent RookComp;
	UChessPieceAbilityComponent PieceAbilityComp;
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UAkAudioEvent AudioEvent;

	UPROPERTY()
	TSubclassOf<ACastleChessBossRookSlam> SlamType;
	
	const float LoweredTileDuration = 6.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Piece = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		RookComp = UCastleChessBossRookComponent::GetOrCreate(Owner);
		PieceAbilityComp = UChessPieceAbilityComponent::GetOrCreate(Owner);
		HazeAkComp = UHazeAkComponent::Create(Owner);

		// Update which tiles will be lowered when the rook is created (to also mark the tiles as occupied)
		FVector2D OriginTileCooridinate = PieceComp.Chessboard.GetClosestGridPosition(Owner.ActorLocation);

		PieceComp.Chessboard.ActorOccupiesSquare(OriginTileCooridinate, Owner);
		AddTileToLowerAndCalculateDuration(RookComp.TilesToLower, OriginTileCooridinate, OriginTileCooridinate);
		for (int Index = 0; Index <= 7; Index++)
		{	
			PieceComp.Chessboard.ActorOccupiesSquare(FVector2D(OriginTileCooridinate.X, Index), Owner);
			if (OriginTileCooridinate != FVector2D(OriginTileCooridinate.X, Index))
				AddTileToLowerAndCalculateDuration(RookComp.TilesToLower, OriginTileCooridinate, FVector2D(OriginTileCooridinate.X, Index));

			PieceComp.Chessboard.ActorOccupiesSquare(FVector2D(Index, OriginTileCooridinate.Y), Owner);
			if (OriginTileCooridinate != FVector2D(Index, OriginTileCooridinate.Y))		
				AddTileToLowerAndCalculateDuration(RookComp.TilesToLower, OriginTileCooridinate, FVector2D(Index, OriginTileCooridinate.Y));
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PieceAbilityComp.State != ECastleChessBossPieceState::TelegraphComplete)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration >= 0.6f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Shouldn't run if the chessboard is disabled
		if (PieceAbilityComp.Chessboard.bChessboardDisabled)
			return;

		PieceAbilityComp.State = ECastleChessBossPieceState::Action;
		
		if (AudioEvent != nullptr)
			HazeAkComp.HazePostEvent(AudioEvent, EventTag = n"RookSlam");

		if (PieceAbilityComp.ActionStartEffect != nullptr)
			Niagara::SpawnSystemAtLocation(PieceAbilityComp.ActionStartEffect, Owner.ActorLocation, Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Shouldn't run if the chessboard is disabled
		if (PieceAbilityComp.Chessboard.bChessboardDisabled)
			return;
			
		if (SlamType.IsValid())
		{
			ACastleChessBossRookSlam Slam = Cast<ACastleChessBossRookSlam>(SpawnActor(SlamType, Owner.ActorLocation, bDeferredSpawn = true));
			Slam.Setup(PieceComp.Chessboard, Piece, RookComp.TilesToLower, LoweredTileDuration);
			FinishSpawningActor(Slam);
		}
		
		if (PieceAbilityComp.ActionEndEffect != nullptr)
			Niagara::SpawnSystemAtLocation(PieceAbilityComp.ActionEndEffect, Owner.ActorLocation, Owner.ActorRotation);

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
	}

	void AddTileToLowerAndCalculateDuration(TArray<FTileSquareTimer>& TilesToLower, FVector2D OriginTileCoordinate, FVector2D TileCoordinate)
	{
		AChessTile Tile = PieceComp.Chessboard.GetTileActor(TileCoordinate);
		FVector2D Direction = (OriginTileCoordinate - TileCoordinate);

		// Show lines if only one direction is visible
		// remove both lines if they cross over
		if (Direction.X != 0 && !Tile.bShowVerticalLights)
			Tile.bShowHorizontalLights = true;
		else if (Direction.Y != 0 && !Tile.bShowHorizontalLights)
			Tile.bShowVerticalLights = true;
		else
		{
			Tile.bShowHorizontalLights = false;
			Tile.bShowVerticalLights = false;
		}
		

		FVector2D VectorDelta = OriginTileCoordinate - TileCoordinate;
		float Delta = VectorDelta.X + VectorDelta.Y;
		
		float Duration = FMath::Abs(Delta) * 0.24f;

		TilesToLower.Add(FTileSquareTimer(TileCoordinate, Duration));
	}
}
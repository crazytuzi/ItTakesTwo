import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.ChessPieceAbilityComponent;
class UCastleChessBossPawnExplodeCapability : UHazeCapability
{
	default CapabilityTags.Add(n"ChessPiece");
	default CapabilityTags.Add(n"ChessPieceAction");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	ACastleEnemy Piece;
	UChessPieceComponent PieceComp;
	UChessPieceAbilityComponent PieceAbilityComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Piece = Cast<ACastleEnemy>(Owner);
		PieceComp = UChessPieceComponent::GetOrCreate(Owner);
		PieceAbilityComp = UChessPieceAbilityComponent::GetOrCreate(Owner);
	}

	/*
		- Activate will be the explosion where damage is dealt
		- Duration is just to let the anim to play out before death
	*/

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Piece.bDead)
        	return EHazeNetworkActivation::DontActivate;

		if (PieceAbilityComp.State != ECastleChessBossPieceState::TelegraphComplete)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration >= 0.6f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (Piece.bDead)
        	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Shouldn't explode if the chessboard is disabled
		if (PieceAbilityComp.Chessboard.bChessboardDisabled)
			return;

		PieceAbilityComp.State = ECastleChessBossPieceState::Action;

		FVector2D OriginTileCooridinate = PieceComp.Chessboard.GetClosestGridPosition(Owner.ActorLocation);
		TArray<FVector2D> AffectedTiles = PieceComp.Chessboard.GetSurroundingTileLocations(OriginTileCooridinate, true);

		// Spawn effect
		if (PieceAbilityComp.ActionStartEffect != nullptr)
			Niagara::SpawnSystemAtLocation(PieceAbilityComp.ActionStartEffect, Owner.ActorLocation, Owner.ActorRotation);

		for (FVector2D Coordinate : AffectedTiles)
		{
			if (!PieceComp.Chessboard.IsGridPositionValid(Coordinate))
				continue;
				
			// Spawn tile effect
			FVector Location = PieceComp.Chessboard.GetTileActor(Coordinate).TileMesh.WorldLocation;

			if (PieceAbilityComp.ActionTileEffect != nullptr)
				Niagara::SpawnSystemAtLocation(PieceAbilityComp.ActionTileEffect, Location, Owner.ActorRotation);

			// Damage players
			for (AHazePlayerCharacter Player : PieceComp.Chessboard.GetPlayersOnSquare(Coordinate))
			{
				FVector ToPlayer = Player.ActorCenterLocation - Owner.ActorLocation;

				FCastlePlayerDamageEvent Damage;
				Damage.DamageSource = Owner;
				Damage.DamageDealt = PieceAbilityComp.Damage;
				//Damage.DamageEffect = PieceAbilityComp.DamageEffect;
				Damage.DamageLocation = Player.ActorCenterLocation;
				Damage.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);

				Player.DamageCastlePlayer(Damage);
			}			
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
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
}
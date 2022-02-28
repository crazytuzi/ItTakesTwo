import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.CastleChessTelegraph;
import Rice.Math.MathStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.ChessBossAbility;

UCLASS(Abstract)
class UCastleEnemyKingSlamAbility : UChessBossAbility
{
	default CapabilityTags.Add(n"QueenAbility");
    default CapabilityTags.Add(n"CastleEnemyAI");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	UPROPERTY()
	UNiagaraSystem SlamEffect;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> SlamCameraShake;

	UPROPERTY()
	FHazeTimeLike SlamTimeLike;


	TArray<FVector2D> AffectedGridPositions;

	bool bSlamFinished = false;

	FVector StartLocation;
	float Peakheight = 400.f;

	default Cooldown = 1.8f;

	const float PostSlamWait = 0.5f;
	float PostSlamWaitCurrent = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		SlamTimeLike.BindUpdate(this, n"OnSlamUpdate");
		SlamTimeLike.BindFinished(this, n"OnSlamFinished");
	}

	bool ShouldActivateAbility() const override
	{
		if (CurrentCooldown > 0.f)
			return false;

		if (Math::GetDistanceToNearestPlayer(Owner.ActorLocation) <= 400.f)
			return true;

		return false;
	}

	bool ShouldDeactivateAbility() const override
	{
		return PostSlamWaitCurrent >= PostSlamWait;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		bSlamFinished = false;
		PostSlamWaitCurrent = 0.f;
		StartLocation = Owner.ActorLocation;

		Owner.BlockCapabilities(n"CastleEnemyMovement", this);
		Owner.BlockCapabilities(n"ChessboardMovement", this);

		SlamTimeLike.PlayFromStart();

		FVector2D GridPosition;
		PieceComp.Chessboard.GetGridPosition(Owner.ActorLocation, GridPosition);
		AffectedGridPositions = PieceComp.Chessboard.GetSurroundingTileLocations(GridPosition, true);

		for (FVector2D AffectedGridPosition : AffectedGridPositions)
		{
			if (PieceComp.Chessboard.IsGridPositionValid(AffectedGridPosition))
				PieceComp.Chessboard.GetTileActor(AffectedGridPosition).TelegraphTile();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		AbilitiesComp.AbilityFinished();
		Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
		Owner.UnblockCapabilities(n"ChessboardMovement", this);

		CurrentCooldown = Cooldown;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{			
		if (bSlamFinished)
			PostSlamWaitCurrent += DeltaTime;
	}

	UFUNCTION()
	void OnSlamUpdate(float Value)
	{	
		float PieceZ = StartLocation.Z + (Value * Peakheight);
		FVector NewLocation = StartLocation;
		NewLocation.Z = PieceZ;

		Owner.SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void OnSlamFinished()
	{
		bSlamFinished = true;
		Owner.SetActorLocation(StartLocation);

		if (SlamCameraShake.IsValid())
			Game::GetMay().PlayCameraShake(SlamCameraShake, 3.f);

		for (FVector2D AffectedGridPosition : AffectedGridPositions)
		{
			if (PieceComp.Chessboard.IsGridPositionValid(AffectedGridPosition))
			{
				TArray<AHazePlayerCharacter> PlayersOnSquare = PieceComp.Chessboard.GetPlayersOnSquare(AffectedGridPosition);
				
				for (AHazePlayerCharacter Player : PlayersOnSquare)
				{
					FVector ToPlayer = Player.ActorLocation - OwningBoss.ActorLocation;

					FCastlePlayerDamageEvent Evt;
					Evt.DamageSource = OwningBoss;
					Evt.DamageDealt = 50.f;
					Evt.DamageLocation = Player.ActorCenterLocation;
					Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
	
					Player.DamageCastlePlayer(Evt);
				}

				Niagara::SpawnSystemAtLocation(SlamEffect, PieceComp.Chessboard.GetSquareCenter(AffectedGridPosition), FRotator::ZeroRotator);
			}
		}
	}
}
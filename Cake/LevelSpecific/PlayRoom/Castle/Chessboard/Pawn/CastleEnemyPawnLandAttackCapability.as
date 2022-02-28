import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

class UCastleEnemyChessPawnLandAttackCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyAttack");

    ACastleEnemy Enemy;
	UChessPieceComponent PieceComp;

    // Minimum damage dealt to the player
    UPROPERTY()
    float MinPlayerDamageDealt = 15.f;

    // Maximum damage dealt to the player
    UPROPERTY()
    float MaxPlayerDamageDealt = 20.f;

    // The damage effect that is used on the player. Leave empty for the default.
    UPROPERTY()
    TSubclassOf<UCastleDamageEffect> DamageEffect;

	UPROPERTY()
    TSubclassOf<ACastleEnemy> SpawnedChessPiece;

	UPROPERTY()
	UNiagaraSystem LandingEffect;

	UPROPERTY()
	UNiagaraSystem PawnHealingEffect;

	bool bDidLanding = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        PieceComp = UChessPieceComponent::GetOrCreate(Owner);

		PieceComp.OnLanded.AddUFunction(this, n"OnLanded");		
    }

	UFUNCTION()
	void OnLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousGridPos, FVector2D GridPos)
	{
		bDidLanding = true;

        float Damage = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);

		TArray<FVector2D> DamagedGridPositions;

		DamagedGridPositions.Add(GridPos);

		// FVector2D Forward = GridPos + (GridPos - PreviousGridPos);
		// DamagedGridPositions.Add(Forward);

		for (FVector2D DamagedGridPosition : DamagedGridPositions)
		{
			if (!Chessboard.IsGridPositionValid(DamagedGridPosition))
				continue;

			//if (DamagedGridPosition != GridPos)
				Niagara::SpawnSystemAtLocation(LandingEffect, Chessboard.GetSquareCenter(DamagedGridPosition), FRotator::ZeroRotator);
			
			for (auto Player : Chessboard.GetPlayersOnSquare(DamagedGridPosition))
			{
				FVector ToPlayer = Player.ActorLocation - Enemy.ActorLocation;
				ToPlayer.Z = 0.f;

				FCastlePlayerDamageEvent Evt;
				Evt.DamageSource = Enemy;
				Evt.DamageDealt = Damage;
				Evt.DamageLocation = Player.ActorCenterLocation;
				Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
				Evt.DamageEffect = DamageEffect;

				Player.DamageCastlePlayer(Evt);


				// Knock back players if we hit them				
				if (!Player.HasControl())
					continue;
				if (Player.IsAnyCapabilityActive(n"KnockDown"))
					continue;


				float KnockForce = 400.f;
				FVector KnockImpulse = ToPlayer.GetSafeNormal() * KnockForce + FVector(0.f, 0.f, 200.f);
				Player.KnockdownActor(KnockImpulse);

				// if (Charger.ChargePlayerDamageForceFeedback != nullptr)
				// 	Player.PlayForceFeedback(Charger.ChargePlayerDamageForceFeedback, false, false, n"Damage");


			}
		}


		// Heal if the pawn reaches the end of the board
		// {
		// 	FVector2D MoveDelta = GridPos - PreviousGridPos;
		
		// 	if (MoveDelta.X != 0)
		// 		if (GridPos.X == 0 || GridPos.X == Chessboard.GridSize.X - 1)
		// 		{
		// 			//PieceComp.Chessboard.SpawnChessPiece(SpawnedChessPiece, GridPos);
		// 			//Owner.DestroyActor();
					
		// 			//Enemy.Kill();
		// 			Enemy.SetEnemyHealth(Enemy.MaxHealth);
		// 			Niagara::SpawnSystemAtLocation(PawnHealingEffect, Chessboard.GetSquareCenter(GridPos), FRotator::ZeroRotator);
		// 		}

		// 	if (MoveDelta.Y != 0)
		// 		if (GridPos.Y == 0 || GridPos.Y == Chessboard.GridSize.Y - 1)
		// 		{
		// 			//PieceComp.Chessboard.SpawnChessPiece(SpawnedChessPiece, GridPos);
		// 			//Owner.DestroyActor();

		// 			//Enemy.Kill();

		// 			Enemy.SetEnemyHealth(Enemy.MaxHealth);
		// 			Niagara::SpawnSystemAtLocation(PawnHealingEffect, Chessboard.GetSquareCenter(GridPos), FRotator::ZeroRotator);
		// 		}
		// }
		
	}

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (bDidLanding)
			return EHazeNetworkActivation::ActivateLocal; 
		else
			return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (bDidLanding)
			return EHazeNetworkDeactivation::DontDeactivate; 
		else
			return EHazeNetworkDeactivation::DeactivateLocal; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		bDidLanding = false;
    }
};
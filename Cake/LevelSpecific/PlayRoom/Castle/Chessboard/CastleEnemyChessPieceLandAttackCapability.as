import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessPieceComponent;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

class UCastleEnemyChessPieceLandAttackCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default CapabilityTags.Add(n"CastleEnemyAttack");

    ACastleEnemy Enemy;
	UChessPieceComponent PieceComp;

    // Minimum damage dealt to the player
    UPROPERTY()
    float MinPlayerDamageDealt = 10.f;

    // Maximum damage dealt to the player
    UPROPERTY()
    float MaxPlayerDamageDealt = 10.f;

    // The damage effect that is used on the player. Leave empty for the default.
    UPROPERTY()
    TSubclassOf<UCastleDamageEffect> DamageEffect;

	bool bDidLanding = false;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
        PieceComp = UChessPieceComponent::GetOrCreate(Owner);

		PieceComp.OnLanded.AddUFunction(this, n"OnLanded");
		PieceComp.OnTelegraphDone.AddUFunction(this, n"OnTelegraphDone");
		PieceComp.OnMoveStarted.AddUFunction(this, n"OnMoveStarted");
    }

	UFUNCTION()
	void OnMoveStarted(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousPosition, FVector2D GridPos)
	{
	}

	UFUNCTION()
	void OnTelegraphDone(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousPosition, FVector2D GridPos)
	{
	}

	UFUNCTION()
	void OnLanded(ACastleEnemy Enemy, AChessboard Chessboard, FVector2D PreviousPosition, FVector2D GridPos)
	{
		bDidLanding = true;

        float Damage = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);

		for (auto Player : Chessboard.GetPlayersOnSquare(GridPos))
		{
            FVector ToPlayer = Player.ActorLocation - Enemy.ActorLocation;

            FCastlePlayerDamageEvent Evt;
            Evt.DamageSource = Enemy;
            Evt.DamageDealt = Damage;
            Evt.DamageLocation = Player.ActorCenterLocation;
            Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
            Evt.DamageEffect = DamageEffect;

            BP_OnHitPlayer(Player, Evt);
            Player.DamageCastlePlayer(Evt);
		}
	}

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Hit Player"))
    void BP_OnHitPlayer(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent) {}

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
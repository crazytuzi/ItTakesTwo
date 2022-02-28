import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.CastleEnemyAIAttackCapabilityBase;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;

class UCastleEnemyGroundPoundAttackCapability : UCastleEnemyAIAttackCapabilityBase
{
    // Angle of the attack cone
    UPROPERTY()
    float ConeAngle = 60.f;

    // Distance the attack cone travels
    UPROPERTY()
    float ConeDistance = 600.f;

    // Minimum damage dealt to the player
    UPROPERTY()
    float MinPlayerDamageDealt = 10.f;

    // Maximum damage dealt to the player
    UPROPERTY()
    float MaxPlayerDamageDealt = 10.f;

	UPROPERTY()
	float JumpHeight = 400.f;

	UPROPERTY()
	UCurveFloat JumpCurve;

	FVector StartLocation;
	FVector TargetLocation;

	float JumpTime;

    // The damage effect that is used on the player. Leave empty for the default.
    UPROPERTY()
    TSubclassOf<UCastleDamageEffect> DamageEffect;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		StartLocation = Owner.ActorLocation;
		TargetLocation = StartLocation + FVector(0.f, 0.f, JumpHeight);
		JumpTime = 0.f;
		Owner.BlockCapabilities(n"CastleEnemyFalling", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		Owner.UnblockCapabilities(n"CastleEnemyFalling", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MoveComp.CanCalculateMovement())
		{
			float CurAlpha = JumpCurve.GetFloatValue(JumpTime);
			FVector CurLoc = FMath::Lerp(StartLocation, TargetLocation, CurAlpha);
			FVector CurDelta = CurLoc - Owner.ActorLocation;
			
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"GroundPound");
			MoveData.ApplyDelta(CurDelta);
			MoveComp.Move(MoveData);
		}

		Super::TickActive(DeltaTime);

		JumpTime += DeltaTime;
	}

    void ExecuteAttack(FAttackExecuteEvent Event) override
    {
		if (Event.bCanceled)
			return;

        UCastleEnemyAIAttackCapabilityBase::ExecuteAttack(Event);

        float Damage = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);

        for (AHazePlayerCharacter Player : Game::GetPlayers())
        {
			if (!Player.HasControl())
				continue;

            float Distance = Player.ActorLocation.Distance(Enemy.ActorLocation);
            if (Distance > ConeDistance)
                continue;
			if (Player.bHidden)
				continue;

            FVector ToPlayer = Player.ActorLocation - Enemy.ActorLocation;
            float AttackAngle = Event.AttackDirection.AngularDistance(ToPlayer); 
            if (AttackAngle > FMath::DegreesToRadians(ConeAngle))
                continue;

            FCastlePlayerDamageEvent Evt;
            Evt.DamageSource = Enemy;
            Evt.DamageDealt = Damage;
            Evt.DamageLocation = Player.ActorCenterLocation;
            Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
            Evt.DamageEffect = DamageEffect;

			NetTriggerOnHitEffect(Player, Evt);
            Player.DamageCastlePlayer(Evt);
        }
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetTriggerOnHitEffect(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent)
	{
		FVector PushForce = DamageEvent.DamageDirection.GetSafeNormal() * 2000.f;
		PushForce += FVector(0.f, 0.f, 2000.f);
		Player.AddImpulse(PushForce);
		BP_OnHitPlayer(Player, DamageEvent);
	}

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Hit Player"))
    void BP_OnHitPlayer(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent) {}
};
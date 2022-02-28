import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAI.CastleEnemyAIAttackCapabilityBase;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.Capabilities.KnockDown.KnockdownStatics;

class UCastleEnemyAIConeAttackCapability : UCastleEnemyAIAttackCapabilityBase
{
    // Angle of the attack cone
    UPROPERTY()
    float ConeAngle = 60.f;

    // Distance the attack cone travels
    UPROPERTY()
    float ConeDistance = 400.f;

    // Minimum damage dealt to the player
    UPROPERTY()
    float MinPlayerDamageDealt = 7.f;

    // Maximum damage dealt to the player
    UPROPERTY()
    float MaxPlayerDamageDealt = 9.f;

    // Knockback force applied to the player
    UPROPERTY()
    float KnockbackForce = 0.f;

	UPROPERTY()
	UForceFeedbackEffect HitForceFeedback;

    // The damage effect that is used on the player. Leave empty for the default.
    UPROPERTY()
    TSubclassOf<UCastleDamageEffect> DamageEffect;

	UPROPERTY()
	UAkAudioEvent PlayerHitAudioEvent;	

    void ExecuteAttack(FAttackExecuteEvent Event) override
    {
		if (Event.bCanceled)
			return;

        UCastleEnemyAIAttackCapabilityBase::ExecuteAttack(Event);

        FVector ConeStart = Enemy.ActorLocation;
        //System::DrawDebugConeInDegrees(ConeStart, AttackDirection, ConeDistance, ConeAngle, 0.f, Duration = 2.f);

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

            //System::DrawDebugPoint(Player.ActorLocation, 50.f, PointColor = FLinearColor::Red, Duration = 2.f);

            FCastlePlayerDamageEvent Evt;
            Evt.DamageSource = Enemy;
            Evt.DamageDealt = Damage;
            Evt.DamageLocation = Player.ActorCenterLocation;
            Evt.DamageDirection = Math::ConstrainVectorToPlane(ToPlayer, FVector::UpVector);
            Evt.DamageEffect = DamageEffect;

			NetTriggerOnHitEffect(Player, Evt);
			if (HitForceFeedback != nullptr)
				Player.PlayForceFeedback(HitForceFeedback, false, false, n"CastleHit");
            Player.DamageCastlePlayer(Evt);

			if (KnockbackForce > 0.f)
			{
				FVector KnockImpulse = AttackDirection.GetSafeNormal() * KnockbackForce + FVector(0.f, 0.f, 1000.f);
				Player.KnockdownActor(KnockImpulse);
			}
        }
    }

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetTriggerOnHitEffect(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent)
	{
		BP_OnHitPlayer(Player, DamageEvent);
		PlayPlayerHitAudioEvent(Player);		
	}

    UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Hit Player"))
    void BP_OnHitPlayer(AHazePlayerCharacter Player, FCastlePlayerDamageEvent DamageEvent) {}

	void PlayPlayerHitAudioEvent(AHazeActor Actor)
	{
		if (PlayerHitAudioEvent != nullptr && Actor != nullptr)
		{
			HazeAkComp.HazePostEvent(PlayerHitAudioEvent);
		}
	}
};
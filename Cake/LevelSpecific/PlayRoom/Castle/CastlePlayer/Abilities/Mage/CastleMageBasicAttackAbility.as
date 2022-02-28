import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleBasicAttackAbility;
import Cake.Environment.BreakableStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleLevelScripts.CastleFirePlatform;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleHittableComponent;

class UCastleMageBasicAttackAbility : UCastleBasicAttackAbility
{
	UPROPERTY(Category = "Attack Attributes")
	UNiagaraSystem AttackEffect;
	UPROPERTY(Category = "Attack Attributes")
	float AttackLength = 300.f;
	UPROPERTY(Category = "Attack Attributes")
	float AttackWidth = 300.f;

	UPROPERTY(Category = "Attack Damage")
	int AttackDamageMin = 6;
	UPROPERTY(Category = "Attack Damage")
	int AttackDamageMax = 6;
	UPROPERTY(Category = "Attack Damage")
	int AttackDamageSpeed = 800;

	UPROPERTY(Category = "Attack Knockback")
	float AttackKnockbackDurationMultiplier = 1.f;
	UPROPERTY(Category = "Attack Knockback")
	float AttackKnockbackVerticalForce = 1.f;
	UPROPERTY(Category = "Attack Knockback")
	float AttackKnockbackHorizontalForce = 1.f;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> CameraShakeType;
	UPROPERTY(Category = "Camera Shake")
	float CameraShakeScale = 1.f;

	UPROPERTY(Category = "Camera Force Feedback")
	UForceFeedbackEffect ForceFeedbackHitType;
	UPROPERTY(Category = "Camera Force Feedback")
	UForceFeedbackEffect ForceFeedbackMissType;

	UPROPERTY(Category = "Combo Data")
	UAkAudioEvent HitEnemyAudioEvent;

	UHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		Super::ControlPreActivation(ActivationParams);

		if (AttackDirection.IsNearlyZero())
		{
			FRotator Rotation = OwningPlayer.ActorRotation;
			TargetEnemy = CastleComponent.FindTargetEnemy(Rotation, AttackLength, 100.f);

			if (TargetEnemy != nullptr)
			{
				FVector ToEnemy = TargetEnemy.ActorLocation - Owner.ActorLocation;
				ToEnemy.Normalize();
				AttackDirection = ToEnemy;
			}
		}

		ActivationParams.AddVector(n"AttackDirection", AttackDirection.GetSafeNormal());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		UCastleBasicAttackAbility::OnActivated(ActivationParams);
				
		// Affect hit targets
		FVector StartLocation = OwningPlayer.ActorLocation;
		FVector EndLocation = OwningPlayer.ActorLocation + (AttackDirection * AttackLength);
		float Width = AttackWidth;


		// Get actors in box, and split them into castle enemies, and freezables
		TArray<AHazeActor> HitActors = GetActorsInBox(StartLocation, EndLocation, Width, bShowDebug = false);
		TArray<ABreakableActor> Breakables = GetBreakableActorsFromArray(HitActors);
		TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesFromArray(HitActors);
		TArray<UCastleFreezableComponent> HitFreezables = GetFreezableComponentsFromArray(HitActors);

		HazeAkComp = UHazeAkComponent::Get(OwningPlayer);

		for (ACastleEnemy HitEnemy : HitEnemies)
		{
			if (!IsHittableByAttack(OwningPlayer, HitEnemy, HitEnemy.ActorLocation))
				continue;
				
			DamageEnemy(HitEnemy);
			KnockbackEnemy(HitEnemy);
			FreezeEnemy(HitEnemy);
			PlayAudioEventAtActor(HitEnemyAudioEvent, HitEnemy);
		}
		
		for (ABreakableActor Breakable : Breakables)
		{
			if (!IsHittableByAttack(OwningPlayer, Breakable, Breakable.ActorLocation))
				continue;

			FBreakableHitData BreakableData;
			BreakableData.HitLocation = Breakable.ActorLocation;
			BreakableData.DirectionalForce = (Breakable.ActorLocation - OwningPlayer.ActorLocation).GetSafeNormal() * 5.f;
			BreakableData.ScatterForce = 5.f;

			Breakable.HitBreakableActor(BreakableData);
		}

		for (UCastleFreezableComponent HitFreezable : HitFreezables)
		{
			FVector ActorLocation = HitFreezable.Owner.ActorLocation;

			ACastleFirePlatform FirePlatform = Cast<ACastleFirePlatform>(HitFreezable.Owner);
			if (FirePlatform != nullptr)
				ActorLocation.Z = Owner.ActorLocation.Z;

			if (!IsHittableByAttack(OwningPlayer, FirePlatform, ActorLocation))
				continue;
				
			HitFreezable.HitFreezableActor(OwningPlayer);
		}

		for (AHazeActor HitActor : HitActors)
		{
			UCastleHittableComponent HittableComp = UCastleHittableComponent::Get(HitActor);
			if (HittableComp == nullptr)
				continue;
			if (!IsHittableByAttack(OwningPlayer, HitActor, HitActor.ActorLocation))
				continue;

			HittableComp.OnHitByCastlePlayer.Broadcast(OwningPlayer, HitActor.ActorLocation);
		}

		FVector EffectEndLocation = EndLocation;
		ModifyAttackDistanceForCollision(StartLocation, EffectEndLocation);

		SpawnEffect(OwningPlayer.ActorLocation + FVector(0, 0, 90.f), OwningPlayer.ActorRotation, Width, EffectEndLocation.Distance(StartLocation));
		PlayForceFeedback(HitEnemies.Num());
		PlayCameraShake(HitEnemies.Num());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (!MoveComp.CanCalculateMovement())
			return;

        FHazeFrameMovement Movement = MoveComponent.MakeFrameMovement(n"CastleMageBasicAttack");
		if (HasControl())
		{
			FVector Gravity = -MoveComp.WorldUp * 1100.f * DeltaTime;
			Movement.ApplyVelocity(Gravity);
			Movement.ApplyActorVerticalVelocity();

			MoveComponent.SetTargetFacingDirection(AttackDirection);
			Movement.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveCharacter(Movement, n"CastleBasicAttack");
		CrumbComp.LeaveMovementCrumb();
	}

	void DamageEnemy(ACastleEnemy CastleEnemy)
	{
		if (CastleEnemy == nullptr)
			return;

		FCastleEnemyDamageEvent DamageEvent;

		DamageEvent.DamageDealt = FMath::RandRange(AttackDamageMin, AttackDamageMax);
		if (CastleComponent.IsAttackCritical())
		{
			DamageEvent.DamageDealt *= CastleComponent.CriticalStrikeDamage;
			DamageEvent.bIsCritical = true;
		}

		DamageEvent.DamageSource = OwningPlayer;
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
		DamageEvent.DamageDirection = Owner.ActorForwardVector;
		DamageEvent.DamageSpeed = AttackDamageSpeed;

		DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);
	}

	void KnockbackEnemy(ACastleEnemy CastleEnemy)
	{		
		if (CastleEnemy == nullptr)
			return;

		FCastleEnemyKnockbackEvent KnockbackEvent;

		KnockbackEvent.Source = OwningPlayer;
		KnockbackEvent.Location = CastleEnemy.ActorLocation;
		KnockbackEvent.Direction = Owner.ActorForwardVector;
		KnockbackEvent.DurationMultiplier = AttackKnockbackDurationMultiplier;
		KnockbackEvent.HorizontalForce = AttackKnockbackHorizontalForce;
		KnockbackEvent.VerticalForce = AttackKnockbackVerticalForce;
		KnockbackEvent.KnockBackCurveOverride;
		KnockbackEvent.KnockUpCurveOverride;

		CastleEnemy.KnockBack(KnockbackEvent);
	}

	void FreezeEnemy(ACastleEnemy CastleEnemy)
	{		
		if (CastleEnemy == nullptr)
			return;

		FCastleEnemyStatusEffect Status;
		Status.Type = ECastleEnemyStatusType::Freeze;
		Status.Duration = 1.5f;
		Status.Magnitude = 1.f;

		CastleEnemy.ApplyStatusEffect(Status);
	}

	UFUNCTION()
	void SpawnEffect(FVector WorldLocation, FRotator WorldRotation, float Width, float Length)
	{
		if (AttackEffect == nullptr)
			return;

		UNiagaraComponent Effect = Niagara::SpawnSystemAtLocation(AttackEffect, WorldLocation, WorldRotation);
		Effect.SetNiagaraVariableFloat("User.Length", Length);
		Effect.SetNiagaraVariableFloat("User.Width", Width);
	}

	void PlayForceFeedback(int HitEnemyCount)
	{
		UForceFeedbackEffect ForceFeedbackEffect = HitEnemyCount > 0 ? ForceFeedbackHitType : ForceFeedbackMissType;

		if (ForceFeedbackEffect == nullptr)
			return;

		OwningPlayer.PlayForceFeedback(ForceFeedbackEffect, bLooping = false, bIgnoreTimeDilation = true, Tag = n"None");
	}

	void PlayCameraShake(int HitEnemyCount)
	{
		if (!CameraShakeType.IsValid())
			return;

		float ActualCameraShakeScale = CameraShakeScale;
		if (HitEnemyCount == 0)
			ActualCameraShakeScale *= 0.5f;

 		Game::GetMay().PlayCameraShake(CameraShakeType, ActualCameraShakeScale);
	}

	void PlayAudioEventAtActor(UAkAudioEvent AudioEvent, AHazeActor Actor)
	{
		if (AudioEvent != nullptr)
			HazeAkComp.HazePostEvent(AudioEvent);
	}
}
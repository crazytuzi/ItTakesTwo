import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleBasicAttackAbility;
import Cake.Environment.BreakableStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteSword;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleHittableComponent;

class UCastleBruteBasicAttackAbility : UCastleBasicAttackAbility
{
	UPROPERTY(Category = "Attack Attributes")
	UNiagaraSystem AttackEffect;
	UPROPERTY(Category = "Attack Attributes")
	float AttackRadius = 230.f;
	UPROPERTY(Category = "Attack Attributes")
	float AttackConeDegrees = 200.f;

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

	ACastleBruteSword BruteSword;

	default SlotName = n"BasicAttack";

	UPROPERTY(Category = "Combo Data")
	UAkAudioEvent HitEnemyAudioEvent;

	UHazeAkComponent HazeAkComp;

	FVector InitialLocation;
	FVector TargetLocation;

	// How long the move portion of the attack takes
	const float MoveDuration = 0.14f;
	const float MovePOW = 0.6f;

	const float EnemyTargetMaxAngle = 115.f;
	const float MoveDistanceTarget = 600.f;
	const float MovementMargin = 105.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleBasicAttackAbility::Setup(SetupParams);		

		// Find the attached sword
		TArray<AActor> AttachedActors;
		OwningPlayer.GetAttachedActors(AttachedActors);

		for (AActor AttachedActor : AttachedActors)
		{
			if (Cast<ACastleBruteSword>(AttachedActor) != nullptr)
			{
				BruteSword = Cast<ACastleBruteSword>(AttachedActor);
				HazeAkComp = UHazeAkComponent::Get(OwningPlayer, n"HazeAkComponent");
				break;
			}
		}
	}

	float GetRangeForAutoTarget() override
	{
		return MoveDistanceTarget + MovementMargin;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		Super::ControlPreActivation(ActivationParams);

		// Check if we have a target enemy in our attack direction
		FRotator Rotation = FRotator::MakeFromX(AttackDirection);
		TargetEnemy = CastleComponent.FindTargetEnemy(Rotation, MoveDistanceTarget + MovementMargin, EnemyTargetMaxAngle);
		TargetLocation = Owner.ActorLocation;

		// Calculate the target location
		if (TargetEnemy != nullptr)
		{
			// Get vector to the enemy
			FVector ToEnemy = TargetEnemy.ActorLocation - Owner.ActorLocation;
			ToEnemy = ToEnemy.ConstrainToPlane(MoveComponent.WorldUp);

			if (ToEnemy.DotProduct(Owner.ActorForwardVector) > 0.f)
			{
				// Update attack direction as we can't be sure the enemy is in the correct direction
				AttackDirection = ToEnemy.GetSafeNormal();
				if (AttackDirection.IsNearlyZero())
					AttackDirection = Owner.ActorForwardVector;

				// Pull the attack back a bit outside of the capsule so that the player does aim for inside them
				ToEnemy -= (ToEnemy.GetSafeNormal() * (TargetEnemy.CapsuleComponent.CapsuleRadius + MovementMargin));
				ToEnemy = ToEnemy.GetClampedToMaxSize(MoveDistanceTarget);

				TargetLocation = Owner.ActorLocation + ToEnemy;
			}
		}	

		ActivationParams.AddVector(n"AttackDirection", AttackDirection.GetSafeNormal());
		ActivationParams.AddVector(n"TargetLocation", TargetLocation);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		UCastleBasicAttackAbility::OnActivated(ActivationParams);

		InitialLocation = Owner.ActorLocation;
		TargetLocation = ActivationParams.GetVector(n"TargetLocation");

		// Deal damage at the target location
		FTransform AttackTransform;
		AttackTransform.Location = TargetLocation;
		AttackTransform.Rotation = Owner.ActorRotation.Quaternion();
		DamageEnemiesAtTransform(AttackTransform);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		if (!MoveComp.CanCalculateMovement())
			return;

        FHazeFrameMovement Movement = MoveComponent.MakeFrameMovement(n"CastleBruteBasicAttack");
		if (HasControl())
		{
			float MoveAlpha = FMath::Clamp(ActiveDuration / MoveDuration, 0.f, 1.f);
			MoveAlpha = FMath::Pow(MoveAlpha, MovePOW);

			FVector MoveLocation = FMath::Lerp(InitialLocation, TargetLocation, MoveAlpha);
			MoveLocation.Z = Owner.ActorLocation.Z;
	
			FVector DeltaMove = MoveLocation - Owner.ActorLocation;
			DeltaMove = DeltaMove.ConstrainToPlane(MoveComp.WorldUp);
			
			FVector Gravity = -MoveComp.WorldUp * 1100.f * DeltaTime;
			Movement.ApplyVelocity(Gravity);
			Movement.ApplyActorVerticalVelocity();

			Movement.ApplyDelta(DeltaMove);
	
			MoveComponent.SetTargetFacingDirection(AttackDirection);
			Movement.OverrideStepUpHeight(50.f);
			Movement.OverrideStepDownHeight(0.f);
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

	void DamageEnemiesAtTransform(FTransform Transform)
	{
		// Affect hit targets
		FVector Origin = Transform.Location;
		FRotator Rotation = Transform.Rotation.Rotator();
		float Radius = AttackRadius;

		// Get actors in box, and split them into castle enemies, and freezables
		TArray<AHazeActor> HitActors = GetActorsInCone(Origin, Rotation, Radius, AttackConeDegrees, bShowDebug = false);
		TArray<ABreakableActor> Breakables = GetBreakableActorsFromArray(HitActors);
		TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesFromArray(HitActors);				

		for (ACastleEnemy HitEnemy : HitEnemies)
		{
			if (!IsHittableByAttack(OwningPlayer, HitEnemy, HitEnemy.ActorLocation))
				continue;
			DamageEnemy(HitEnemy);
			KnockbackEnemy(HitEnemy);
			BurnEnemy(HitEnemy);
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

		for (AHazeActor HitActor : HitActors)
		{
			UCastleHittableComponent HittableComp = UCastleHittableComponent::Get(HitActor);
			if (HittableComp == nullptr)
				continue;
			if (!IsHittableByAttack(OwningPlayer, HitActor, HitActor.ActorLocation))
				continue;

			HittableComp.OnHitByCastlePlayer.Broadcast(OwningPlayer, HitActor.ActorLocation);
		}

		SpawnEffect(OwningPlayer.ActorLocation + FVector(0, 0, 90.f), OwningPlayer.ActorRotation);
		PlayForceFeedback(HitEnemies.Num());
		PlayCameraShake(HitEnemies.Num());
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
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation + FVector(0, 0, 90);

		FVector PlayerToEnemyDirection = (CastleEnemy.ActorLocation - OwningPlayer.ActorLocation).GetSafeNormal();

		if (ComboNumber == 1)
			DamageEvent.DamageDirection = PlayerToEnemyDirection.CrossProduct(FVector::UpVector);
		else if (ComboNumber == 2)
			DamageEvent.DamageDirection = -PlayerToEnemyDirection.CrossProduct(FVector::UpVector);
		else
			DamageEvent.DamageDirection = PlayerToEnemyDirection;	

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

		FVector PlayerToEnemyDirection = (CastleEnemy.ActorLocation - OwningPlayer.ActorLocation).GetSafeNormal();

		if (ComboNumber == 1)
			KnockbackEvent.Direction = PlayerToEnemyDirection.CrossProduct(FVector::UpVector);
		else if (ComboNumber == 2)
			KnockbackEvent.Direction = -PlayerToEnemyDirection.CrossProduct(FVector::UpVector);
		else
			KnockbackEvent.Direction = PlayerToEnemyDirection;	
	
		KnockbackEvent.DurationMultiplier = AttackKnockbackDurationMultiplier;
		KnockbackEvent.HorizontalForce = AttackKnockbackHorizontalForce;
		KnockbackEvent.VerticalForce = AttackKnockbackVerticalForce;
		KnockbackEvent.KnockBackCurveOverride;
		KnockbackEvent.KnockUpCurveOverride;

		CastleEnemy.KnockBack(KnockbackEvent);
	}

	void BurnEnemy(ACastleEnemy CastleEnemy)
	{		
		if (CastleEnemy == nullptr)
			return;

		FCastleEnemyStatusEffect Status;
		Status.Type = ECastleEnemyStatusType::Burn;
		Status.Duration = 3.1f;
		Status.Magnitude = 1.f;

		CastleEnemy.ApplyStatusEffect(Status);
	}

	UFUNCTION()
	void SpawnEffect(FVector WorldLocation, FRotator WorldRotation)
	{
		if (AttackEffect == nullptr)
			return;

		UNiagaraComponent Effect = Niagara::SpawnSystemAtLocation(AttackEffect, WorldLocation, WorldRotation);
		//Effect.SetNiagaraVariableFloat("User.Length", AttackLength);
		//Effect.SetNiagaraVariableFloat("User.Width", AttackWidth);
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
			AkComp.HazePostEvent(AudioEvent);		
	}
}
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;
import Vino.Movement.MovementSettings;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteWhirlwind;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteIgnitedGround;
import Cake.Environment.BreakableStatics;

class UCastleBruteIgniteCapability : UCastleAbilityCapability
{    
    default CapabilityTags.Add(n"AbilityIgnite");
	default CapabilityTags.Add(CapabilityTags::Input);

	default TickGroupOrder = 2;

	float AbilityDuration = 0.5f;
	float CastPoint = 0.4f;

	const float MinDamage = 20.f;
	const float MaxDamage = 40.f;
	const float ExplosionRadius = 400.f;

	float IgniteCooldown = 3.f;

    float Cooldown = IgniteCooldown;
    float CooldownCurrent = 0.f;	

	float Height = 0.f;

	default SlotName = n"Ignite";

	UPROPERTY()
	TSubclassOf<ACastleBruteIgnitedGround> GroundEffect;
	int SpawnGroundCounter = 0;

	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;

	UPROPERTY()
	UCurveFloat HeightCurve;

	UPROPERTY()
	UNiagaraSystem ImpactEffect;

	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> CameraShakeType;
	UPROPERTY(Category = "Camera Shake")
	float CameraShakeScale = 1.f;

	UPROPERTY(Category = "Camera Force Feedback")
	UForceFeedbackEffect ForceFeedback;

	UHazeCrumbComponent CrumbComponent;
	UHazeAkComponent HazeAkComp;
	bool bSpawnedIgnite = false;
	FVector StartLocation;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleAbilityCapability::Setup(SetupParams);
		CrumbComponent = UHazeCrumbComponent::GetOrCreate(OwningPlayer);
		HazeAkComp = UHazeAkComponent::Get(OwningPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
    {
        if (CooldownCurrent > 0)
            CooldownCurrent -= DeltaTime;

		if (SlotWidget != nullptr)
		{
			SlotWidget.CooldownDuration = Cooldown;
			SlotWidget.CooldownCurrent = CooldownCurrent;
		}

		if (WasActionStarted(ActionNames::CastleAbilitySecondary))
			SlotWidget.SlotPressed();
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (CooldownCurrent > 0)
			return EHazeNetworkActivation::DontActivate; 

		if (!CastleComponent.bComboCanAttack)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::CastleAbilitySecondary))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;       
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ActiveDuration > AbilityDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;
        return EHazeNetworkDeactivation::DontDeactivate;
	}  

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		Cooldown = IgniteCooldown;	
		CooldownCurrent = Cooldown;	
		bSpawnedIgnite = false;
		StartLocation = OwningPlayer.ActorLocation;

		SlotWidget.SlotActivated();

		if (ActivatedAudioEvent != nullptr)
			HazeAkComp.HazePostEvent(ActivatedAudioEvent);		
	} 

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (!bSpawnedIgnite)
			SpawnIgnite();

		OwningPlayer.MeshOffsetComponent.ResetLocationWithTime(0.f);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
		if (MoveComponent.CanCalculateMovement())
			MovePlayer(DeltaTime);

		if (!bSpawnedIgnite && ActiveDuration >= CastPoint)
		{
			SpawnIgnite();

			TArray<AHazeActor> HitActors = GetActorsInCone(Owner.ActorLocation, FRotator::ZeroRotator, ExplosionRadius, 360.f, false);
			TArray<ABreakableActor> Breakables = GetBreakableActorsFromArray(HitActors);
			TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesFromArray(HitActors);			
			for (ACastleEnemy HitCastleEnemy : HitEnemies)
			{
				if (!IsHittableByAttack(OwningPlayer, HitCastleEnemy, HitCastleEnemy.ActorLocation))
					continue;

				DamageEnemy(HitCastleEnemy);
			}

			for (ABreakableActor Breakable : Breakables)
			{
				if (!IsHittableByAttack(OwningPlayer, Breakable, Breakable.ActorLocation))
					continue;

				FBreakableHitData BreakableData;
				BreakableData.HitLocation = Breakable.ActorLocation;
				BreakableData.DirectionalForce = (Breakable.ActorLocation - OwningPlayer.ActorLocation).GetSafeNormal() * 5.f;
				BreakableData.ScatterForce = 5.f;
				BreakableData.NumberOfHits = 2;

				Breakable.HitBreakableActor(BreakableData);
			}
		}
	}

	void SpawnIgnite()
	{
		bSpawnedIgnite = true;

		PlayForceFeedback();
		PlayCameraShake();

		Niagara::SpawnSystemAtLocation(
			ImpactEffect,
			StartLocation,
			OwningPlayer.ActorRotation);

		if (GroundEffect.IsValid())
		{
			ACastleBruteIgnitedGround Ignite = Cast<ACastleBruteIgnitedGround>(SpawnActor(
				GroundEffect,
				StartLocation,
				FRotator(),
				bDeferredSpawn = true));

			Ignite.OwningPlayer = OwningPlayer;	
			FinishSpawningActor(Ignite);
		}
	}

	void DamageEnemy(ACastleEnemy CastleEnemy)
	{
		FCastleEnemyDamageEvent DamageEvent;

		float DistanceToExplosion = CastleEnemy.ActorLocation.Dist2D(Owner.ActorLocation) - CastleEnemy.CapsuleComponent.ScaledCapsuleRadius;
		DamageEvent.DamageDealt = MinDamage + FMath::Clamp(1.f - (DistanceToExplosion / ExplosionRadius), 0.f, 1.f) * (MaxDamage - MinDamage);

		DamageEvent.DamageDirection = (CastleEnemy.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		DamageEvent.DamageSpeed = 900.f;
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
		DamageEvent.DamageSource = OwningPlayer;

		DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);
	}

	void MovePlayer(float DeltaTime)
	{
		FVector TargetLocation = StartLocation;
		if (HeightCurve != nullptr)
			TargetLocation.Z += Height * HeightCurve.GetFloatValue(ActiveDuration / AbilityDuration);

		OwningPlayer.MeshOffsetComponent.OffsetLocationWithTime(
			TargetLocation, 0.f); 

		if (MoveComp.CanCalculateMovement())
		{
			if (HasControl())
			{
				FHazeFrameMovement Movement = MoveComponent.MakeFrameMovement(n"CastleBruteIgnite");     
				Movement.OverrideCollisionProfile(n"PlayerCharacterIgnorePawn");
				MoveCharacter(Movement, n"CastleIgnite");
							
				CrumbComponent.LeaveMovementCrumb();
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

				FHazeFrameMovement MoveData = MoveComponent.MakeFrameMovement(n"CastleBruteIgnite");
				MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

				MoveData.OverrideCollisionProfile(n"PlayerCharacterIgnorePawn");
				MoveCharacter(MoveData, n"CastleIgnite");
			}
		}
	}

	void PlayForceFeedback()
	{
		if (ForceFeedback == nullptr)
			return;

		OwningPlayer.PlayForceFeedback(ForceFeedback, bLooping = false, bIgnoreTimeDilation = true, Tag = n"None");
	}

	void PlayCameraShake()
	{
		if (!CameraShakeType.IsValid())
			return;

 		Game::GetMay().PlayCameraShake(CameraShakeType, CameraShakeScale);
	}
}
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteSword;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;
import Cake.Environment.BreakableStatics;

class UCastleBruteDashAbility : UCastleAbilityCapability
{    
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default BlockExclusionTags.Add(n"CanCancelUltimate");
	
    default CapabilityTags.Add(n"AbilityDash");
	default CapabilityTags.Add(CapabilityTags::Input);

    UPROPERTY()
    float Cooldown = 1.0f;
    UPROPERTY()
    float CooldownCurrent = 0.f;

    UPROPERTY()
    bool bDashComplete = true;
    UPROPERTY()
    float DashDistance = 1000;
    UPROPERTY()
    float DashDuration = 0.3f;
    UPROPERTY()
    float DashSpeed;
    UPROPERTY()
    FVector DashDirection;
	UPROPERTY()
    float DashDamage = 40.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY()
	UNiagaraSystem DashEffectType;
	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;
	UPROPERTY()
	UAkAudioEvent DeactivatedAudioEvent;
	UPROPERTY()
	UAkAudioEvent EnemyHitAudioEvent;
	
	ACastleBruteSword BruteSword;
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY()
	UCastleAnimationBruteDataAsset AnimationData;

	TArray<ACastleEnemy> DamagedEnemies;

	default SlotName = n"Dash";

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleAbilityCapability::Setup(SetupParams);
		
		AkComp = UHazeAkComponent::Get(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);

		// Find the attached sword
		TArray<AActor> AttachedActors;
		OwningPlayer.GetAttachedActors(AttachedActors);

		for (AActor AttachedActor : AttachedActors)
		{
			if (Cast<ACastleBruteSword>(AttachedActor) != nullptr)
			{
				BruteSword = Cast<ACastleBruteSword>(AttachedActor);
				break;
			}
		}
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

		if (WasActionStarted(ActionNames::CastleAbilityDash))
			SlotWidget.SlotPressed();
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

        if (!WasActionStarted(ActionNames::CastleAbilityDash))
			return EHazeNetworkActivation::DontActivate;

		if (CooldownCurrent > 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;       
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!MoveComponent.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

        if (ActiveDuration >= DashDuration)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
                    
        return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if (GetAttributeVector(AttributeVectorNames::MovementDirection).Size() >= 0.1f)
            DashDirection = GetAttributeVector(AttributeVectorNames::MovementDirection).GetSafeNormal();
        else
            DashDirection = Owner.ActorForwardVector;

		ActivationParams.AddVector(n"DashDirection", DashDirection);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {		
        Owner.BlockCapabilities(CapabilityTags::Movement, this);
        Owner.BlockCapabilities(CapabilityTags::MovementAction, this);
        Owner.BlockCapabilities(n"CastleAbility", this);
        Owner.BlockCapabilities(n"KnockDown", this);

        DashDirection = ActivationParams.GetVector(n"DashDirection");
		MoveComponent.SetTargetFacingDirection(DashDirection);

		DamagedEnemies.Empty();

        DashSpeed = DashDistance / DashDuration;
        CooldownCurrent = Cooldown;

		SlotWidget.SlotActivated();

		if (DashEffectType != nullptr)
			Niagara::SpawnSystemAttached(DashEffectType, Owner.RootComponent, NAME_None, FVector(), FRotator(), EAttachLocation::SnapToTarget, true);
		//DashEffectType, Owner.ActorLocation, FRotator::MakeFromX(DashDirection));

		PlayAudioEventFromComponent(AkComp, ActivatedAudioEvent);
		OwningPlayer.AddPlayerInvulnerability(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayAudioEventFromComponent(AkComp, DeactivatedAudioEvent);

		MoveComponent.SetVelocity(FVector(0.f));

        Owner.UnblockCapabilities(CapabilityTags::Movement, this);
        Owner.UnblockCapabilities(CapabilityTags::MovementAction, this);
        Owner.UnblockCapabilities(n"CastleAbility", this);
        Owner.UnblockCapabilities(n"KnockDown", this);

		OwningPlayer.RemovePlayerInvulnerability(this);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
        FHazeFrameMovement Movement = MoveComponent.MakeFrameMovement(n"CastlePlayerDash");	

		if (HasControl())
		{
			FVector Velocity;
			Velocity = DashDirection * DashSpeed;

			FVector DeltaMovement;
			DeltaMovement = Velocity * DeltaTime;

			TraceMovementForDamage(DeltaMovement);
			Movement.ApplyVelocity(Velocity);

			Movement.OverrideCollisionProfile(n"PlayerCharacterIgnorePawn");
			Movement.OverrideStepUpHeight(50.f);
			Movement.OverrideStepDownHeight(0.f);
			Movement.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveCharacter(Movement, n"CastleDash");
		CrumbComponent.LeaveMovementCrumb();
    }

	void TraceMovementForDamage(FVector DeltaMove)  
	{
		TArray<AHazeActor> HitActors = GetActorsInCone(OwningPlayer.ActorLocation, OwningPlayer.ActorRotation, Radius = 175.f, AngleDegrees = 180, bShowDebug = false);
		TArray<ABreakableActor> Breakables = GetBreakableActorsFromArray(HitActors);
		TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesFromArray(HitActors);

		for (ACastleEnemy CastleEnemy : HitEnemies)
		{
			if (!DamagedEnemies.Contains(CastleEnemy))
			{
				DamageEnemy(CastleEnemy);	
				PlayEnemyHitAudioEvent(CastleEnemy);

				DamagedEnemies.Add(CastleEnemy);
			}
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
	}

	void DamageEnemy(ACastleEnemy CastleEnemy)
	{		
		FCastleEnemyDamageEvent DamageEvent;

		DamageEvent.DamageDealt = DashDamage;
		if (CastleComponent.IsAttackCritical())
		{
			DamageEvent.DamageDealt *= CastleComponent.CriticalStrikeDamage;
			DamageEvent.bIsCritical = true;
		}	
		
		DamageEvent.DamageDirection = ((CastleEnemy.ActorLocation - Owner.ActorLocation).GetSafeNormal() + Owner.ActorForwardVector).GetSafeNormal();
		DamageEvent.DamageSpeed = 2200.f;		
		DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
		DamageEvent.DamageSource = OwningPlayer;

		DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);

		FCastleEnemyKnockbackEvent KnockbackEvent;
		KnockbackEvent.Source = OwningPlayer;
		KnockbackEvent.DurationMultiplier = 1.5f;
		KnockbackEvent.Direction = ((CastleEnemy.ActorLocation - Owner.ActorLocation).GetSafeNormal() + Owner.ActorForwardVector).GetSafeNormal();
		KnockbackEvent.HorizontalForce = 8.f;
		KnockbackEvent.VerticalForce = 2.f;
		CastleEnemy.KnockBack(KnockbackEvent);
	}

	void PlayAudioEventFromComponent(UHazeAkComponent AkComponent, UAkAudioEvent AudioEvent)
	{
		if (AkComponent != nullptr && AudioEvent != nullptr)
			AkComponent.HazePostEvent(AudioEvent);
			
	}

	void PlayEnemyHitAudioEvent(AHazeActor Actor)
	{
		if (EnemyHitAudioEvent != nullptr && Actor != nullptr)
			HazeAudio::PostEventAtLocation(EnemyHitAudioEvent, Actor);
			
	}
}

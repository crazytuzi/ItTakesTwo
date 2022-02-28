import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;
import Vino.Movement.MovementSettings;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteWhirlwind;
import Peanuts.Audio.AudioStatics;
import Cake.Environment.BreakableStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleDungeonVOBank;

class UCastleBruteWhirlwindAbility : UCastleAbilityCapability
{    
    default CapabilityTags.Add(n"AbilityWhirlwind");
	default CapabilityTags.Add(CapabilityTags::Input);
	
    default BlockExclusionTags.Add(n"CanCancelKnockdown");
	default TickGroupOrder = 2;

	UPROPERTY()
    float Duration = 5.0f;
    UPROPERTY()
    float DurationCurrent = 0.f;

	UPROPERTY(Category = "Movement")
	float WhirlwindMoveSpeed = 800.f;
	UPROPERTY(Category = "Movement")
	float TurnRate = 3.5f;
	FVector Velocity;
	FVector MoveDirection;

	default SlotName = n"Ultimate";

	float TickTimer = BIG_NUMBER;
	UPROPERTY(Category = "Damage")
	float DamageRadius = 400.f;
	UPROPERTY(Category = "Damage")
	float DamageAngleDeg = 360.f;
	UPROPERTY(Category = "Damage")
	float TickInterval = 0.15f;
	UPROPERTY(Category = "Damage")
	float DamagePerTickMin = 8.f;
	float DamagePerTickMax = 12.f;

	UHazeCrumbComponent CrumbComponent;
	UNiagaraComponent WhirlwindComp;
	float WhirlwindStrength = 0.f;

	UHazeAkComponent WhirlwindAkComponent;
	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;
	UPROPERTY()
	UAkAudioEvent DeactivatedAudioEvent;
	UPROPERTY()
	UAkAudioEvent EnemyHitAudioEvent;
	UPROPERTY()	
	UNiagaraSystem WhilrwindEffect;

	UPROPERTY()
	UCastleDungeonVOBank VOBank;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleAbilityCapability::Setup(SetupParams);

		WhirlwindAkComponent = UHazeAkComponent::Get(Owner);
		CrumbComponent = UHazeCrumbComponent::GetOrCreate(OwningPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(ActionNames::CastleAbilityUltimate))
			return EHazeNetworkActivation::DontActivate; 

		if (!CastleComponent.bComboCanAttack)
			return EHazeNetworkActivation::DontActivate;   

		if (CastleComponent.UltimateCharge < CastleComponent.UltimateChargeMax)
        	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;       
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DurationCurrent >= Duration)
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
	}  

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (WasActionStarted(ActionNames::CastleAbilityUltimate))
			SlotWidget.SlotPressed();
	}

	// UFUNCTION(BlueprintOverride)
	// void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	// {	
	// 	if (GetAttributeVector(AttributeVectorNames::MovementDirection).Size() > 0)
	// 		MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
	// 	else
	// 		MoveDirection = GetOwningPlayersRotation().ForwardVector;


	// 	ActivationParams.AddVector(n"InitialDirection", MoveDirection);
	// }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		SlotWidget.SlotActivated();

		CastleComponent.UltimateCharge = CastleComponent.UltimateChargeMax;

        OwningPlayer.BlockCapabilities(n"AbilityBasicAttack", this);
        OwningPlayer.BlockCapabilitiesExcluding(n"GameplayAction", n"CanCancelUltimate", this);

		DurationCurrent = 0.f;

		PlayAudioEventFromComponent(WhirlwindAkComponent, ActivatedAudioEvent);
		OwningPlayer.AddPlayerInvulnerability(this);

		CastleComponent.bUsingUltimate = true;

		if (WhirlwindComp == nullptr)
			WhirlwindComp = Niagara::SpawnSystemAttached(WhilrwindEffect, Owner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
		else
			WhirlwindComp.Activate();

		WhirlwindStrength = 0.f;

		UMovementSettings::SetMoveSpeed(OwningPlayer, 1000.f, Instigator = this);

		PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleDungeonUltimateMay");
		PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleFireTornadoFirstReactionCody");
	} 

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UMovementSettings::ClearMoveSpeed(OwningPlayer, Instigator = this);

		PlayAudioEventFromComponent(WhirlwindAkComponent, DeactivatedAudioEvent);

		OwningPlayer.ClearSettingsByInstigator(Instigator = this);

        OwningPlayer.UnblockCapabilities(n"AbilityBasicAttack", this);		
        OwningPlayer.UnblockCapabilities(n"GameplayAction", this);		
		OwningPlayer.RemovePlayerInvulnerability(this);

		WhirlwindComp.Deactivate();
		CastleComponent.bUsingUltimate = false;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
		if (HasControl())
		{
			UpdateTickInterval(DeltaTime);
		}

		UpdateAbilityDuration(DeltaTime);

		if(CharacterOwner.Mesh.CanRequestLocomotion())
		{
        	FHazeRequestLocomotionData AnimationRequest;
			AnimationRequest.AnimationTag = n"CastleWhirlwind";

			CharacterOwner.RequestLocomotion(AnimationRequest);
		}

		SpendUltimateCharge(DeltaTime);

		WhirlwindStrength = FMath::Min((WhirlwindStrength + DeltaTime), 1.f);
		WhirlwindComp.SetNiagaraVariableFloat("User.Strength", WhirlwindStrength);
	}

	void SpendUltimateCharge(float DeltaTime)
	{
		if (CastleComponent == nullptr)
			return;

		CastleComponent.AddUltimateCharge(-CastleComponent.UltimateChargeMax/Duration * DeltaTime);
	}

	void UpdateAbilityDuration(float DeltaTime)
	{
		DurationCurrent += DeltaTime;
	}

	void UpdateTickInterval(float DeltaTime)
	{
		TickTimer += DeltaTime;

		if (TickTimer >= TickInterval)
		{
			DamageEnemies();
			
			TickTimer = 0.f;
		}
	}

	void DamageEnemies()
	{
		TArray<AHazeActor> HitActors = GetActorsInCone(OwningPlayer.ActorLocation, OwningPlayer.ActorRotation, DamageRadius, DamageAngleDeg, false);
		TArray<ABreakableActor> Breakables = GetBreakableActorsFromArray(HitActors);
		TArray<ACastleEnemy> HitEnemies = GetCastleEnemiesFromArray(HitActors);
		
		for (ACastleEnemy CastleEnemy : HitEnemies)
		{
			if (!IsHittableByAttack(OwningPlayer, CastleEnemy, CastleEnemy.ActorLocation))
				continue;

			float Damage = FMath::RandRange(DamagePerTickMin, DamagePerTickMax);
			bool bIsCritical = CastleComponent.IsAttackCritical(0.35f);
			if (bIsCritical)
				Damage *= CastleComponent.CriticalStrikeDamage;

			FCastleEnemyDamageEvent DamageEvent;
			DamageEvent.DamageDealt = Damage;
			DamageEvent.bIsCritical = bIsCritical;

			DamageEvent.DamageDirection = CastleEnemy.ActorLocation - OwningPlayer.ActorLocation;
			DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
			DamageEvent.DamageSpeed = 700.f;
			DamageEvent.DamageSource = OwningPlayer;
			DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);

			FCastleEnemyKnockbackEvent KnockbackEvent;
			KnockbackEvent.Source = OwningPlayer;
			KnockbackEvent.DurationMultiplier = 1.5f;
			KnockbackEvent.Direction = OwningPlayer.ActorLocation - CastleEnemy.ActorLocation;
			KnockbackEvent.HorizontalForce = 3.f;
			KnockbackEvent.VerticalForce = 1.5f;
			CastleEnemy.KnockBack(KnockbackEvent);

			PlayEnemyHitAudioEvent(CastleEnemy);
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
	
	void PlayAudioEventFromComponent(UHazeAkComponent HazeAkComponent, UAkAudioEvent AudioEvent)
	{
		if (HazeAkComponent != nullptr && AudioEvent != nullptr)
			HazeAkComponent.HazePostEvent(AudioEvent);
	}

	void PlayEnemyHitAudioEvent(AHazeActor Actor)
	{
		if (EnemyHitAudioEvent != nullptr && Actor != nullptr)
			WhirlwindAkComponent.HazePostEvent(EnemyHitAudioEvent);
	}
}
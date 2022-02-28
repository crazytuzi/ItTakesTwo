
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;
import Vino.Movement.MovementSettings;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Brute.CastleBruteWhirlwind;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.Mage.CastleMageBeamUltimateComponent;
import Cake.Environment.BreakableStatics;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleDungeonVOBank;

class UCastleMageBeamUltimateAbility : UCastleAbilityCapability
{    
    default CapabilityTags.Add(n"AbilityBeam");
	default CapabilityTags.Add(CapabilityTags::Input);
	
    default BlockExclusionTags.Add(n"CanCancelKnockdown");
	default TickGroupOrder = 2;

    UPROPERTY()
	float BeamDamageWidth = 400.f;
    UPROPERTY()
	float BeamVisualWidth = 500.f;

	UPROPERTY(Category = "Damage")
	float TickInterval = 0.15f;	
	UPROPERTY(Category = "Damage")
	float DamagePerTickMin = 9.f;
	float DamagePerTickMax = 13.f;

	UPROPERTY()	
	UNiagaraSystem BeamEffect;

	UCastleMageBeamUltimateComponent UltComp;
	UHazeCrumbComponent CrumbComponent;
	FVector WantedDirection;
	UNiagaraComponent BeamComp;
	float TickTimer = BIG_NUMBER;

	FVector BeamStart;
	FVector BeamEnd;
	FVector InitialLocation;

	FHazeAcceleratedRotator BeamRotation;
	bool bHitAnyEnemies = false;

	default SlotName = n"Ultimate";

	UPROPERTY()
	UCastleDungeonVOBank VOBank;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UCastleAbilityCapability::Setup(SetupParams);
		CrumbComponent = UHazeCrumbComponent::GetOrCreate(OwningPlayer);
		UltComp = UCastleMageBeamUltimateComponent::Get(OwningPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
    {
		if (WasActionStarted(ActionNames::CastleAbilityUltimate))
			SlotWidget.SlotPressed();
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

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
		if (!MoveComponent.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (UltComp.DurationCurrent >= UltComp.Duration)
			return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		WantedDirection = GetOwningPlayersRotation().ForwardVector;
		if (GetAttributeVector(AttributeVectorNames::MovementDirection).Size() > 0)
			WantedDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			
		auto TargetEnemy = CastleComponent.FindTargetEnemy(FRotator::MakeFromX(WantedDirection), 5000.f, 50.f);
		if (TargetEnemy != nullptr)
		{
			FVector ToEnemy = TargetEnemy.ActorLocation - Owner.ActorLocation;
			ToEnemy.Normalize();
			WantedDirection = ToEnemy;
		}

		ActivationParams.AddVector(n"InitialDirection", WantedDirection);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		SlotWidget.SlotActivated();
		UltComp.bActivated = true;

		InitialLocation = OwningPlayer.ActorLocation;
		WantedDirection = ActivationParams.GetVector(n"InitialDirection");
		BeamRotation.SnapTo(FRotator::MakeFromX(WantedDirection));

        OwningPlayer.BlockCapabilities(n"Movement", this);
        OwningPlayer.BlockCapabilities(n"AbilityBasicAttack", this);
        OwningPlayer.BlockCapabilitiesExcluding(n"GameplayAction", n"CanCancelUltimate", this);

		UltComp.DurationCurrent = 0.f;
		bHitAnyEnemies = false;

		CastleComponent.UltimateCharge = CastleComponent.UltimateChargeMax;

		OwningPlayer.AddPlayerInvulnerability(this);

		BeamComp = Niagara::SpawnSystemAttached(BeamEffect, Owner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		CastleComponent.bUsingUltimate = true;

		PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleDungeonUltimateCody");
		PlayFoghornVOBankEvent(VOBank, n"FoghornDBPlayroomCastleIceBeamFirstReactionMay");
	} 

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UltComp.bActivated = false;

        OwningPlayer.UnblockCapabilities(n"Movement", this);
        OwningPlayer.UnblockCapabilities(n"AbilityBasicAttack", this);		
        OwningPlayer.UnblockCapabilities(n"GameplayAction", this);		
		OwningPlayer.RemovePlayerInvulnerability(this);

		OwningPlayer.MeshOffsetComponent.ResetLocationWithTime(0.25f);

		CastleComponent.bUsingUltimate = false;

		if (BeamComp != nullptr)
		{
			BeamComp.Deactivate();
			BeamComp = nullptr;
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
		SpendUltimateCharge(DeltaTime);
		UpdateAbilityDuration(DeltaTime);
		UpdateBeamLocations();
		MovePlayer(DeltaTime);
		UpdatePlayerEffects();
		UpdateTickInterval(DeltaTime);
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
		bHitAnyEnemies = false;
		TArray<AHazeActor> HitActors = GetActorsInBox(BeamStart, BeamEnd, BeamDamageWidth, bShowDebug = false);
		TArray<ABreakableActor> Breakables = GetBreakableActorsFromArray(HitActors);
		TArray<ACastleEnemy> HitCastleEnemies = GetCastleEnemiesFromArray(HitActors);


		for (ACastleEnemy CastleEnemy : HitCastleEnemies)
		{
			float Damage = FMath::RandRange(DamagePerTickMin, DamagePerTickMax);
			bool bIsCritical = CastleComponent.IsAttackCritical(0.35f);
			if (bIsCritical)
				Damage *= CastleComponent.CriticalStrikeDamage;

			FCastleEnemyDamageEvent DamageEvent;
			DamageEvent.DamageDealt = Damage;
			DamageEvent.bIsCritical = bIsCritical;

			DamageEvent.DamageDirection = CastleEnemy.ActorLocation - OwningPlayer.ActorLocation;
			DamageEvent.DamageLocation = CastleEnemy.ActorLocation;
			DamageEvent.DamageSpeed = 900.f;
			DamageEvent.DamageSource = OwningPlayer;

			DamageCastleEnemy(OwningPlayer, CastleEnemy, DamageEvent);

			FCastleEnemyKnockbackEvent KnockbackEvent;
			KnockbackEvent.Source = OwningPlayer;
			KnockbackEvent.DurationMultiplier = 1.5f;
			KnockbackEvent.Direction = CastleEnemy.ActorLocation - OwningPlayer.ActorLocation;
			KnockbackEvent.HorizontalForce = 1.f;
			KnockbackEvent.VerticalForce = 1.f;
			CastleEnemy.KnockBack(KnockbackEvent);

			bHitAnyEnemies = true;
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

	void UpdatePlayerEffects()
	{
		if (bHitAnyEnemies)
			OwningPlayer.SetFrameForceFeedback(0.5f, 0.5f);
		else
			OwningPlayer.SetFrameForceFeedback(0.2f, 0.2f);
	}

	void UpdateAbilityDuration(float DeltaTime)
	{
		UltComp.DurationCurrent += DeltaTime;
	}

	void SpendUltimateCharge(float DeltaTime)
	{
		if (CastleComponent == nullptr)
			return;

		CastleComponent.AddUltimateCharge(-CastleComponent.UltimateChargeMax/UltComp.Duration * DeltaTime);
	}

	void UpdateBeamLocations()
	{
		BeamStart = Owner.ActorCenterLocation;
		BeamEnd = BeamStart + (Owner.ActorForwardVector * 5000.f);

		// Trace to see where the beam should end
		FHitResult Hit;
		if (System::LineTraceSingleByProfile(
			BeamStart,
			BeamEnd,
			n"PlayerCharacterIgnoreConditional",
			false, TArray<AActor>(), EDrawDebugTrace::None,
			Hit, false))
		{
			if (Hit.bBlockingHit)
			{
				BeamEnd = Hit.Location;
			}

			UltComp.bLastHitBlocking = Hit.bBlockingHit;
		}

		FVector VisualStart = OwningPlayer.Mesh.WorldLocation;
		VisualStart += FVector(0.f, 0.f, 88.f);
		VisualStart += (Owner.ActorForwardVector * 88.f);

		FVector VisualEnd = BeamEnd;
		VisualEnd.Z = VisualStart.Z;

		BeamComp.SetFloatParameter(n"User.BeamWidth", BeamVisualWidth);
		BeamComp.SetVectorParameter(n"User.BeamStart", VisualStart);
		BeamComp.SetVectorParameter(n"User.BeamEnd", VisualEnd);

		UltComp.BeamLength = (VisualEnd - VisualStart).Size();	
		UltComp.BeamEnd = VisualEnd;
	}

	void MovePlayer(float DeltaTime)
	{
		OwningPlayer.MeshOffsetComponent.OffsetLocationWithSpeed(
			InitialLocation + FVector(0.f, 0.f, 150.f),
			400.f);

		if (!MoveComp.CanCalculateMovement())
			return;

		if (HasControl())
		{
			FVector WantedFacing = GetAttributeVector(n"MovementDirection");
			if (WantedFacing.IsNearlyZero())
				WantedFacing = Owner.ActorForwardVector;

			BeamRotation.AccelerateTo(FRotator::MakeFromX(WantedFacing), 4.f, DeltaTime);

			FHazeFrameMovement Movement = MoveComponent.MakeFrameMovement(n"MageBeamUltimate");     
			Movement.SetRotation(BeamRotation.Value.Quaternion());
			Movement.OverrideCollisionProfile(n"PlayerCharacterIgnorePawn");
			MoveCharacter(Movement, n"CastleFrozenOrb");
						
			CrumbComponent.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComponent.MakeFrameMovement(n"MageBeamUltimate");
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
			MoveData.OverrideCollisionProfile(n"PlayerCharacterIgnorePawn");

			MoveCharacter(MoveData, n"CastleFrozenOrb");
		}
	}
};
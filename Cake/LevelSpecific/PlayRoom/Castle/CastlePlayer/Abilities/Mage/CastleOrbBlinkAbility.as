import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.Abilities.CastleAbilityCapability;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;

class UCastleOrbBlinkAbility : UCastleAbilityCapability
{    
    default CapabilityTags.Add(n"AbilityBlink");
	default CapabilityTags.Add(CapabilityTags::Input);
	
    default BlockExclusionTags.Add(n"CanCancelUltimate");
    default BlockExclusionTags.Add(n"CanCancelKnockdown");
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	/* Cooldown of the ability. Counted from *ending* the orb. */
    UPROPERTY()
    float Cooldown = 1.0f;

	/* Speed that the orb moves at. */
	UPROPERTY()
	float OrbSpeed = 2400.f;

	/* Rotation speed (degrees) for the orb's facing. */
	UPROPERTY()
	float OrbRotationSpeed = 500.f;

	/* Maximum distance we can move by orbing. */
    UPROPERTY()
    float MaxOrbDistance = 400.f;

	/* Maximum duration we can stay as an orb. */
	UPROPERTY()
	float MaxOrbDuration = 1.0f;

	/* Minimum duration before we can release the orb. */
	UPROPERTY()
	float MinOrbDuration = 0.2f;

	/* Target minimum distance to auto-move. */
	UPROPERTY()
	float AutoMoveMinDistance = 400.f;

	/* Distance the blink can step up */
	UPROPERTY()
    float BlinkStepUpHeight = 150.f;

	/* Class for the orb effect to spawn. */
	UPROPERTY()
	TSubclassOf<ACastleOrbEffect> OrbEffect = ACastleOrbEffect::StaticClass();

    float CooldownCurrent = 0.f;
	float Timer = 0.f;
    FVector BlinkStartLocation;
	ACastleOrbEffect Orb;
	FRotator OrbWantRotation;
	bool bMinDistanceReached = false;
	bool bWaitingForRelease = false;
	bool bLostControl = false;
	UHazeCrumbComponent CrumbComponent;
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UNiagaraSystem StartEffect;
	UNiagaraComponent StartEffectComp;

	UPROPERTY()
	UNiagaraSystem EndEffect;
	UNiagaraComponent EndEffectComp;

	default SlotName = n"Blink";
	
	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;

	UPROPERTY()
	UAkAudioEvent BlinkAudioEvent;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

        OwningPlayer = Cast<AHazePlayerCharacter>(Owner);
        MoveComponent = UHazeBaseMovementComponent::Get(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
        CastleComponent = UCastleComponent::Get(Owner);
		HazeAkComp = UHazeAkComponent::Get(OwningPlayer);

		Orb = Cast<ACastleOrbEffect>(SpawnPersistentActor(OrbEffect.Get()));
		Orb.SetActorHiddenInGame(true);
	}

    UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (Orb != nullptr)
		{
			Orb.DestroyActor();
			Orb = nullptr;
		}
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComponent.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

        if (IsActioning(ActionNames::CastleAbilityDash) && CooldownCurrent <= 0.f && !bWaitingForRelease)
            return EHazeNetworkActivation::ActivateUsingCrumb;
        else
            return EHazeNetworkActivation::DontActivate;       
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if ((!IsActioning(ActionNames::CastleAbilityDash) && Timer >= MinOrbDuration) || Timer >= MaxOrbDuration)
            return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        return EHazeNetworkDeactivation::DontDeactivate;
	}
    
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		SlotWidget.SlotActivated();
		
		Timer = 0.f;
		bMinDistanceReached = false;
		bLostControl = false;

		OwningPlayer.BlockCapabilities(n"GameplayAction", this);

        BlinkStartLocation = OwningPlayer.ActorLocation;

		CastleComponent.bIsBlinking = true;
		CastleComponent.BlinkStartLocation = BlinkStartLocation;

		StartOrbing();
		PlayActivatedAudioEvent();

		if (StartEffect != nullptr)
			StartEffectComp = Niagara::SpawnSystemAtLocation(StartEffect, Owner.ActorLocation);
	}

	void StartOrbing()
	{
        CooldownCurrent = Cooldown;

		OwningPlayer.SetActorHiddenInGame(true);
		OwningPlayer.AddPlayerInvulnerability(this);
		Orb.StartLocation = OwningPlayer.ActorLocation;
		Orb.ActorLocation = OwningPlayer.ActorLocation;
		Orb.ActorRotation = OwningPlayer.ActorRotation;
		OrbWantRotation = Orb.ActorRotation;
		Orb.StartOrbing();
		Orb.SetActorHiddenInGame(false);
	}

	void FinishOrbing()
	{
		OwningPlayer.SetActorHiddenInGame(false);
		OwningPlayer.RemovePlayerInvulnerability(this);
		Orb.FinishOrbing(OwningPlayer.ActorLocation);
		Orb.SetActorHiddenInGame(true);
		
		PlayAnimation();
		PlayBlinkAudioEvent();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		OwningPlayer.UnblockCapabilities(n"GameplayAction", this);

		FinishOrbing();

		bWaitingForRelease = IsActioning(ActionNames::CastleAbilityDash);

		CastleComponent.bIsBlinking = false;

		if (StartEffectComp != nullptr)
		{	
			StartEffectComp.Deactivate();
			StartEffectComp = nullptr;
		}

		if (EndEffect != nullptr)
			Niagara::SpawnSystemAtLocation(EndEffect, Owner.ActorLocation);
	}

    UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
    {
        if (!IsActive() && CooldownCurrent > 0)
            CooldownCurrent -= DeltaTime;

		if (SlotWidget != nullptr)
		{
			SlotWidget.CooldownDuration = Cooldown;
			SlotWidget.CooldownCurrent = CooldownCurrent;
		}

		if (bWaitingForRelease)
		{
			if (!IsActioning(ActionNames::CastleAbilityDash))
				bWaitingForRelease = false;
		}

		if (WasActionStarted(ActionNames::CastleAbilityDash))
			SlotWidget.SlotPressed();
    }

    UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
		Timer += DeltaTime;

		FVector WorldMovement = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector DeltaMove = WorldMovement.GetSafeNormal() * OrbSpeed * DeltaTime;

		Orb.OrbPercentage = Timer / MaxOrbDuration;

		float PrevDistance = Orb.ActorLocation.Distance(BlinkStartLocation);

		if (PrevDistance > AutoMoveMinDistance)
			bMinDistanceReached = true;

		if (!bLostControl && !IsActioning(ActionNames::CastleAbilityDash))
			bLostControl = true;

		if (bLostControl)
		{
			DeltaMove = OrbWantRotation.RotateVector(FVector(OrbSpeed * DeltaTime, 0.f, 0.f));
		}
		else if (DeltaMove.IsNearlyZero())
		{
			if(!bMinDistanceReached)
				DeltaMove = OrbWantRotation.RotateVector(FVector(OrbSpeed * DeltaTime, 0.f, 0.f));
		}
		else
		{
			OrbWantRotation = Math::MakeRotFromX(DeltaMove);
			bMinDistanceReached = true;
		}

		FVector NewPosition = Owner.ActorLocation + DeltaMove;
		FVector Offset = NewPosition - BlinkStartLocation;
		float Distance = Offset.Size();

		if (Distance > MaxOrbDistance)
			NewPosition = BlinkStartLocation + (Offset * (MaxOrbDistance / Distance));

		if (MoveComponent.CanCalculateMovement())
		{
			FHazeFrameMovement Movement = MoveComponent.MakeFrameMovement(n"CastleOrbBlink");

			if (HasControl())
			{
				Movement.OverrideStepUpHeight(100.f);
				Movement.OverrideStepDownHeight(0.f);

				Movement.ApplyDelta(NewPosition - Owner.ActorLocation);
				Movement.FlagToMoveWithDownImpact();
				Movement.ApplyTargetRotationDelta();

				MoveComponent.SetTargetFacingRotation(OrbWantRotation);
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
				Movement.ApplyConsumedCrumbData(ConsumedParams);
			}

			Movement.OverrideCollisionProfile(n"PlayerCharacterIgnoreConditional");
			MoveComponent.Move(Movement);

			Orb.ActorLocation = Owner.ActorLocation;
			Orb.ActorRotation = Owner.ActorRotation;
		}

		Orb.Update(DeltaTime);

		CrumbComponent.LeaveMovementCrumb();
    }

	void PlayAnimation()
	{       
		if (CastleComponent.MageAnimationData == nullptr)
			return;		

		FCastleAbilityAnimation AttackAnimData = CastleComponent.MageAnimationData.BlinkExit;

        if (AttackAnimData.Animation != nullptr)
		{
			FHazeSlotAnimSettings AnimSettings;
			AnimSettings.BlendTime = AttackAnimData.AnimationSettings.BlendTime;
			AnimSettings.PlayRate = AttackAnimData.AnimationSettings.PlayRate;

			OwningPlayer.PlaySlotAnimation(AttackAnimData.Animation, AnimSettings);
		}			
	}

	void PlayActivatedAudioEvent()
	{
		if (ActivatedAudioEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(ActivatedAudioEvent);
		}
	}


	void PlayBlinkAudioEvent()
	{
		if (BlinkAudioEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(BlinkAudioEvent);
		}
	}
}

class ACastleOrbEffect : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float OrbPercentage = 0.f;

	UPROPERTY()
	FVector StartLocation;

	UFUNCTION(BlueprintEvent)
	void StartOrbing()
	{
	}

	UFUNCTION(BlueprintEvent)
	void FinishOrbing(FVector TargetLocation)
	{
	}

	UFUNCTION(BlueprintEvent)
	void Update(float DeltaTime)
	{
	}

	UFUNCTION()
	void StretchTowardsStart(FVector Origin, USceneComponent Comp, bool bCenter = true)
	{
		float Distance = Origin.Distance(StartLocation);
		FVector Offset = StartLocation - Origin;
		FRotator Rotation = Math::MakeRotFromZ(Offset);

		if (bCenter)
		{
			Comp.WorldLocation = Origin + Offset * 0.5f;
		}

		FVector NewScale = Comp.WorldScale;
		NewScale.Z = Distance / 100.f;
		Comp.SetWorldScale3D(NewScale);

		Comp.SetWorldRotation(Rotation);
	}
};
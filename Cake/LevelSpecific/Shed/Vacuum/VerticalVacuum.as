import Cake.LevelSpecific.Shed.Vacuum.VacuumStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;

event void FEnteredExhaust(AHazePlayerCharacter Player);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AVerticalVacuum : AHazeActor
{
	
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BlowEffectActivateAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SuckEffectActivateAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent FanLoopActivateAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerEnterVacuumAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerExitVacuumAudioEvent;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachmentPoint;
	default AttachmentPoint.Mobility = EComponentMobility::Static;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent ExhaustStart;
    default ExhaustStart.RelativeLocation = FVector(0.f, 0.f, 250.f);

    UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
    UStaticMeshComponent FanHead;
    default FanHead.RelativeRotation = FRotator(0.f, 0.f, -90.f);
	default FanHead.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
	UStaticMeshComponent FanInterior;
	default FanInterior.RelativeRotation = FRotator(0.f, 0.f, -90.f);
	default FanInterior.SetLightingChannels(false, true, false);

    UPROPERTY(DefaultComponent, Attach = FanHead)
    UStaticMeshComponent Fan;
	
	UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
	UCapsuleComponent Exhaust;
	default Exhaust.CapsuleRadius = 180.f;
	default Exhaust.CapsuleHalfHeight = CapsuleLength;
	default Exhaust.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
	UNiagaraComponent BlowEffect;

	UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
	UNiagaraComponent SuckEffect;

	UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
	UStaticMeshComponent KillTrigger;

	UPROPERTY(DefaultComponent, Attach = AttachmentPoint)
	UPointLightComponent DirectionLight;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.f;

	UPROPERTY(Category = "Properties", Meta = (MakeEditWidget))
	FVector TopLocation = FVector(0.f, 0.f, 1000.f);

	UPROPERTY(Category = "Properties")
	float CapsuleLength = 600.f;

	UPROPERTY(Category = "Properties")
	EVacuumMode VacuumMode;

	UPROPERTY(Category = "Properties")
	bool bActive = true;

	UPROPERTY(EditDefaultsOnly, Category = "Properties")
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

    float MaximumRotationSpeed = 10.f;
    float DesiredRotationSpeed;
    float CurrentRotationSpeed;

	UPROPERTY()
	FEnteredExhaust OnEnteredExhaust;

	UPROPERTY()
	bool bAutoSetCapsuleOffset = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Exhaust.OnComponentBeginOverlap.AddUFunction(this, n"EnterExhaust");
		Exhaust.OnComponentEndOverlap.AddUFunction(this, n"ExitExhaust");

		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterKillTrigger");

		if (VacuumMode == EVacuumMode::Blow)
		{
			CurrentRotationSpeed = MaximumRotationSpeed;
			HazeAkComp.HazePostEvent(BlowEffectActivateAudioEvent);
		}
		else
		{
			CurrentRotationSpeed = -MaximumRotationSpeed;
			HazeAkComp.HazePostEvent(SuckEffectActivateAudioEvent);
		}

		DesiredRotationSpeed = CurrentRotationSpeed;

		HazeAkComp.HazePostEvent(FanLoopActivateAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bActive)
			return;

		CurrentRotationSpeed = FMath::FInterpTo(CurrentRotationSpeed, DesiredRotationSpeed, DeltaTime, 3.f);
		Fan.AddLocalRotation(FRotator(CurrentRotationSpeed, 0.f, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterExhaust(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			Player.PlayerHazeAkComp.HazePostEvent(PlayerEnterVacuumAudioEvent);
			Player.SetCapabilityAttributeObject(n"VerticalVacuum", this);
			Player.SetCapabilityActionState(n"VerticalVacuum", EHazeActionState::Active);
			
			Player.BlockCapabilities(MovementSystemTags::Jump, this);
			Player.UnblockCapabilities(MovementSystemTags::Jump, this);

			Player.BlockCapabilities(MovementSystemTags::Dash, this);
			Player.UnblockCapabilities(MovementSystemTags::Dash, this);

			Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void ExitExhaust(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if(Player != nullptr)
		{
			Player.PlayerHazeAkComp.HazePostEvent(PlayerExitVacuumAudioEvent);
			Player.SetCapabilityActionState(n"VerticalVacuum", EHazeActionState::Inactive);
			Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		}
    }

	UFUNCTION(NotBlueprintCallable)
	void EnterKillTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (VacuumMode == EVacuumMode::Blow)
			return;

		KillPlayer(Player, DeathEffect);
	}

	UFUNCTION()
	void ChangeDirection()
	{
		switch (VacuumMode)
		{
		case EVacuumMode::Suck:
			VacuumMode = EVacuumMode::Blow;
			BlowEffect.Activate(true);
			SuckEffect.Deactivate();
			HazeAkComp.HazePostEvent(BlowEffectActivateAudioEvent);
			DirectionLight.SetLightColor(FLinearColor(0.f, 1.f, 0.f));
		break;
		case EVacuumMode::Blow:
			VacuumMode = EVacuumMode::Suck;
			SuckEffect.Activate(true);
			BlowEffect.Deactivate();
			HazeAkComp.HazePostEvent(SuckEffectActivateAudioEvent);
			DirectionLight.SetLightColor(FLinearColor(1.f, 0.f, 0.f));
		break;
		}
		
		DesiredRotationSpeed = -DesiredRotationSpeed;
	}
  
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		UpdateCapsulePositions();
		UpdateEffectVisibility();
	}

	void UpdateCapsulePositions()
	{
		Exhaust.SetCapsuleHalfHeight(CapsuleLength);
		float CapsuleOffset = ((CapsuleLength + 130.f));
		if (bAutoSetCapsuleOffset)
			Exhaust.SetRelativeLocation(FVector(0.f, 0.f, CapsuleOffset));
	}

	void UpdateEffectVisibility()
	{
		if(VacuumMode == EVacuumMode::Blow)
		{
			BlowEffect.SetAutoActivate(true);
			SuckEffect.SetAutoActivate(false);
			DirectionLight.SetLightColor(FLinearColor(0.f, 1.f, 0.f));
		}
		else
		{
			BlowEffect.SetAutoActivate(false);
			SuckEffect.SetAutoActivate(true);
			DirectionLight.SetLightColor(FLinearColor(1.f, 0.f, 0.f));
		}
	}
}
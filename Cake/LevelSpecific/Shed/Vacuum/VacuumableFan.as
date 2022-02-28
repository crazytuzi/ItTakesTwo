import Cake.LevelSpecific.Shed.Vacuum.VacuumableComponent;
import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Vino.PlayerHealth.PlayerHealthStatics;
import Peanuts.Audio.AudioStatics;

class AVacuumableFan : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent FanMesh;
    default FanMesh.StaticMesh = Asset("/Game/Environment/Props/Fantasy/Shed/Structure/Ventilation_Fan_01.Ventilation_Fan_01");
    default FanMesh.RelativeScale3D = FVector(2.f, 2.f, 2.f);
	default FanMesh.LDMaxDrawDistance = 12000.f;

    UPROPERTY(DefaultComponent, Attach = Root)
    USphereComponent TriggerSphere;
    default TriggerSphere.SphereRadius = 350.f;
    default TriggerSphere.RelativeLocation = FVector(70.f, 0.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent KillCylinder;
    default KillCylinder.StaticMesh = Asset("/Engine/BasicShapes/Cylinder.Cylinder");
    default KillCylinder.RelativeRotation = FRotator(90.f, 0.f, 0.f);
    default KillCylinder.RelativeLocation = FVector(70.f, 0.f, 0.f);
    default KillCylinder.RelativeScale3D = FVector(8.5f, 8.5f, 0.5f);
    default KillCylinder.bHiddenInGame = true;
    default KillCylinder.bVisible = false;
    default KillCylinder.CollisionProfileName = n"PlayerCharacterOverlapOnly";

    UPROPERTY(DefaultComponent)
    UVacuumableComponent VacuumableComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bRenderWhileDisabled = true;
	default DisableComp.AutoDisableRange = 5000.f;

    UPROPERTY()
    bool bActiveFromStart = false;

    UPROPERTY()
    AVacuumHoseActor InitialHose;

    UPROPERTY()
    EVacuumMountLocation ExhaustLocation;

    UPROPERTY()
    float MaximumRotationSpeed = -200.f;
    float DesiredRotationSpeed;
    float CurrentRotationSpeed;

    float InterpSpeed = 0.5f;
    float MinInterpSpeed = 0.2f;
    float MaxInterpSpeed = 2.f;	

    UPROPERTY()
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UAkAudioEvent PlayVacuumableFanLoopingEvent;	

	UPROPERTY()
	UAkAudioEvent StopVacuumableFanLoopingEvent;

	bool bStartedPlayingAudio = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        VacuumableComponent.OnStartVacuuming.AddUFunction(this, n"StartVacuuming");
        VacuumableComponent.OnEndVacuuming.AddUFunction(this, n"StopSpinning");

        KillCylinder.OnComponentBeginOverlap.AddUFunction(this, n"EnterFan");

        if (InitialHose != nullptr && HasControl())
        {
			InitialHose.NetAddActorToExhaust(this, ExhaustLocation);
        }

        if (bActiveFromStart)
            StartSpinning();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        CurrentRotationSpeed = FMath::FInterpTo(CurrentRotationSpeed, DesiredRotationSpeed, DeltaTime, InterpSpeed);
        InterpSpeed = InterpSpeed + (DeltaTime * 0.1);
        InterpSpeed = FMath::Clamp(InterpSpeed, MinInterpSpeed, MaxInterpSpeed);

        FRotator RotationRate = FRotator(0.f, 0.f, CurrentRotationSpeed * DeltaTime);
        FanMesh.AddLocalRotation(RotationRate);
    }

    UFUNCTION()
    void SwapDirection()
    {
        DesiredRotationSpeed *= -1;
        MaximumRotationSpeed *= 1;
        CurrentRotationSpeed /= 2;
        InterpSpeed = MinInterpSpeed;
    }

    UFUNCTION()
    void StartVacuuming(USceneComponent Nozzle)
    {
        StartSpinning();
    }

    UFUNCTION()
    void StartSpinning()
    {
        DesiredRotationSpeed = MaximumRotationSpeed;
        InterpSpeed = MaxInterpSpeed;
		
		if(HazeAkComp.IsGameObjectRegisteredWithWwise() && !bStartedPlayingAudio)
		{
			HazeAkComp.HazePostEvent(PlayVacuumableFanLoopingEvent);
			bStartedPlayingAudio = true;
		}
    }

    UFUNCTION()
    void StopSpinning()
    {
        DesiredRotationSpeed = 0.f;
        InterpSpeed = MaxInterpSpeed;	

		if(HazeAkComp.IsGameObjectRegisteredWithWwise())
		{
			HazeAkComp.HazePostEvent(StopVacuumableFanLoopingEvent);
			bStartedPlayingAudio = false;
		}
		
		HazeAkComp.ClearQueuedEvents();
    }

    UFUNCTION()
    void EnterFan(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr && FMath::Abs(CurrentRotationSpeed) >= FMath::Abs(MaximumRotationSpeed/1.5))
        {
            KillPlayer(Player, DeathEffect);
        }
    }
}
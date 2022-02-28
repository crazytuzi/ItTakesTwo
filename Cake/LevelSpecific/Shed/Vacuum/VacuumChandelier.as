import Cake.LevelSpecific.Shed.Vacuum.VacuumableComponent;
import Peanuts.Audio.AudioStatics;

class AVacuumChandelier : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Chandelier;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartWeatherVaneAudioEvent;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SyncRotation; 

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.f;

    UPROPERTY()
    float CurrentRotationRate;

    UPROPERTY()
    float DesiredRotationRate;

    UPROPERTY()
    float MaximumRotation;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		HazeAkComp.HazePostEvent(StartWeatherVaneAudioEvent);
		if (HasControl())
			SyncRotation.Value = ActorRotation;
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
        if(HasControl())
        {
            CurrentRotationRate = FMath::FInterpTo(CurrentRotationRate, DesiredRotationRate, Delta, 2.f);
			if (CurrentRotationRate > 0.f)
				AddActorLocalRotation(FRotator(0.f, CurrentRotationRate, 0.f));
			SyncRotation.Value = ActorRotation;
        }
        else
        {
			float PreviousYaw = ActorRotation.Yaw;
			if (!SyncRotation.Value.Equals(ActorRotation, 0.01f)) 
			{
				SetActorRotation(SyncRotation.Value);
			}
			CurrentRotationRate = ActorRotation.Yaw - PreviousYaw;
        }
		HazeAkComp.SetRTPCValue("Rtpc_Platform_Shed_Vacuum_WeatherVane_Rotation", CurrentRotationRate);
    }
}
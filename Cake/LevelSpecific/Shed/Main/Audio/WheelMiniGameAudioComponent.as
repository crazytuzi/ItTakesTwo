import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Shed.Main.WheelHatch;

class UWheelMiniGameAudioComponent : UActorComponent
{	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartButtonHitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MachineStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MachineSpeedupEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MachineStopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent AllHatchesFlipUpEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HatchHitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HatchFlipUpEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformDropEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartButtonResetEvent;

	UHazeAkComponent WheelHazeAkComp;
	UHazeAkComponent PlatformHazeAkComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WheelHazeAkComp = UHazeAkComponent::GetOrCreateHazeAkComponent(Cast<AHazeActor>(Owner), NAME_None, true, true);
	}

	UFUNCTION()
	void PlayStartButtonHit()
	{
		WheelHazeAkComp.HazePostEvent(StartButtonHitEvent);
	}

	UFUNCTION()
	void PlayStartButtonReset(FTransform ButtonTrans)
	{
		UHazeAkComponent::HazePostEventFireForget(StartButtonResetEvent, ButtonTrans);
	}


	UFUNCTION()
	void StartMachineAudio()
	{
		WheelHazeAkComp.HazePostEvent(MachineStartEvent);
	}

	UFUNCTION()
	void MinigameFinished()
	{
		WheelHazeAkComp.HazePostEvent(MachineStopEvent);
		WheelHazeAkComp.HazePostEvent(PlatformDropEvent);
	}

	UFUNCTION()
	void PlayHatchHit(AHazePlayerCharacter Player)
	{
		HazeAudio::SetPlayerPanning(WheelHazeAkComp, Player);

		WheelHazeAkComp.HazePostEvent(HatchHitEvent);
	}

	UFUNCTION()
	void PlayHatchFlipUp(AWheelHatch Hatch)
	{
		Hatch.HatchAkComp.HazePostEvent(HatchFlipUpEvent);
	}

	UFUNCTION()
	void PlayAllHatchesFlipUp()
	{
		WheelHazeAkComp.HazePostEvent(AllHatchesFlipUpEvent);
	}

	UFUNCTION()
	void PlayMachineSpeedup()
	{
		WheelHazeAkComp.HazePostEvent(MachineSpeedupEvent);
	}
}
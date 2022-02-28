
import Vino.Checkpoints.Volumes.DeathVolume;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.JumpToBlenderActor;

class AMixer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent RotatingRoot;
	UPROPERTY(DefaultComponent, Attach = RotatingRoot)	
	UStaticMeshComponent RotatingMesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent ButtonRoot;
	UPROPERTY(DefaultComponent, Attach = ButtonRoot)	
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000.f;
	
	UPROPERTY()
	ADeathVolume DeathTrigger;
	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopAudioEvent;

	FHazeAcceleratedFloat AcceleratedFloatButton;
	float TargetRotationButton;

	bool MixerActive;
	UPROPERTY()
	float AutoDisableTimer = 15.f;
	float AutoDisableTimerTemp;

	bool bRotationAllowed = false;
	FHazeAcceleratedFloat AcceleratedFloat;
	float TargetRotationSpeed;

	UPROPERTY()
	AJumpToBlenderActor JumpToBlenderActor;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//PrintToScreen("TargetRotationButton " + TargetRotationButton);
		AcceleratedFloatButton.SpringTo(TargetRotationButton, 600, 0.9, DeltaSeconds);
		FRotator RelativeRotationButton;
		RelativeRotationButton.Roll = AcceleratedFloatButton.Value;
		ButtonMesh.SetRelativeRotation(RelativeRotationButton);

		if(MixerActive)
		{
			AutoDisableTimerTemp -= DeltaSeconds;
			if(AutoDisableTimerTemp <0)
			{
				if(HasControl())
				{
					ButtonAutoDisable();
				}
			}
		}
		if(bRotationAllowed)
		{
			AcceleratedFloat.SpringTo(TargetRotationSpeed, 20, 0.9, DeltaSeconds);
			RotatingRoot.AddLocalRotation(FRotator(0, AcceleratedFloat.Value * DeltaSeconds * 10, 0));
		}
	}

	UFUNCTION()
	void DisableRotation()
	{
		if(MixerActive)
			return;

		bRotationAllowed = false;
	}

	UFUNCTION(NetFunction)
	void ButtonAutoDisable()
	{
		ButtonPressed();
	}

	UFUNCTION()
	void ButtonPressed()
	{
		TargetRotationButton = TargetRotationButton - 180;

		if(MixerActive == false)
		{
			JumpToBlenderActor.ChangeBlenderState(true);
			bRotationAllowed = true;
			TargetRotationSpeed = 200;
			MixerActive = true;
			DeathTrigger.EnableDeathVolume();
			AutoDisableTimerTemp = AutoDisableTimer;
			HazeAkComp.HazePostEvent(StartAudioEvent);
		}
		else if(MixerActive == true)
		{
			JumpToBlenderActor.ChangeBlenderState(false);
			TargetRotationSpeed = 0;
			MixerActive = false;
			DeathTrigger.DisableDeathVolume();
			HazeAkComp.HazePostEvent(StopAudioEvent);
			System::SetTimer(this, n"DisableRotation", 1.0f, false);
		}
	}
}


import Peanuts.Audio.AudioStatics;
event void FOnWheelSpin(AHazePlayerCharacter Player);

class APirateShipWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent ButtonRoot;

	UPROPERTY(DefaultComponent, Attach = ButtonRoot)	
	UStaticMeshComponent ButtonMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayWheelSpinAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopWheelSpinAudioEvent;

	bool bWheelIsMoving = false;

	FOnWheelSpin OnWheelSpin;

	bool bAllowTick;

	FHazeAcceleratedFloat AcceleratedFloat;

	float RotationVelocity = 1;
	float FuturePitch;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bAllowTick)
			return;

		if(RotationVelocity > 0)
		{
			RotationVelocity -= 1.25f * (DeltaSeconds * 62);
			FuturePitch = GetActorRotation().Pitch + RotationVelocity * DeltaSeconds;
			AcceleratedFloat.SpringTo(FuturePitch, 5000, 1, DeltaSeconds);
		}
		else
		{
			RotationVelocity = 0;
			FuturePitch = 0;
			AcceleratedFloat.SpringTo(FuturePitch, 10, 1, DeltaSeconds);
		}
		
		ButtonMesh.AddLocalRotation(FRotator(0, 0, -AcceleratedFloat.Value));
		
		float NormalizedRotation = HazeAudio::NormalizeRTPC01(FMath::Abs(AcceleratedFloat.Value), 0.f, 13.f);
		HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Snowglobe_Interactions_PirateShipWheel_Rotation", NormalizedRotation);
		
		if(bWheelIsMoving && AcceleratedFloat.Value == 0.f)
		{
			HazeAkComp.HazePostEvent(StopWheelSpinAudioEvent);
			bWheelIsMoving = false;
		}
	}

	UFUNCTION()
	void ButtonPressed(AHazePlayerCharacter Player)
	{
		bAllowTick = true;

		if(!bWheelIsMoving)
		{
			HazeAkComp.HazePostEvent(PlayWheelSpinAudioEvent);
		}
		bWheelIsMoving = true;

		OnWheelSpin.Broadcast(Player);

		if(RotationVelocity > 600)
			RotationVelocity += 25;
		else if(RotationVelocity >= 400 && RotationVelocity < 600)
			RotationVelocity += 50;
		else if(RotationVelocity >= 200 && RotationVelocity < 400)
			RotationVelocity += 100;
		else if(RotationVelocity < 200)
			RotationVelocity += 225;
	}
}


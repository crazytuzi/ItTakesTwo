import Vino.Interactions.InteractionComponent;
import Peanuts.Audio.AudioStatics;

event void FInteractedWithKaleidoscope();

enum EKaleidoscopeColor
{  
    Red,
	Yellow,
	Blue
};

//audio hit clamp to add on reach min and max rotation :
//UAkAudioEvent RotatingKaleidoscopeHitClamppAudioEvent;


class ARotatingKaleidoscope : AHazeActor
{
    UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeRedStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeRedStopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeYellowStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeYellowStopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeBlueStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeBlueStopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RotatingKaleidoscopeHitClamppAudioEvent;
	
	UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Cylinder;

	UPROPERTY(DefaultComponent, Attach = Cylinder)
	USceneComponent HandleLocation;

	UPROPERTY(DefaultComponent, Attach = Cylinder)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent AttachComponent;
	default AttachComponent.RelativeLocation = FVector(480.f, -90.f, -25.f);
	default AttachComponent.RelativeRotation = FRotator(0.f, -90.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = AttachComponent)
	USkeletalMeshComponent EditorSkelMesh;
	default EditorSkelMesh.bHiddenInGame = true;
	default EditorSkelMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY()
	float RotationMultiplier;
	default RotationMultiplier = 35.f;

	UPROPERTY()
	EKaleidoscopeColor KaleidoscopeColor;

	UPROPERTY()
	TArray<UMaterialInstance> MaterialArray;

	UPROPERTY()
	TSubclassOf<UHazeCapability> KaleidoscopeCapability;

	UPROPERTY()
	bool bIsRotating;

	UPROPERTY()
	FInteractedWithKaleidoscope InteractedWithKaleidoscope;
	
	bool bInteractedWith;

	bool bHasHitStop = false;
	bool bHasStartedAudio = false;
	bool bHasBeenMoved = false;

	AHazePlayerCharacter PlayerUsingKaleidoscope;

	float CurrentYaw;
	float TargetYaw;

	float RotationDelta = 0.f;
	float YawLastTick = 0.f;

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionCompActivated");
		CurrentYaw = ActorRotation.Yaw;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float Delta)
	{		
		RotationDelta = CurrentYaw - YawLastTick;	
		YawLastTick = CurrentYaw;	
		HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_Kaleidoscope_Rotation", RotationDelta);

		if (!bInteractedWith && CurrentYaw > 0.f)
		{	
			float YawToApply = CurrentYaw - RotationMultiplier * ActorDeltaSeconds;
			if (YawToApply > 0.f)
			{
				CurrentYaw = YawToApply;
				bHasHitStop = false;
				StartAudio();
			}
			else if(YawToApply <= 0.f)
			{
				CurrentYaw = 0.f; 
				HitStop();
				StopAudio();
			}
		
			SetActorRotation(FRotator(0.f, CurrentYaw, 0.f));
			TargetYaw = CurrentYaw;			
		}

		if (PlayerUsingKaleidoscope != nullptr && !PlayerUsingKaleidoscope.HasControl())
		{
			CurrentYaw = FMath::FInterpConstantTo(CurrentYaw, TargetYaw, Delta, RotationMultiplier);
			UpdateAudio(CurrentYaw);
			SetActorRotation(FRotator(0.f, CurrentYaw, 0.f));
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Cylinder.SetMaterial(0, MaterialArray[KaleidoscopeColor]);
	}

	UFUNCTION()
	void InteractionCompActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		SetInteractionCompEnabled(false);
		Player.SetCapabilityActionState(n"PushingKaleidoscope", EHazeActionState::Active);
		Player.SetCapabilityAttributeObject(n"RotatingKaleidoscope", this);
		Player.SetCapabilityAttributeObject(n"AttachComp", AttachComponent);
		bInteractedWith = true;
		Player.AddCapability(KaleidoscopeCapability);
		InteractedWithKaleidoscope.Broadcast();

		PlayerUsingKaleidoscope = Player;
	}

	UFUNCTION()
	void HandleInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
	{		
		Player.SetCapabilityActionState(n"PushingKaleidoscope", EHazeActionState::Active);
		Player.SetCapabilityAttributeObject(n"RotatingKaleidoscope", this);
		Player.SetCapabilityAttributeObject(n"AttachComp", AttachComponent);
		bInteractedWith = true;
		Player.AddCapability(KaleidoscopeCapability);

		PlayerUsingKaleidoscope = Player;
	}

	void SetInteractionCompEnabled(bool bEnabled)
	{
		bEnabled ? InteractionComp.Enable(n"PlayerInteracted") : InteractionComp.Disable(n"PlayerInteracted");
	}

	void StoppedInteracting()
	{
		bInteractedWith = false;
		SetInteractionCompEnabled(true);
		PlayerUsingKaleidoscope = nullptr;
	}

	void SetPlayerInput(AHazePlayerCharacter Player, float Input)
	{
		RotateKaleidoscope(Input);
	}

	void UpdateAudio(float YawToApply)
	{
		if (YawToApply < 180.f && YawToApply >= 0.f)
		{
			bHasHitStop = false;
			StartAudio();
		}
		else if(YawToApply >= 180.f)
		{
			HitStop();
			StopAudio();
		}
		else if(YawToApply <= 0.f)
		{
			HitStop();
			StopAudio();
		}
	}

	void RotateKaleidoscope(float Input)
	{		
		if (PlayerUsingKaleidoscope == nullptr || !PlayerUsingKaleidoscope.HasControl())
			return;
		
		float InputMultiplier;

		if (Input < -0.15f)
			InputMultiplier = -1.f;
		else if (Input > 0.15f)
			InputMultiplier = 1.f;
		else
			InputMultiplier = 0.f;		

		float YawToApply = CurrentYaw - InputMultiplier * RotationMultiplier * ActorDeltaSeconds;

		CurrentYaw = FMath::Clamp(YawToApply, 0., 180.f);
		UpdateAudio(CurrentYaw);
		bIsRotating = true; 

		SetActorRotation(FRotator(0.f, CurrentYaw, 0.f));
		NetSetTargetYaw(CurrentYaw);
	}

	void HitStop()
	{
		if (!bHasHitStop && bHasBeenMoved)
		{
			bHasHitStop = true;
			HazeAkComp.HazePostEvent(RotatingKaleidoscopeHitClamppAudioEvent);
		}
	}

	void StartAudio()
	{
		if (!bHasHitStop && !bHasStartedAudio)
		{
			bHasStartedAudio = true;

			switch (KaleidoscopeColor)
			{
				case EKaleidoscopeColor::Blue:
					HazeAkComp.HazePostEvent(RotatingKaleidoscopeBlueStartAudioEvent);
					break;

				case EKaleidoscopeColor::Red:
					HazeAkComp.HazePostEvent(RotatingKaleidoscopeRedStartAudioEvent);
					break;

				case EKaleidoscopeColor::Yellow:
					HazeAkComp.HazePostEvent(RotatingKaleidoscopeYellowStartAudioEvent);
					break;
			}
		}
	}

	void StopAudio()
	{
		if (bHasHitStop && bHasStartedAudio)
		{
			bHasStartedAudio = false;

			switch (KaleidoscopeColor)
			{
				case EKaleidoscopeColor::Blue:
					HazeAkComp.HazePostEvent(RotatingKaleidoscopeBlueStopAudioEvent);
					break;

				case EKaleidoscopeColor::Red:
					HazeAkComp.HazePostEvent(RotatingKaleidoscopeRedStopAudioEvent);
					break;

				case EKaleidoscopeColor::Yellow:
					HazeAkComp.HazePostEvent(RotatingKaleidoscopeYellowStopAudioEvent);
					break;
			}
		}
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSetTargetYaw(float NewTargetYaw)
	{
		TargetYaw = NewTargetYaw;

		if (!bHasBeenMoved && TargetYaw > 3.f)
		{
			bHasBeenMoved = true;
		}
	}
}
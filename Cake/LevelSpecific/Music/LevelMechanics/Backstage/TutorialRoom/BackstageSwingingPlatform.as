
class ABackstageSwingingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SceneMasterComp;
	UPROPERTY(DefaultComponent, Attach = SceneMasterComp)
	USceneComponent SceneMoveComp;
	UPROPERTY(DefaultComponent, Attach = SceneMoveComp)
	USceneComponent SceneRotateComp;
	UPROPERTY(DefaultComponent, Attach = SceneRotateComp)
	UStaticMeshComponent PlatformMesh;
	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UStaticMeshComponent StringMesh1;
	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UStaticMeshComponent StringMesh2;
	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UStaticMeshComponent StringMesh3;
	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UStaticMeshComponent StringMesh4;

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformMoveAudioEvent;

	UPROPERTY()
	AHazeCameraVolume CameraVolume;
	bool bStartMoving = false;
	float fInterpFloatYaw;
	float fInterpFloatRoll;
	float fInterpFloatPitch;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SyncRotationComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStartMoving)
		{
			if(HasControl())
			{
				TickMovement(DeltaSeconds);
				SyncRotationComp.Value = SceneRotateComp.GetRelativeRotation();
			}
			else
			{	
				SceneRotateComp.SetRelativeRotation(FRotator(SyncRotationComp.Value));
				float PitchNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-11, 11),FVector2D(-1, 1.f), SyncRotationComp.Value.Pitch);
				HazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_SwingingPlatform_Pitch", PitchNormalized);
			}
		}
	}

	void TickMovement(float DeltaSeconds)
	{
		FRotator RelativeRotation;
		RelativeRotation.Yaw = FMath::Sin(Time::GameTimeSeconds * 1.25f) * 3.5f;
		//RelativeRotation.Roll = FMath::Sin(Time::GameTimeSeconds * 1.4f) * 3.f;
		RelativeRotation.Pitch = FMath::Sin(Time::GameTimeSeconds * 1.f) * 6.f;

		fInterpFloatYaw = FMath::FInterpTo(fInterpFloatYaw, RelativeRotation.Yaw, DeltaSeconds, 3.f);
		fInterpFloatRoll = FMath::FInterpTo(fInterpFloatRoll, RelativeRotation.Roll, DeltaSeconds, 3.f);
		fInterpFloatPitch = FMath::FInterpTo(fInterpFloatPitch, RelativeRotation.Pitch, DeltaSeconds, 3.f);
		
		SceneRotateComp.SetRelativeRotation(FRotator(fInterpFloatPitch, fInterpFloatYaw, fInterpFloatRoll));

		float PitchNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-11, 11),FVector2D(-1, 1.f), fInterpFloatPitch);
		HazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Platform_SwingingPlatform_Pitch", PitchNormalized);
		//PrintToScreen("platform pitch normalized : " + PitchNormalized);
	}

	UFUNCTION()
	void StartPlatform()
	{
		bStartMoving = true;
		HazeAkComp.HazePostEvent(PlatformMoveAudioEvent);
	}
}


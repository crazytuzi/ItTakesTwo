
class ABackstageSwingingWallSlidePlatform : AHazeActor
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

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncRotationComponent SmoothSyncRotator;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SmoothSyncVector;

	UPROPERTY()
	AHazeCameraVolume CameraVolume;
	bool bStartMoving = false;
	float fInterpFloatYaw;
	float fInterpFloatRoll;
	float fInterpLocation;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CameraVolume.AttachToComponent(PlatformMesh, n"NAME_None", EAttachmentRule::KeepWorld);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStartMoving)
		{
			FVector RelativeLocation;
			RelativeLocation.Y = FMath::Sin(Time::GameTimeSeconds * 0.7f) * 400.f - 400;
			fInterpLocation = FMath::FInterpTo(fInterpLocation, RelativeLocation.Y, DeltaSeconds, 2.f);
			SceneMoveComp.SetRelativeLocation(FVector(0, fInterpLocation, 0));
			
			FRotator RelativeRotation;
			RelativeRotation.Yaw = FMath::Sin(Time::GameTimeSeconds * 0.7f) * 12.f - 12;
			RelativeRotation.Roll = FMath::Sin(Time::GameTimeSeconds * 1.4f) * 3.f;

			fInterpFloatYaw = FMath::FInterpTo(fInterpFloatYaw, RelativeRotation.Yaw, DeltaSeconds, 2.f);
			fInterpFloatRoll = FMath::FInterpTo(fInterpFloatRoll, RelativeRotation.Roll, DeltaSeconds, 2.f);
			SceneRotateComp.SetRelativeRotation(FRotator(0, fInterpFloatYaw, fInterpFloatRoll));
		}
	}

	UFUNCTION()
	void StartPlatform()
	{
		if(this.HasControl())
		{
			NetStartPlatform();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartPlatform()
	{
		bStartMoving = true;
	}
}



class RotatingMobileActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CoreRotationRoot;

	UPROPERTY(DefaultComponent, Attach = CoreRotationRoot)
	UStaticMeshComponent CoreMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent InnerRotationRoot;

	UPROPERTY(DefaultComponent, Attach = InnerRotationRoot)
	UStaticMeshComponent InnerMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent MiddleRotationRoot;

	UPROPERTY(DefaultComponent, Attach = MiddleRotationRoot)
	UStaticMeshComponent MidMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent OuterRotationRoot;

	UPROPERTY(DefaultComponent, Attach = OuterRotationRoot)
	UStaticMeshComponent OuterMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 6000.f;

	UPROPERTY(Category = "Settings")
	float CoreRotationSpeed = 15.f;
	UPROPERTY(Category = "Settings")
	float InnerRotationSpeed = 10.f;
	UPROPERTY(Category = "Settings")
	float MiddleRotationSpeed = 6.6f;
	UPROPERTY(Category = "Settings")
	float OuterRotationSpeed = 3.3f;

	float CoreInitialYaw = 0.f;
	float InnerInitialYaw = 0.f;
	float MiddleInitialYaw = 0.f;
	float OuterInitialYaw = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CoreInitialYaw = CoreRotationRoot.RelativeRotation.Yaw;
		InnerInitialYaw = InnerRotationRoot.RelativeRotation.Yaw;
		MiddleInitialYaw = MiddleRotationRoot.RelativeRotation.Yaw;
		OuterInitialYaw = OuterRotationRoot.RelativeRotation.Yaw;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		RotateLayers(DeltaTime);
	}

	void RotateLayers(float DeltaTime)
	{
		float YawToAdd = CoreRotationSpeed * DeltaTime;
		CoreRotationRoot.AddLocalRotation(FRotator(0.f, YawToAdd, 0.f));

		YawToAdd = InnerRotationSpeed * DeltaTime;
		InnerRotationRoot.AddLocalRotation(FRotator(0.f, YawToAdd, 0.f));

		YawToAdd = MiddleRotationSpeed * DeltaTime;
		MiddleRotationRoot.AddLocalRotation(FRotator(0.f, YawToAdd, 0.f));

		YawToAdd = OuterRotationSpeed * DeltaTime;
		OuterRotationRoot.AddLocalRotation(FRotator(0.f, YawToAdd, 0.f));
	}

	UFUNCTION()
	void SetHackingSequenceState()
	{
		SetActorTickEnabled(false);

		CoreRotationRoot.SetRelativeRotation(FRotator(CoreRotationRoot.RelativeRotation.Pitch, CoreInitialYaw, CoreRotationRoot.RelativeRotation.Roll));
		InnerRotationRoot.SetRelativeRotation(FRotator(InnerRotationRoot.RelativeRotation.Pitch, InnerInitialYaw, InnerRotationRoot.RelativeRotation.Roll));
		MiddleRotationRoot.SetRelativeRotation(FRotator(MiddleRotationRoot.RelativeRotation.Pitch, MiddleInitialYaw, MiddleRotationRoot.RelativeRotation.Roll));
		OuterRotationRoot.SetRelativeRotation(FRotator(OuterRotationRoot.RelativeRotation.Pitch, OuterInitialYaw, OuterRotationRoot.RelativeRotation.Roll));
	}
}
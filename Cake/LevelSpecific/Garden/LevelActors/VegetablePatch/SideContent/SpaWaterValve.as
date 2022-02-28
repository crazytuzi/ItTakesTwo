
class ASpaWaterValve : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent ButtonRoot;
	UPROPERTY(DefaultComponent, Attach = ButtonRoot)	
	UStaticMeshComponent ButtonMesh;
	UPROPERTY(DefaultComponent, Attach = ButtonRoot)	
	UStaticMeshComponent CylinderMesh;

	FHazeAcceleratedFloat AcceleratedFloatButton;
	float TargetRotationButton;
	bool bAllowTick;
	UPROPERTY()
	ERotateAxis AxisToRotate = ERotateAxis::Roll;
	UPROPERTY()
	bool bRotateForward = false;
	UPROPERTY()
	float AmountToRotate = 100;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bAllowTick)
			return;

		AcceleratedFloatButton.SpringTo(TargetRotationButton, 600, 0.9, DeltaSeconds);
		FRotator RelativeRotationButton;
		RelativeRotationButton.Roll = AcceleratedFloatButton.Value;

		if(AxisToRotate == ERotateAxis::Roll)
		{
			ButtonMesh.SetRelativeRotation(FRotator(RelativeRotationButton.Roll,0, 0));
		}
		else if(AxisToRotate == ERotateAxis::Pitch)
		{
			ButtonMesh.SetRelativeRotation(FRotator(0,RelativeRotationButton.Roll, 0));
		}
		else if(AxisToRotate == ERotateAxis::Yaw)
		{
			ButtonMesh.SetRelativeRotation(FRotator(0,0, RelativeRotationButton.Roll));
		}
	}

	UFUNCTION()
	void ButtonPressed()
	{
		bAllowTick = true;

		if(bRotateForward)
			TargetRotationButton = TargetRotationButton + AmountToRotate;
		else	
			TargetRotationButton = TargetRotationButton - AmountToRotate;

		System::SetTimer(this, n"AutoDisable", 10.f, false);
	}

	UFUNCTION()
	void AutoDisable()
	{
		bAllowTick = false;
	}
}

enum ERotateAxis
{
	Roll,
	Pitch,
	Yaw
}


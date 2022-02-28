
class AConcertHallPushButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent ButtonRoot;
	UPROPERTY(DefaultComponent, Attach = ButtonRoot)	
	UStaticMeshComponent ButtonMesh;

	FHazeAcceleratedFloat AcceleratedFloatButton;
	float TargetLocationButton;
	bool bAllowTick;
	UPROPERTY()
	float AmountToOffset = 30;
	UPROPERTY()
	bool bAutoReset = true;

	float SpringToSpeed = 600;
	UPROPERTY()
	float SpringToForwardSpeed= 600;
	UPROPERTY()
	float SpringToBackwardsSpeed = 600;




	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bAllowTick)
			return;


		if(bAutoReset)
		{
			if(AcceleratedFloatButton.Value >= TargetLocationButton)
			{
				SpringToSpeed = SpringToBackwardsSpeed;
				TargetLocationButton = 0;
			}	
		}

		AcceleratedFloatButton.SpringTo(TargetLocationButton, SpringToSpeed, 0.9, DeltaSeconds);
		FVector RelativeLocationButton;
		RelativeLocationButton.X = AcceleratedFloatButton.Value;


		ButtonMesh.SetRelativeLocation(FVector(-RelativeLocationButton.X, 0, 0));
	}

	UFUNCTION()
	void ButtonPressed()
	{
		bAllowTick = true;
		SpringToSpeed = SpringToForwardSpeed;
		TargetLocationButton = AmountToOffset;
		System::SetTimer(this, n"AutoDisable", 10.f, false);
	}

	UFUNCTION()
	void AutoDisable()
	{
		bAllowTick = false;
	}
}

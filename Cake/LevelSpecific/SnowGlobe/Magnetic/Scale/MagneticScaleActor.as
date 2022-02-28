// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticScaleComponent;
// event void FOnMagneticScaleStateChanged(bool Active);

// UCLASS(Abstract)
// class AMagneticScaleActor : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	USceneComponent RootComp;

// 	// UPROPERTY(DefaultComponent, Attach = RootComp)
// 	// USceneComponent LeftBase;

// 	UPROPERTY(DefaultComponent, Attach = RootComp)
// 	USceneComponent Base;

// 	// UPROPERTY(DefaultComponent, Attach = LeftBase)
// 	// UMagneticScaleComponent LeftMagnetComponent;

// 	UPROPERTY(DefaultComponent, Attach = Base)
// 	UMagneticScaleComponent MagneticComponent;
	
// 	bool bActivated;

// 	FOnMagneticScaleStateChanged OnMagneticScaleStateChanged;

// 	UPROPERTY()
// 	float HowFarDownToPull = 300.0f;

// 	UPROPERTY()
// 	float HowFarUpToPush = -50.0f;

// 	float TotalPercentage = 0.0f;

// 	UPROPERTY()
// 	float PullDownSpeed = 500.0f;

// 	UPROPERTY()
// 	float ReturnSpeed = 15.0f;

// 	UPROPERTY()
// 	float TotalCurrentSpeed = 0.0f;

// 	UPROPERTY()
// 	bool bOnlyActivateWhenFinished = false;

// 	UPROPERTY()
// 	bool bActivateWhenHalfOfScaleIsFinished = false;


// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		AddCapability(n"MagneticScaleCapability");
// 	}

// 	UFUNCTION()
// 	void ActivateScale()
// 	{
// 		if(!bActivated)
// 			bActivated = true;
// 	}

// 	void DeactivateScale()
// 	{
// 		// if(!LeftMagnetComponent.bActivated && !MagneticComponent.bActivated)
// 			bActivated = false;
// 	}
// }
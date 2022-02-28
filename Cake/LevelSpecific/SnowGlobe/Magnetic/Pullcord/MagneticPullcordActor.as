import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Peanuts.Spline.SplineComponent;

event void FOnMagneticPullcordActivated(AHazePlayerCharacter Player);
event void FOnMagneticPullcordDeactivated();
event void FOnMagneticPullcordHatchFinished();
event void FOnMagneticPullcordHatchOpen();
event void FOnMagneticPullcordHatchClose();
event void FOnMagneticPullcordReset();
event void FOnMagneticPullcordStartTimer();

UCLASS(Abstract)
class AMagneticPullcordActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent HandleMesh;

	UPROPERTY(DefaultComponent, Attach = HandleMesh)
	UMagnetGenericComponent MagneticComponent;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSplineComponent Spline;
	
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncLocalPosition;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncLockedInActivationTimer;

	bool bActivated;

	UPROPERTY()
	FOnMagneticPullcordActivated OnMagneticPullcordActivated;
	UPROPERTY()
	FOnMagneticPullcordDeactivated OnMagneticPullcordDeactivated;
	UPROPERTY()
 	FOnMagneticPullcordHatchFinished OnMagneticPullcordHatchFinished;
	UPROPERTY()
 	FOnMagneticPullcordReset OnMagneticPullcordReset;
	UPROPERTY()
 	FOnMagneticPullcordStartTimer OnMagneticPullcordStartTimer;
	UPROPERTY()
 	FOnMagneticPullcordHatchOpen OnMagneticPullcordHatchOpen;
	UPROPERTY()
 	FOnMagneticPullcordHatchClose OnMagneticPullcordHatchClose;
	
	UPROPERTY()
	EHazePlayer OwningPlayer;

	float CurrentDistance;

	float ActivatedDistance = -350.0f;	

	UPROPERTY()
	float ReturnAccelerationSpeed = 10000.0f;

	UPROPERTY()
	bool bIsLockedInActivation = false;
	
	UPROPERTY()
	float LockedInActivationTimer = 0.0f;

	UPROPERTY()
	float LockedInActivationDuration = 25.0f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"MagneticPullcordCapability");

		if (OwningPlayer == EHazePlayer::Cody)
		{
			SetControlSide(Game::GetCody());
		}

		else
		{
			SetControlSide(Game::GetMay());
		}
	}
}
//import Cake.LevelSpecific.SnowGlobe.Magnetic.Scale.MagneticScaleActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Pullcord.MagneticPullcordActor;

event void FOnPlatformStateChanged(bool isMoving, bool goingForward);
event void FOnPlatformSupportStart();
event void FOnPlatformSupportFinished();

UCLASS(Abstract)
class AScaleConnectedPlatformActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Platform;

	// UPROPERTY()
	// AMagneticScaleActor Scale;

	UPROPERTY()
	AMagneticPullcordActor Pullcord;

	UPROPERTY()
	FOnPlatformStateChanged OnPlatformStateChanged;

	UPROPERTY()
	FOnPlatformSupportStart OnPlatformSupportStart;
	UPROPERTY()
	FOnPlatformSupportFinished OnPlatformSupportFinished;

	UPROPERTY()
	float HowFarToPushOut = 1800.0f;

	float MovementSpeed = 800.0f;
	float MoveBackSpeed = 500.0f; 

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(Pullcord != nullptr)
		{
			AddCapability(n"ScaleConnectedPlatformCapability");
		}
	}
}
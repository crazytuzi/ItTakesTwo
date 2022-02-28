import Vino.Camera.Components.CameraKeepInViewComponent;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.Climbing.SnowGlobeClimbingCameraRotateComponent;
import Peanuts.Spline.SplineActor;

class ASnowGlobeClimbingCamera : AHazeCameraActor
{   
	UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
	USnowGlobeClimbingCameraRotateComponent RotatorComponent;

    UPROPERTY(DefaultComponent, Attach = RotatorComponent, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComponent;

    UPROPERTY(DefaultComponent, Attach = KeepInViewComponent, ShowOnActor)
    UHazeCameraComponent Camera;

	UPROPERTY()
	ASplineActor WallSpline;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotatorComponent.Spline = WallSpline.Spline;
	}
}
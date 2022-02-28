import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Components.CameraSplineRotationFollowerComponent;
import Peanuts.Spline.SplineComponent;

class AKeepInViewSplineRotatorCameraActor : AHazeCameraActor
{   
	UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
	UCameraSplineRotationFollowerComponent SplineRotationFollower;

	default SplineRotationFollower.CameraSpline = CameraSpline;

    UPROPERTY(DefaultComponent, Attach = SplineRotationFollower, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComponent;

    UPROPERTY(DefaultComponent, Attach = KeepInViewComponent, ShowOnActor)
    UHazeCameraComponent Camera;
	default Camera.Settings.bUseSnapOnTeleport = true;
	default Camera.Settings.bSnapOnTeleport = false;

	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CameraSpline;

#if EDITOR
    default CameraSpline.bShouldVisualizeScale = true;
    default CameraSpline.ScaleVisualizationWidth = 100.f;
#endif

}
import Vino.Camera.Components.BallSocketCameraComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Components.CameraSplineRotationFollowerComponent;

class ASplineRotatorFollowUserBallSocketCamera : AHazeCameraActor
{
	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponentBase RotationSpline;
#if EDITOR
    default RotationSpline.bShouldVisualizeScale = true;
    default RotationSpline.ScaleVisualizationWidth = 20.f;
#endif

	// This component will rotate along with the spline
	UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
	UCameraSplineRotationFollowerComponent RotationFollower;
	default RotationFollower.CameraSpline = RotationSpline;
	default RotationFollower.RotationOffset = FRotator(0, -90, 0);
	default RotationFollower.bUseAsClampsCenter = true;

	UPROPERTY(DefaultComponent, Attach = RotationFollower, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComponent;
	default KeepInViewComponent.PlayerFocus = EKeepinViewPlayerFocus::User;
	
	UPROPERTY(DefaultComponent,Attach = KeepInViewComponent, ShowOnActor)
	UBallSocketCameraComponent BallSocket;

	UPROPERTY(DefaultComponent, Attach = BallSocket, ShowOnActor)
	UHazeCameraComponent Camera;
};
import Vino.Camera.Components.BallSocketCameraComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;

class AFollowUserBallSocketCamera : AHazeCameraActor
{
	UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComponent;
	default KeepInViewComponent.PlayerFocus = EKeepinViewPlayerFocus::User;
	
	UPROPERTY(DefaultComponent,Attach = KeepInViewComponent, ShowOnActor)
	UBallSocketCameraComponent BallSocket;

	UPROPERTY(DefaultComponent, Attach = BallSocket, ShowOnActor)
	UHazeCameraComponent Camera;
};
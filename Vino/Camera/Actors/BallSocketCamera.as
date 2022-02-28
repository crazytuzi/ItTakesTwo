import Vino.Camera.Components.BallSocketCameraComponent;

class ABallSocketCamera : AHazeCameraActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UBallSocketCameraComponent BallSocket;

	UPROPERTY(DefaultComponent, Attach = BallSocket, ShowOnActor)
	UHazeCameraComponent Camera;
};
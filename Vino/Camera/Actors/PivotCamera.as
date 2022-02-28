import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Camera.Components.CameraMatchDirectionComponent;

class APivotCamera : AHazeCameraActor
{
   	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraMatchDirectionComponent MatchDirectionComponent;
	default MatchDirectionComponent.bMatchDirection = false;

   	UPROPERTY(DefaultComponent, Attach = MatchDirectionComponent, ShowOnActor)
	UCameraSpringArmComponent SpringArm;

	UPROPERTY(DefaultComponent, Attach = SpringArm, ShowOnActor)
	UHazeCameraComponent Camera;
}
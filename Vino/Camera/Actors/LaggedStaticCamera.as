import Vino.Camera.Components.CameraLagComponent;
import Vino.Camera.Components.CameraDetacherComponent;

// Attach this to something to make camera follow parent with some lag
UCLASS(hideCategories="Rendering Cooking Input Actor LOD")
class ALaggedStaticCamera : AHazeCameraActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraDetacherComponent CameraDetacher;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = CameraDetacher)
	UCameraLagComponent CameraLagger;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = CameraLagger)
	UHazeCameraComponent Camera;
};
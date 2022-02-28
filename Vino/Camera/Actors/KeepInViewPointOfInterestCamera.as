import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Components.CameraPointOfInterestRotationComponent;

class AKeepInViewPointOfInterestCamera :AHazeCameraActor
{
	UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
	UCameraPointOfInterestRotationComponent PointOfInterestRotator;

    UPROPERTY(DefaultComponent, Attach = PointOfInterestRotator, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComponent;

    UPROPERTY(DefaultComponent, Attach = KeepInViewComponent, ShowOnActor)
    UHazeCameraComponent Camera;
	default Camera.Settings.bUseSnapOnTeleport = true;
	default Camera.Settings.bSnapOnTeleport = false;
}
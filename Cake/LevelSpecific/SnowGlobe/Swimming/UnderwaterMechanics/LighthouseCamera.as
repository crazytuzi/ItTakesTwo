import Vino.Camera.Components.CameraKeepInViewComponent;
import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.LighthouseCameraRotatorComponent;

class ALighthouseCamera : AHazeCameraActor
{   
	UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
	ULighthouseCameraRotatorComponent RotatorComponent;

    UPROPERTY(DefaultComponent, Attach = RotatorComponent, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComponent;

    UPROPERTY(DefaultComponent, Attach = KeepInViewComponent, ShowOnActor)
    UHazeCameraComponent Camera;
}
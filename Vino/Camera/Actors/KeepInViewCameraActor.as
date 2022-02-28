import Vino.Camera.Components.CameraKeepInViewComponent;

class AKeepInViewCameraActor : AHazeCameraActor
{   
    UPROPERTY(DefaultComponent, Attach = CameraRootComponent, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComponent;

    UPROPERTY(DefaultComponent, Attach = KeepInViewComponent, ShowOnActor)
    UHazeCameraComponent Camera;
	default Camera.Settings.bUseSnapOnTeleport = true;
	default Camera.Settings.bSnapOnTeleport = false;

    UFUNCTION(Category = "Keep In View")
    void AddTarget(FHazeFocusTarget FocusTarget)
    {
        KeepInViewComponent.AddTarget(FocusTarget);
    }
    UFUNCTION(Category = "Keep In View")
    void RemoveTarget(AHazeActor Actor)
    {
        KeepInViewComponent.RemoveTarget(Actor);
    }
}
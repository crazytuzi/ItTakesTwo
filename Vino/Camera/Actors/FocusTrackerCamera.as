import Vino.Camera.Components.FocusTrackerComponent;


class AFocusTrackerCamera : AHazeCameraActor
{
	UPROPERTY(DefaultComponent)
	UFocusTrackerComponent FocusTracker;

	UPROPERTY(DefaultComponent, Attach = FocusTracker)
	UHazeCameraComponent Camera;
}
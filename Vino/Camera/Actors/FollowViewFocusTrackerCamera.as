import Vino.Camera.Components.CameraFollowViewComponent;
import Vino.Camera.Components.FocusTrackerComponent;

class AFollowViewFocusTrackerCamera : AHazeCameraActor
{
	UPROPERTY(DefaultComponent)
	UCameraFollowViewComponent FollowView;

	UPROPERTY(DefaultComponent, Attach = FollowView)
	UFocusTrackerComponent FocusTracker;

	UPROPERTY(DefaultComponent, Attach = FocusTracker)
	UHazeCameraComponent Camera;
}

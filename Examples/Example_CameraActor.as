import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Components.BallSocketCameraComponent;

// When you just want to tweak the default camera, you should apply camera settings (see Example_CameraSettings.as)
// but when you want some more complex or different behaviour you should instead activate a separate camera. 
// This can be done in some different ways:
// 1. Place a camera actor in a level and place a Haze Camera Volume with the Camera property set to the camera actor.
//    This will activate the camera while the player is inside the volume.
// 2. Place a camera actor in a level and call CameraActor.ActivateCamera(Player...), see below.
//    You then need to call CameraActor.DeactivateCamera(Player) when the player should blend back to the default camera.
// 3. Give an actor a Haze Camera Component and call Player.ActivateCamera on that component, see below. 
//    Note that if both players should be able to use this camera at the same time you need to give the actor a 
//    Haze Camera Root Component which the camera is attached to (with one or more camera parent components in between).

// A camera actor is really just an actor with a camera root component and a camera component such as this:
UCLASS(hideCategories="Rendering Cooking Input Actor LOD")
class AExampleSuperSimpleCamera : AHazeCameraActor
{
	// Simplest possible camera actor, identical to AStaticCamera. 
	// Since this inherits from AHazeCameraActor it already has a camera root component, so can be activated by 
	// both players at the same time.
	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeCameraComponent Camera;
};

// You will find lots of useful camera actors in Vino/Camera/Actors, such as keep in view cameras, spline cameras etc.
// However, if you need some new behaviour we'd have to create a new camera. To do this we use camera parent components
// as puzzle pieces that handles some part of the wanted behaviour. These can be found in Vino/Camera/Components. 
// Some examples of this below:

// Camera rotation is controlled by player input but moves in/out along that rotation to keep both players in view, within some bounds.
UCLASS(hideCategories="Rendering Cooking Input Actor LOD")
class AExampleBallsocketKeepInViewCamera : AHazeCameraActor
{
	// This will rotate along with player input, moving it's attach children with it.
	UPROPERTY(DefaultComponent, ShowOnActor)
	UBallSocketCameraComponent BallSocket;

	// This will try to keep both players in view 
	UPROPERTY(DefaultComponent, ShowOnActor, Attach = BallSocket)
	UCameraKeepInViewComponent KeepInView;
	default KeepInView.PlayerFocus = EKeepinViewPlayerFocus::AllPlayers;
	default KeepInView.MinDistance = 1000.f;
	default KeepInView.BufferDistance = 1000.f;
	default KeepInView.MaxDistance = 5000.f;
	default KeepInView.AccelerationDuration = 0.5f;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = KeepInView)
	UHazeCameraComponent Camera;
}

// Finally, if you need some completely new behaviour you have to create new camera parent components that handle it, 
// then plug that into an actor which uses the new component in together with other camera parent comps.
// This example component will roll continuously, dragging any attached components along with it.
class UExampleRollingCameraParentComponent : UHazeCameraParentComponent
{
	// Set this to true if you've created a camera parent component that will use player input
	default bWantsCameraInput = false; 

	// This is called when the camera is being activated. The PreviousState parameter tells us if the camera was: 
	// - Inactive (if never previously activated or fully blended out)
	// - BlendingOut (if currently blending out)
	// You will never get this call when the camera was previously active.
	// Note that this occurs early during the camera system update instead of immediately when an activate camera call is made.
	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		// Whenever a camera is initially activated or activated again after having fully blended out,
		// you usually want it to snap into place rather than move there.
		if (PreviousState == EHazeCameraState::Inactive)
		{
			Snap();
		}
	}

	// Called when the camera starts blending out. The camera will continue to update during the blend,
	// so most cleanup should be done in OnCameraFinishedBlendingOut
	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
	}

	// Called when the camera has blended out fully and will stop updating. Clean up stuff here.
	UFUNCTION(BlueprintOverride)
	void OnCameraFinishedBlendingOut(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
	}

	// Called every camera system update. Use this rather than Tick as order of execution is more tighly controlled.
	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		// Rollin' rollin' rollin', rollin' rollin' rollin', rollin' rollin' rollin', rollin' rollin' rollin', rawhide!
		FRotator NewRotation = RelativeRotation;
		NewRotation.Roll += 30.f * DeltaSeconds;
		SetRelativeRotation(NewRotation.GetNormalized());
	}

	// Called whenever this camera should snap into place. Make sure anything this component changes is snapped as well.
	UFUNCTION(BlueprintOverride)
	void Snap()
	{
	}
};

// Now we can use the camera parent component to patch together a camera which will pivot around 
// it's own location based on input and continuously roll on top of that:
UCLASS(hideCategories="Rendering Cooking Input Actor LOD")
class AExampleBallsocketRollingCamera : AHazeCameraActor
{
	UPROPERTY(DefaultComponent, ShowOnActor)
	UBallSocketCameraComponent BallSocket;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = BallSocket)
	UExampleRollingCameraParentComponent Roller;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = Roller)
	UHazeCameraComponent Camera;
};


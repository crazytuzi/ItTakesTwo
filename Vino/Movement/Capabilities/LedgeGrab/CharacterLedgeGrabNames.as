
namespace LedgeGrabTags
{
    const FName Enter = n"EnterCharacterLedgeGrab";
    const FName Hang = n"HangCharacterLedgeGrab";
    const FName ClimbUp = n"ClimpCharacterLedgeGrab";
    const FName JumpUp = n"JumpUpCharacterLedgeGrab";
    const FName JumpAway = n"JumpAwayCharacterLedgeGrab";
    const FName Evaluate = n"EvaluateCharacterLedgeGrab";
    const FName Drop = n"DropCharacterLedgeGrab";

	const FName HangMove = n"LedgeGrabHangMovementCapability";
}

namespace LedgeGrabActivationEvents
{
	const FName Grabbing = n"LedgeGrabSystemActiveAction";

	// Used to force pretick to run so we can update the cooldown.
	const FName Cooldown = n"LedgeGrabCoolingDown";
}

namespace LedgeGrabSyncNames
{
    const FName HangPosition = n"LedgeGrabWorldHangPosition";
    const FName RelativeHangPosition = n"LedgeGrabRelativeHangPosition";
    const FName LedgeNormal = n"LedgeGrabWorlWallNormal";
    const FName RelativeNormal = n"LedgeGrabRelativeWallNormal";
    const FName HangObject = n"LedgeGrabHangPrimitive";
	const FName StartedDescending = n"LedgeGrabStartedDescending";
    const FName DeactivationType = n"LedgeGrabDeactivationType";
	const FName Dropped = n"LedgeGrabCancellingOutOf";

	const FName ContactSurface = n"LedgeGrabContactSurfaceMaterial";

	const FName LeftHandLocation = n"LedgeGrabLeftHandLocation";
	const FName RightHandLocation = n"LedgeGrabRightHandLocation";

	const FName LeftHandForwardRotation = n"LedgeGrabLeftHandForwardRotation";
	const FName LeftHandUpRotation = n"LedgeGrabLeftHandUpRotation";
	
	const FName RightHandForwardRotation = n"LedgeGrabRightHandForwardRotation";
	const FName RightHandUpRotation = n"LedgeGrabRightHandUpRotation";
}

namespace LedgeGrabAnimationParams
{
	const FName HangDirection = n"LedgeHangInputDirection";
}


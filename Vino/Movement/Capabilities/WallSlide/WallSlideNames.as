namespace WallSlideActions
{
    const FName JumpInputStopped = n"WallSlideJumpInputStopped";
	const FName HorizontalJump = n"WallslideHorizontalJumpIsActive";
}

namespace WallslideActivationEvents
{
	const FName Wallsliding = n"WallslideSystemActiveAction";

	const FName Cooldown = n"WallslideCooldownForceActivation";
	const FName JumpCheck = n"WallSlideForceJumpOffDataCheck";
}

namespace WallSlideAnimParams
{
	const FName FastSlideDistance = n"FastWallSlideDistance";
}

namespace WallSlideSyncing
{
	const FName WallNormal = n"WallSlideRelativeOrWorldNormal";
	const FName Primitive = n"WallSlidePrimitiveSlidingOn";
	const FName Cancelled = n"WallSlideWasEndedWithCancelPress";
	const FName FastSlideDistance = n"WallSlideFastSlideDistance";
	const FName Location = n"WallSlideSyncLocation";
}

namespace WallSlideTags
{
	const FName WallSliding = n"ActiveWallSlideCapability";
}

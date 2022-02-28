
namespace GroundPoundTags
{
	const FName Start = n"GroundPoundStart";
	const FName Fall = n"GroundPoundFall";
	const FName Land = n"GroundPoundLand";
	const FName Exit = n"GroundPoundExit";
	const FName Jump = n"GroundPoundJump";
	const FName Dash = n"GroundPoundDash";

	const FName LandOnWater = n"GroundPoundLandOnWater";

	const FName TotemHeadStart = n"GroundPoundTotemHeadStart";
	const FName TotemHeadFall  = n"GroundPoundTotemHeadFall";
	const FName TotemHeadLand  = n"GroundPoundTotemHeadLand";

	const FName TotemBodyStart = n"GroundPoundTotemBodyStart";
}

namespace GroundPoundSyncNames
{
	const FName LandGrounded = n"GroundPoundSyncLandedGrounded";
	const FName LandPrimitive = n"GroundPoundSyncLandedOnPrimitive";
	const FName CallbackComp = n"GroundPoundSyncCallbackComp";
}

namespace GroundPoundEventActivation
{
	const FName System = n"GroundPoundSystemActionEvent";

	const FName Entering = n"GroundPoundEnteringEvent";
	const FName Falling = n"GroundPoundFallingEvent";
	const FName Landed = n"GroundPoundLandedEvent";
}

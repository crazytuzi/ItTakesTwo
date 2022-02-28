
struct FCharacterLedgeGrabSettings
{
	// How far away from the hang position the characters hand will be.
	float HandOffset = 15.f;

	// How far the character position is offset from the ledge. Is calculated from the hang animation MH.
	FVector HangOffset = FVector::ZeroVector;

	// How long it takes to lerp into the hang position.
	float LerpToHangPositionTime = 0.2f;

	// How long you stay in the enter capbility before going to the hang capability.
	float EnterDuration = 0.42f;

	// How long after you have ledgegrab it takes before you can ledgegrab again.
	float LedgeGrabCooldown = 0.4f;

	// Minimum input needed to control wich direction the jumps off in.
	float JumpOffMinStickInput = 0.25f;

	// ------ LedgeFindSettings -------
	// How high we will offset the sphere trace when looking for a wall.
	float WallCheckPositionHeight = 150.f;

	// How long forward we will trace when looking for a wall.
	float WallCheckForwardDistance = 15.f;

	// How long forward of the character we start the trace.
	float WallCheckStartForwardOffset = 5.f;

	// How much to lower the trace when looking for the forward hand position.
	float HandLowering = 10.f;
	
	// How much to back away before tracing for the wall.
	float HandForwardTrace = 35.f;

	// The character has to be below this speed to allow a ledge grab. (Lucas Approved comment)
	float WallCheckMaxAllowedUpwardsSpeed = 800.f;

	// Radius of the spere trace trying to find the wall.
	float WallTraceSphereRadius = 25.f;

	// How far up we will go to try and find the first gap to trace down from.
	float FindLedgePositionTraceMaxHeight = 40.f;

	// How far we will go from the impact normal when finding the location to trace to.
	float FindLedgePositionTraceDepth = 10.f;

	// Heigt distance between each trace when tracing for grabbable gaps.
	float FindLedgeGapHeightTraceSegments = 15.f;

	// How far down we will trace when looking for hand positions.
	float FindHandPositionHeightTrace = 15.f;

	// Height difference allowed when looking at height positions for the hands.
	float MaxAllowedHandDifference = 1.f;

	// Max difference allowed on the degree difference between wallhits.
	float MaxAllowedWallNormalDifference = 30.f;

	// How much the surface is allowed to tilt, in degress.
	float MaxTopTilt = 15.f;

	// If the stick is above this value then input will be zeroed.
	float MaxExtraHangSideInput = - 0.55;

	// Haning jump off vector will be clamp to this degree amount.
	float MaxDegreeSideInputVector = 35.f;

	// Minimum degress to start turning when hanging.
	float HangHandMinDegress = 40.f;

	FCharacterLedgeGrabSettings GetScaledLedgeGrabSettings(float Scale) const
	{
		FCharacterLedgeGrabSettings Output = this;

		Output.HandOffset *= Scale;
		Output.HangOffset *= Scale;
		Output.WallCheckPositionHeight *= Scale;
		Output.WallCheckForwardDistance *= Scale;
		Output.WallCheckStartForwardOffset *= Scale;
		Output.WallTraceSphereRadius *= Scale;
		Output.FindLedgePositionTraceMaxHeight *= Scale;
		Output.FindLedgePositionTraceDepth *= Scale;
		Output.FindLedgeGapHeightTraceSegments *= Scale;
		Output.FindHandPositionHeightTrace *= Scale;
		Output.MaxAllowedHandDifference *= Scale;
		Output.HandLowering *= Scale;
		Output.HandForwardTrace *= Scale;

		return Output;
	}
}


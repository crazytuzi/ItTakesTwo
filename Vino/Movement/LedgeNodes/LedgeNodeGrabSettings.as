
struct FLedgeNodeGrabSettings
{
	// how high up the we go from the players feet location to find where to do location calculations from
	const float ChestOffset = 150.f;

	// How far down from the hang position we put the player.
	const float HangOffset = 165.f;

	// How long it takes to enter the node.
	const float GrabDuration = 0.5f;

	// How long after ledge node jump does it take before you can enter into a new node.
	const float JumpRentryDuration = 0.3f;

	// How long after we have cancelled out of a node grab those it take before we can go into a new grab.
	const float CancelDuration = 1.f;

	// Minimum stick input needed to jumpaway from node.
	const float MinStickInput = 0.25f;
}

namespace GrappleSettings
{
	const FGrappleSpeedSettings Speed;
}

struct FGrappleSpeedSettings
{
	// Time after activation where the player freezes in the air
	const float FreezeTime = 0.2f;

	// The initial speed upon activation
	const float InitialSpeed = 4500.f;

	// The minimum speed you can reach during the grapple
	const float MinimumSpeed = 1800.f;

	// The initial speed upon activation
	const float DragExponent = 1.8f;
}
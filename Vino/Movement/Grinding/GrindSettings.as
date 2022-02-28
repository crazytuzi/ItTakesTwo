namespace GrindSettings
{
	// The time that needs to pass before you can grind on a previous grind spline
	const float GrindSplineCooldown = 0.15f;
	// The time that the grind rail is down prioritized after leaving
	const float GrindSplineLowPriorityDuration = 1.f;

	const float GrindingOffsetInterpSpeed = 8.f;

	const FGrindSpeedSettings Speed;

	// Enter Settings
	const FGrindProximitySettings Proximity;
	const FGrindGrappleSettings Grapple;
	const FGrindTransferSettings Transfer;

	// Impact settings
	const FGrindObstructionSettings Obstruction;

	// Active Grind Settings
	const FGrindGrindingSettings Grinding;
	const FGrindJumpSettings Jump;
	const FGrindDashSettings Dash;
	const FGrindTurnAroundSettings TurnAround;

	// Ground exit 
	const FGrindGroundExitSettings GroundExit;
}

struct FGrindProximitySettings
{
	// How close you need to be to grind while airbourne
	const float AirbourneAcceptanceRange = 125.f;

	// How close you need to be when returning to the same spline after a jump
	const float AirbourneAcceptanceRangeJumpedFrom = 50.f;

	// The accepted downwards angle of the players' velocity
	const float AirbourneDownwardsAcceptanceAngleDeg = 90.f;


	// How close you need to be to grind while grounded
	const float GroundedAcceptanceRange = 50.f;

	// The accepted angle between the players' velocity and the spline direction
	// (0 is perfectly in the tangent or -tangent's direction)
	const float GroundedSplinewardsAcceptanceAngleDeg = 30.f;
}

struct FGrindGrappleSettings
{
	const float InitialSpeed = 0.f;
	const float Acceleration = 8200.f;
	const float DragScale = 2.f;

	const float MaxRange = 1900.f;

	UPROPERTY(Category = "Movement")
	const float EnterVelocityRotationRate = 140.f;

	UPROPERTY(Category = "Camera|Look At")
	const float CameraLookAtDistanceAlongSpline = 1200.f;

	UPROPERTY(Category = "Camera|Look At")
	const float CameraLookAtAdditionalHeight = 300.f;
}

struct FGrindTransferSettings
{
	const float Speed = 3200.f;

	const float AttachPointForwardDistance = 800.f;

	const float MaxTransferDistance = 1400.f;

	const float WidgetDistance = 3000.f;
}

struct FGrindGrindingSettings
{
	UPROPERTY(Category = "Camera")
	const float CameraFutureTestDistance = 800.f;

	UPROPERTY(Category = "Camera|Look At")
	const float CameraLookAtAdditionalHeight = 200.f;

	UPROPERTY(Category = "Camera|Pivot Offset")
	const float HorizontalPivotOffsetMax = 225.f;

	UPROPERTY(Category = "Camera|Pivot Offset")
	const float HorizontalPivotOffsetAngleMax = 20.f;

	// FOV at minimum speed
	UPROPERTY(Category = "Camera")
	const float CameraDefaultFOV = 60.f;

	// Additional FOV at max speed
	UPROPERTY(Category = "Camera")
	const float CameraAdditionalFOVAtMaxSpeed = 30.f;

	// The minimum shimmer strength while grinding
	UPROPERTY(Category = "Camera")
	const float ShimmerMin = 0.1f;
	
	// The addtional shimmer strength while grinding at max speed
	UPROPERTY(Category = "Camera")
	const float ShimmerAddtional = 2.f;
}

struct FGrindBasicSpeedSettings
{
	// How much speed the incline can decrease from desired middle.
	UPROPERTY(Category = "Speed")
	const float DesiredMinOffset = 400.f;

	// The resting desired speed on flat ground
	UPROPERTY(Category = "Speed")
	const float DesiredMiddle = 1800.f;

	// How much speed the incline can increase from desired middle.
	UPROPERTY(Category = "Speed")
	const float DesiredMaxOffset = 800.f;

	float GetDesiredMaximum() const property
	{
		return DesiredMiddle + DesiredMaxOffset;
	}

	float GetDesiredMinimum() const property
	{
		return DesiredMiddle - DesiredMinOffset;
	}
}

struct FGrindSpeedSettings
{	
	UPROPERTY(Category = "Speed")
	FGrindBasicSpeedSettings BasicSettings;

	// The strength of your drag when above desired max
	UPROPERTY(Category = "Speed")
	const float DragStrengthAboveDesired = 1.2f;

	// Your deceleration going uphill, scaled by slope angle
	UPROPERTY(Category = "Acceleration")
	const float DesiredSlopeDeceleration = 700.f;	

	// The deceleration you have on a flat grind spline
	UPROPERTY(Category = "Acceleration")
	const float DesiredNeutralDeceleration = 100.f;

	// You acceleration going downhill on a slope, scaled by slope angle
	UPROPERTY(Category = "Acceleration")
	const float DesiredSlopeAcceleration = 3000.f;

	// At what slope angle is the grind spline considered flat
	UPROPERTY(Category = "Acceleration")
	const float SlopeAngleConsideredFlat = 5.f;

	// At what slope angle is the maximum slope acceleration/deceleration
	UPROPERTY(Category = "Acceleration")
	const float SlopeTerminalAngle = 70.f;
}

struct FGrindJumpSettings
{
	// The vertical impulse of the jump
	const float Impulse = 1600.f;

	// The extra impulse granted at the max test angle
	const float ExtraImpulse = 1500.f;

	// The angle required for the maximum extra impulse
	const float ExtraImpulseMaxTestAngle = 60.f;

	const float Gravity = 3600.f;

	// If your the angle between input and tangent excedes this angle, you will no longer be spline locked
	const float SplineLockInputTangentAngle = 35.f;
}

struct FGrindDashSettings
{
	// The impulse given when dash is activated
	const float Impulse = 2200.f;

	// The max speed you can reach via the dash impulse
	const float MaxSpeed = 3800.f;

	// The cooldown duration after the end of the dash before you can dash again
	const float Cooldown = 0.6f;
}

struct FGrindTurnAroundSettings
{
	UPROPERTY(Category = "Activation")
	const float RequiredAngle = 115.f;

	// How long the TurnAround lasts for
    const float Duration = 1.00f;

	// The cooldown duration after the end of the TurnAround before you can TurnAround again
	const float Cooldown = 0.2f;

	UPROPERTY(Category = "Speed")
	const float DecelerationTime = 0.50f;

	UPROPERTY(Category = "Speed")
	const float ExitSpeed = 4400.f;
}

struct FGrindGroundExitSettings
{
	// How long grinding evaluation should pause for after exiting from hitting ground, to avoid stuttering on/off
	const float EvaluatePauseDuration = 1.2f;
}

struct FGrindObstructionSettings
{
	// This force will always be added
	float MinForce = 250.f;

	// The current grinding speed get added to the min force but gets capped to this value.
	float MaxAddedForce = 500.f;

	// When grappling this force will be added to the MinForce.
	float GrapplingeForce = 1000.f;

	// This force will always be added in the players up direction.
	float UpwardsForce = 1200.f;

	// The minimum angle difference between the tangent of the spline and the direction the player is knocked in
	float MinAngle = 30.f;
}

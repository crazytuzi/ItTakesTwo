UCLASS(Meta = (AutoExpandCategories = "Settings"))
class USplineSlideSettingsDataAsset : UDataAsset
{
	UPROPERTY(Category = Settings)
	FSplineSlideSettings Settings;
}

struct FSplineSlideSettings
{
	UPROPERTY()
	FSplineSlideLongitudinalSettings Longitudinal;

	UPROPERTY()
	FSplineSlideLateralSettings Lateral;
	
	UPROPERTY()
	FSplineSlideAirSettings Air;

	UPROPERTY()
	FSplineSlideJumpSettings Jump;

	UPROPERTY()
	FSplineSlideRampJumpSettings RampJump;

	UPROPERTY()
	FSplineSlideRubberbandSettings Rubberbanding;
}

struct FSplineSlideLongitudinalSettings
{
	/* Constant drag coefficient that will be used along with the desired speed to calculate acceleration
		Higher values will result in a more snappy, faster acceleration feeling, which a shorter duration to reach the desired
	*/
	UPROPERTY()
	const float DragCoefficient = 1.f;

	// Your desired speed when across a neutral slope
	UPROPERTY()
	const float DesiredNeutralSpeed = 2400.f;

	// Desired speed at maximum upwards slope angle, lerped down to neutral speed at neutral angle
	UPROPERTY()
	const float UphillSpeed = 2000.f;

	// Desired speed at maximum downwards angle, lerped down to neutral speed at neutral angle
	UPROPERTY()
	const float DownhillSpeed = 4000.f;

	// The maximum angle that will determine the desired speed
	UPROPERTY()
	const float MaximumAngle = 45.f;	

	/*
		How much the spline forward will be affected by the roll of the spline
		As the spline rolls, the forward vector will be yawed into the banking of the corner
		0.5f scale means for every degree of roll, the forward will be yawed 0.5 degress inwards
	*/
	const float SplineForwardRollAdjustedScale = 0.6f;
}

struct FSplineSlideLateralSettings
{
	// Lateral acceleration in the splines right direction x input
	UPROPERTY()
	const float Acceleration = 3400.f;

	// Lateral velocity drag coefficient
	UPROPERTY()
	const float DragCoefficient = 2.0f;

	// The maximum speed of the Lateral velocity
	UPROPERTY()
	const float MaximumSpeed = 2600.f;
}

struct FSplineSlideBoostSettings
{
	// The speed you will reach during the boost
	UPROPERTY()
	const float Speed = 4200.f;

	// Acceleration while on the boost pad
	UPROPERTY()
	const float Acceleration = 8000.f;
}

struct FSplineSlideAirSettings
{
	UPROPERTY()
	const float Gravity = 3200.f;
}

struct FSplineSlideJumpSettings
{
	// Initial impulse of the jump
	UPROPERTY()
	const float Impulse = 2200.f;

	// Gravity acceleration
	UPROPERTY()
	const float Gravity = 3100.f;

	// How fast your velocity will rotate towards the tangent
	UPROPERTY()
	const float TangentRotationRate = 40.f;
}

struct FSplineSlideRampJumpSettings
{
	UPROPERTY()
	const float Impulse = 1000.f;

	UPROPERTY()
	const float Gravity = 3400.f;
}

struct FSplineSlideRubberbandSettings
{
	UPROPERTY()
	const bool bEnableRubberbanding = true;

	UPROPERTY(Meta = (EditCondition = "bEnableRubberbanding", EditConditionHides))
	const float MinimumScale = 0.85f;

	UPROPERTY(Meta = (EditCondition = "bEnableRubberbanding", EditConditionHides))
	const float MaximumScale = 1.15f;

	UPROPERTY(Meta = (EditCondition = "bEnableRubberbanding", EditConditionHides))
	const float DistanceConsideredMaximum = 5000.f;

	// Positive Pow to make the rubberbanding stronger earlier on
	UPROPERTY(Meta = (EditCondition = "bEnableRubberbanding", EditConditionHides))
	const float PowValue = 1.8f;
}

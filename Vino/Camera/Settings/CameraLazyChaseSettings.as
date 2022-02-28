UCLASS(Meta = (ComposeSettingsOnto = "UCameraLazyChaseSettings"))
class UCameraLazyChaseSettings : UHazeComposableSettings
{
	// If false, we will block any chase assistance capabilities, same as when setting chase assistance to 'None' in options. Do not change this unless you know what you are doing!
	UPROPERTY(AdvancedDisplay)
	bool bUseOptionalChaseAssistance = true;

    // Lazy chase will never be used within this many seconds after having given camera input.
	UPROPERTY()
	float CameraInputDelay = 0.7f;

    // How many seconds after starting to move will lazy chase kick in?
	UPROPERTY()
	float MovementInputDelay = 0.3f;

    // How long time will it take for camera to move to target rotation normally (note that target will usually be changing though)
	UPROPERTY()
	float AccelerationDuration = 5.f;

    // Determines how fast we should chase after target rotation due to angle difference between curretn and target rotation (0 -> do not chase, 1 -> chase at normla speed)
 	UPROPERTY()
	UCurveFloat ChaseFactorByAngleCurve = nullptr; // Can't have asset as default here :(

 	UPROPERTY()
	float MovementThreshold = 100.f;

	UPROPERTY(meta = (ClampMin = "0.0", ClampMax = "1.0"))
	float InheritedVelocityFactor = 0.f;

	// Rotation to chase after is modified by this rotator. Use when player does not align with wanted chase rotation.
	UPROPERTY()
	FRotator ChaseOffset = FRotator::ZeroRotator;
}

UCLASS(Meta = (ComposeSettingsOnto = "UCameraVehicleChaseSettings"))
class UCameraVehicleChaseSettings : UHazeComposableSettings
{
    // Lazy chase will never be used within this many seconds after having given camera input.
	UPROPERTY()
	float CameraInputDelay = 0.1f;

    // How many seconds after starting to move will lazy chase kick in?
	UPROPERTY()
	float MovementInputDelay = 0.1f;

    // How long time will it take for camera to move to target rotation normally (note that target will usually be changing though)
	UPROPERTY()
	float AccelerationDuration = 3.f;

	// If >= 0, acceleration duration will start at this value and change to the normal acceleration duration over acceleration change duration
	UPROPERTY()
	float InitialAccelerationDuration = -1.f;

    // Acceleration will reach the normal acceleration duration over this many seconds when changed.
	UPROPERTY()
	float AccelerationChangeDuration = 1.f;

	// If >= 0, acceleration duration will snap to this value whenever camera input is given
	UPROPERTY()
	float InputResetAccelerationDuration = -1.f;

	// If > 0, camera will try to look at a position this distance ahead of vehicle by offsetting camera pivot.
	// This means vehicle will be framed to the left when turning to the right and vice versa.
	UPROPERTY()
	float LookAheadDistance = 0.f; 

	// Any look ahead offset will blend in over this duration in seconds
	UPROPERTY()
	float LookAheadBlendTime = 2.f;

	// If set, if the movement input is released but the camera input has been used, never revert to the chase until movement stick is used again.
	UPROPERTY()
	bool bOnlyChaseAfterMovementInput = true;

	// Rotation to chase after is modified by this rotator. Use when camera/player does not align with the vehicle.
	UPROPERTY()
	FRotator ChaseOffset = FRotator::ZeroRotator;
}

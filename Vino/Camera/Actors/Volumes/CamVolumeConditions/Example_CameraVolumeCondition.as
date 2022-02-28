class Example_CameraVolumeCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		// Only active while not grounded and not double jumping
		if (Player.IsAnyCapabilityActive(n"AirJump") && Player.IsAnyCapabilityActive(n"Jump"))
			return false;
		UHazeBaseMovementComponent MoveComp = UHazeBaseMovementComponent::Get(Player);
		if (MoveComp.IsGrounded())
			return false;
		return true;
	}
}
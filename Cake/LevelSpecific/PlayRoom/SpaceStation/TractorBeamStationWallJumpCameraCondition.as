import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideHorizontalJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideCapability;

class TractorBeamStationWallJumpCameraCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		if (!Player.MovementWorldUp.Equals(FVector(1.f, 0.f, 0.f)))
			return false;

		if (!Player.IsAnyCapabilityActive(UCharacterWallSlideHorizontalJumpCapability::StaticClass()) && !Player.IsAnyCapabilityActive(UCharacterWallSlideCapability::StaticClass()))
			return false;

		if (!Player.IsMay())
			return false;

		return true;
	}
}
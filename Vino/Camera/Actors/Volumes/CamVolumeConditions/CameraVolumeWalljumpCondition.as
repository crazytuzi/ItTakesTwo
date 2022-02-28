import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideHorizontalJumpCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideCapability;

class UCameraVolumeWalljumpCondition : UHazePlayerCondition
{
	UFUNCTION(BlueprintOverride)
	bool MeetCondition(AHazePlayerCharacter Player)
	{
		if (Player.IsAnyCapabilityActive(UCharacterWallSlideHorizontalJumpCapability::StaticClass()) ||
			Player.IsAnyCapabilityActive(UCharacterWallSlideCapability::StaticClass()) ||
			!Player.MovementComponent.IsGrounded())
		{
			return true;
		}
			
		else
		{
			return false;
		}
			
	}
}
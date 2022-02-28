import Cake.LevelSpecific.Music.MusicJumpTo.MusicJumpToComponent;

namespace MusicJumpTo
{
    UFUNCTION()
	void ActivateMusicJumpTo(AHazePlayerCharacter Player, FHazeJumpToData JumpToData)
    {
        if(Player == nullptr)
        {
            return;
        }

        if(!Player.HasControl())
        {
            return;
        }

        UMusicJumpToComponent JumpToComponent = UMusicJumpToComponent::GetOrCreate(Player);
        JumpToComponent.bJump = true;
		JumpToComponent.TargetComponent = JumpToData.TargetComponent;
		JumpToComponent.TargetTransform = JumpToData.Transform;
		JumpToComponent.AdditionalHeight = JumpToData.AdditionalHeight;
    }
}

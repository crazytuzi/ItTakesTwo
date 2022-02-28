class ULocomotionFeatureMusicTunnel : UHazeLocomotionFeatureBase 
{
    ULocomotionFeatureMusicTunnel()
    {
        Tag = n"MusicTunnel";
    }

	UPROPERTY()
	FHazePlaySequenceData HitReaction;

	UPROPERTY()
	FHazePlayBlendSpaceData BlendSpace;

	UPROPERTY(Category="Tricks")
	FHazePlaySequenceData Trick01;

	UPROPERTY(Category="Tricks")
	FHazePlaySequenceData Trick02;

	UPROPERTY(Category="Tricks")
	FHazePlaySequenceData Trick03;
}
class ASleepingDino : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UPROPERTY()
	UAnimSequence AwakeMH;

	UFUNCTION()
	void OpenMouth()
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = AwakeMH;
		Params.bLoop = true;
		Params.BlendTime = 0.f;
		Mesh.PlaySlotAnimation(Params);
	}
}
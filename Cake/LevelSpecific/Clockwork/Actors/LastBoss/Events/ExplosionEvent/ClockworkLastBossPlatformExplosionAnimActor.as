class AClockworkLastBossPlatformExplosionAnimActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY()
	UAnimSequence Anim;

	UFUNCTION()
	void BlowUpPlatform()
	{
		SetActorHiddenInGame(false);
		PlaySlotAnimation(Animation = Anim, bPauseAtEnd = true);
	}
}
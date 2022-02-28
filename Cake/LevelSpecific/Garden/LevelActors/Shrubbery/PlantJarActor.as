
class APlantJarActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UAnimSequence ClosedAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UAnimSequence OpenMHAnim;

	UFUNCTION(BlueprintCallable)
	void SetOpenIdleState()
	{
		if(OpenMHAnim == nullptr)
			return;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.bLoop = true;
		AnimParams.Animation = OpenMHAnim;

		SkelMesh.PlaySlotAnimation(AnimParams);
	}
}
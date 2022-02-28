import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.ParentBlobKineticBase;

class AParentBlobKineticRubble : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UParentBlobKineticInteractionComponent Interaction;
	default Interaction.bBeginAsValidInteraction = false;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence Animation;

	UPROPERTY()
	FParentBlobKineticInteractionCompletedSignature OnCompleted;

	float AnimPos = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnCompleted.AddUFunction(this, n"Completed");
	}

	UFUNCTION(NotBlueprintCallable)
	void Completed(FParentBlobKineticInteractionCompletedDelegateData Data)
	{
		SetActorTickEnabled(false);
		OnCompleted.Broadcast(Data);

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Animation;
		AnimParams.BlendTime = 0.f;
		AnimParams.StartTime = AnimPos;
		AnimParams.bPauseAtEnd = true;
		AnimParams.PlayRate = 0.5f;
		SkelMesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), AnimParams);
	}

	UFUNCTION()
	void EnableInteraction()
	{
		Interaction.MakeAvailableAsTarget(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float TotalAlpha = Interaction.GetCurrentProgress();
		AnimPos = FMath::Lerp(Animation.PlayLength, 1.15f, TotalAlpha);
		SkelMesh.SetSlotAnimationPosition(Animation, AnimPos);
	}
}
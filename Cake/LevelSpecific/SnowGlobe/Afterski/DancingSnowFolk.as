import Vino.Interactions.InteractionComponent;

struct FSnowFolkDanceAnimation
{
	UPROPERTY()
	UAnimSequence Animation = nullptr;

	UPROPERTY()
	float PlayRate = 1.f;
}

class ADancingSnowFolk : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent Collision;

	UPROPERTY(Category = "Snowfolk")
	USkeletalMesh SnowFolkMesh;

	UPROPERTY(Category = "Snowfolk")
	TArray<FSnowFolkDanceAnimation> DanceAnimations;

	int AnimationIndex;
	TArray<int> AnimationSequence;
	FSnowFolkDanceAnimation AnimationData;
	bool bIsDancing = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.SetSkeletalMesh(SnowFolkMesh);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (HasControl())
		{
			TArray<int> Sequence;
			for (int i = 0; i < DanceAnimations.Num() * 3; ++i)
				Sequence.Add(i % DanceAnimations.Num());
			Sequence.Shuffle();

			NetSetAnimationSequence(Sequence);
		}
	}

	UFUNCTION()
	void PlayNextAnimation()
	{
		if (DanceAnimations.Num() <= 0 || AnimationSequence.Num() <= 0 || !bIsDancing)
			return;

		// Check if we've wrapped, in which case we want to update the animation order
		if (HasControl() && AnimationIndex >= AnimationSequence.Num())
		{
			AnimationSequence.Shuffle();
			NetSetAnimationSequence(AnimationSequence);
		}

		AnimationIndex = ++AnimationIndex % AnimationSequence.Num();
		AnimationData = DanceAnimations[AnimationSequence[AnimationIndex]];

		FHazeSlotAnimSettings AnimSettings;
		AnimSettings.PlayRate = AnimationData.PlayRate;

		PlaySlotAnimation(FHazeAnimationDelegate(),
			FHazeAnimationDelegate(this, n"PlayNextAnimation"),
			AnimationData.Animation, AnimSettings);
	}

	UFUNCTION(NetFunction)
	void NetSetAnimationSequence(TArray<int> NewSequence)
	{
		AnimationIndex = 0;
		AnimationSequence = NewSequence;

		if (!bIsDancing)
		{
			bIsDancing = true;
			PlayNextAnimation();
		}
	}
}
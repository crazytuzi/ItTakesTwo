import Vino.Pickups.PickupActor;

class AFuseCrab : APickupActor
{
	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;

	UPROPERTY(Category = "Animations")
	UAnimSequence DazedAnimation;

	UPROPERTY(Category = "Animations")
	UAnimSequence PickedUpAnimation;

	UPROPERTY(DefaultComponent, Attach = PickupRoot)
	UHazeAkComponent FuseHazeAkComp;

	UFUNCTION()
	void EnableCrab()
	{
		if (IsActorDisabled())
		{
			EnableActor(nullptr);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Mesh.SetCollisionProfileName(n"BlockAllDynamic");
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void OnPickedUp(AHazePlayerCharacter Player) override
	{
		Super::OnPickedUp(Player);

		FHazePlaySlotAnimationParams AnimationParams;
		AnimationParams.Animation = PickedUpAnimation;
		AnimationParams.bLoop = true;
		AnimationParams.BlendTime = 0.6f;

		GetSkeletalPickupMeshComponent().PlaySlotAnimation(AnimationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnPutDown(AHazePlayerCharacter Player) override
	{
		FHazeStopSlotAnimationByAssetParams AssetParams;
		AssetParams.Animation = PickedUpAnimation;
		AssetParams.BlendTime = 0.f;
		GetSkeletalPickupMeshComponent().StopSlotAnimationByAsset(AssetParams);

		FHazePlaySlotAnimationParams AnimationParams;
		AnimationParams.Animation = DazedAnimation;
		AnimationParams.bLoop = true;
		AnimationParams.BlendTime = 0.6f;

		GetSkeletalPickupMeshComponent().PlaySlotAnimation(AnimationParams);

		// Call super method last to ensure slot animation stops
		// if fuse crab was inserted into socket
		Super::OnPutDown(Player);
	}
}
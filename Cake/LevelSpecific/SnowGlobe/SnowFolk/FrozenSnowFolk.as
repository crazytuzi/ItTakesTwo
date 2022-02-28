class AFrozenSnowFolk : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USkeletalMeshComponent SkeletalMeshComponent;
	default SkeletalMeshComponent.CollisionProfileName = n"NoCollision";
	default SkeletalMeshComponent.bGenerateOverlapEvents = false;
	default SkeletalMeshComponent.RelativeScale3D = FVector(0.8f);
	default SkeletalMeshComponent.AnimationMode = EAnimationMode::AnimationSingleNode;
	default SkeletalMeshComponent.AnimationData.SavedPlayRate = 0.f;
	default SkeletalMeshComponent.AnimationData.bSavedPlaying = false;
	default SkeletalMeshComponent.AnimationData.bSavedLooping = false;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent CapsuleComponent;
	default CapsuleComponent.CollisionProfileName = n"BlockAllDynamic";
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default CapsuleComponent.RelativeLocation = FVector::UpVector * 150.f;
	default CapsuleComponent.CapsuleHalfHeight = 200.f;
	default CapsuleComponent.CapsuleRadius = 120.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8400.f;
	
	UPROPERTY(Category = "Snowfolk")
	USkeletalMesh Mesh;

	UPROPERTY(Category = "Snowfolk")
	UMaterialInterface Material;

	UPROPERTY(Category = "Snowfolk")
	UAnimSequence FrozenPose;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (Mesh != nullptr)
		{
			SkeletalMeshComponent.SetSkeletalMesh(Mesh);
		}

		if (Material != nullptr)
		{
			for (int i = 0; i < SkeletalMeshComponent.NumMaterials; ++i)
				SkeletalMeshComponent.SetMaterial(i, Material);
		}

		if (FrozenPose != nullptr)
		{
			SkeletalMeshComponent.AnimationData.AnimToPlay = FrozenPose;
		}
	}
}
import Cake.LevelSpecific.SnowGlobe.SnowFolkCrowd.SnowFolkCrowdMember;
import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkNames;

class AReactionSnowFolk : ASnowFolkCrowdMember
{
	default SetActorTickEnabled(false);
	default SphereCollision.SphereRadius = 200.f;
	default SphereCollision.RelativeLocation = FVector(0.f, 0.f, 200.f);

	UPROPERTY(Category = "Snowfolk")
	USkeletalMesh CharacterMesh;

	UPROPERTY(Category = "Animations")
	UAnimSequence IdleAnim;

	UPROPERTY(Category = "Animations")
	UAnimSequence ReactionAnim;

	UPROPERTY(Category = "Setup")
	bool bIsLeader;

	float MinTimePreReaction = 0.2f; 
	float MaxTimePreReaction = 0.8f; 

	float MinTimePlayReaction = 1.f; 
	float MaxTimePlayReaction = 3.2f; 

	FQuat StartingQuat;
	FQuat LookQuat;
	FHazeAcceleratedQuat AccelQuat;

	float RotationSpeed;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		SkeletalMeshComponent.SetSkeletalMesh(CharacterMesh);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		StartingQuat = SkeletalMeshComponent.WorldRotation.Quaternion();
		AccelQuat.SnapTo(StartingQuat);

		if (!bIsLeader)
			return;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.BlendTime = 0.5f;
		AnimParams.Animation = IdleAnim;
		AnimParams.bLoop = true;

		SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), PlaySlotAnimParams = AnimParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (!bIsLeader)
			return;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.BlendTime = 0.5f;
		AnimParams.Animation = IdleAnim;
		AnimParams.bLoop = true;

		SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(),
		FHazeAnimationDelegate(),
		PlaySlotAnimParams = AnimParams);
	}

	UFUNCTION()
	void ActivateReaction()
	{
		if (!bIsLeader)
			return;

		float Timer = FMath::RandRange(MinTimePreReaction, MaxTimePreReaction);
		System::SetTimer(this, n"DelayedReaction", Timer, false);
	}

	UFUNCTION()
	void ActivateRotationToVector(FVector LookAtLocation, float Time)
	{
		FVector LookLoc = LookAtLocation - SkeletalMeshComponent.WorldLocation; 
		
		LookLoc = LookLoc.ConstrainToPlane(FVector::UpVector);
		LookLoc.Normalize();

		LookQuat = FRotator::MakeFromX(LookLoc).Quaternion();
		
		AccelQuat.SnapTo(ActorRotation.Quaternion());
		RotationSpeed = Time;
	}

	UFUNCTION()
	void DelayedReaction()
	{
		float Timer = FMath::RandRange(MinTimePlayReaction, MaxTimePlayReaction);
		System::SetTimer(this, n"ReturnToIdle", Timer, false);
		
		FHazeAnimationDelegate BlendOut;
		BlendOut.BindUFunction(this, n"ReturnToIdle");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.BlendTime = 0.5f;
		AnimParams.Animation = ReactionAnim;
		AnimParams.bLoop = false;

		SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOut, PlaySlotAnimParams = AnimParams);
	}

	UFUNCTION()
	void ReturnToIdle()
	{
		if (!bIsLeader)
			return;

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.BlendTime = 0.7f;
		AnimParams.Animation = IdleAnim;
		AnimParams.bLoop = true;

		SkeletalMeshComponent.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), PlaySlotAnimParams = AnimParams);
	}
}
import Vino.Animations.PoseTrailComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Animation.FishAnimationComponent;

struct FAnglerFishPoseRotations
{
	UPROPERTY()
	FRotator Tail1;
	UPROPERTY()
	FRotator Tail2;
	UPROPERTY()
	FRotator Tail3;
	UPROPERTY()
	FRotator Tail4;
	UPROPERTY()
	FRotator Tail5;
	UPROPERTY()
	FRotator Tail6;
	UPROPERTY()
	FRotator Tail7;
}

namespace AnglerFishPoseRotations
{
	UFUNCTION()
	void GetAnglerFishPose(UPoseTrailComponent PoseTrail, FAnglerFishPoseRotations& Pose)
	{
		if (PoseTrail == nullptr)
			return;
		PoseTrail.Pose.Find(n"Tail1", Pose.Tail1);
		PoseTrail.Pose.Find(n"Tail2", Pose.Tail2);
		PoseTrail.Pose.Find(n"Tail3", Pose.Tail3);
		PoseTrail.Pose.Find(n"Tail4", Pose.Tail4);
		PoseTrail.Pose.Find(n"Tail5", Pose.Tail5);
		PoseTrail.Pose.Find(n"Tail6", Pose.Tail6);
		PoseTrail.Pose.Find(n"Tail7", Pose.Tail7);
	}
}

class UFishPoseTrailCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Attack");
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 150.f;

	UPoseTrailComponent PoseTrail = nullptr;
	FVector PrevLoc = FVector::ZeroVector;

	UFishAnimationComponent AnimComp = nullptr;
	FHazeAcceleratedRotator BodyDragRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		PoseTrail = UPoseTrailComponent::Get(Owner);
		USkeletalMeshComponent Mesh = USkeletalMeshComponent::Get(Owner);

		AnimComp = UFishAnimationComponent::Get(Owner);

		// Set up pose trail
		float HeadOffsetAlongMesh = PoseTrail.GetBoneOffsetAlongMesh(n"Head", Mesh);
		TArray<FName> Posterior;
		Posterior.Add(n"Tail1");
		Posterior.Add(n"Tail2");
		Posterior.Add(n"Tail3");
		Posterior.Add(n"Tail4");
		Posterior.Add(n"Tail5");
		Posterior.Add(n"Tail6");
		Posterior.Add(n"Tail7");
		PoseTrail.AddBoneBranch(Posterior, Mesh, HeadOffsetAlongMesh);

		PoseTrail.PoseClamps.Add(n"Tail1", FRotator(20.f, 0.f, 20.f));
		PoseTrail.PoseClamps.Add(n"Tail2", FRotator(30.f, 0.f, 30.f));
		PoseTrail.PoseClamps.Add(n"Tail3", FRotator(30.f, 0.f, 30.f));
		PoseTrail.PoseClamps.Add(n"Tail4", FRotator(30.f, 0.f, 30.f));
		PoseTrail.PoseClamps.Add(n"Tail5", FRotator(30.f, 0.f, 30.f));
		PoseTrail.PoseClamps.Add(n"Tail6", FRotator(30.f, 0.f, 30.f));
		PoseTrail.PoseClamps.Add(n"Tail7", FRotator(30.f, 0.f, 30.f));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Always active, run locally
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PrevLoc = Owner.ActorLocation;
		BodyDragRotation.SnapTo(Owner.ActorRotation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Use actor location as trail head (should be close enough)
		FVector CurLoc = Owner.ActorLocation;
		FVector Delta = (CurLoc - PrevLoc);
		PoseTrail.AddTrailPoint(Delta.Size(), Delta.ToOrientationQuat());
		PoseTrail.UpdatePose(FQuat(Owner.ActorRotation), DeltaTime);
		PrevLoc = CurLoc;

		// Set swimming turn blendspace value from lagging rotation
		AnimComp.SetSwimTurn(BodyDragRotation.AccelerateTo(Owner.ActorRotation, 10.f, DeltaTime));

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			PoseTrail.DrawDebug(Owner.ActorLocation - Owner.ActorUpVector * 2000.f);
#endif
	}
}
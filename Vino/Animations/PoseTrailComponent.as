import Peanuts.Spline.SplineComponent;

struct FPoseTrailBone
{
	FName 	 Bone = NAME_None;
	float 	 Distance = 0.f;

	FPoseTrailBone(FName Bone, float Distance)
	{
		this.Bone = Bone;
		this.Distance = Distance;
	}
}

struct FPoseTrailBoneBranch
{
	TArray<FPoseTrailBone> Bones;
}

class UPoseTrailComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	// How far each point will be from previous point in the stored trail
	UPROPERTY()
	float Interval = 10.f;

	// How fast bone rotations interpolate. Higher values means trail will be followed more closely, lower will give more smoothness. 
	UPROPERTY()
	float BoneInterpolationSpeed = 10.f;

	// Rotational pose clamps of bones. If there's no entry for abone it is assumed to be unclamped
	UPROPERTY()
	TMap<FName, FRotator> PoseClamps;

	// Last placed trail point. May be closer to first stored trail point than min interval.
	FQuat TrailHeadRotation;
	float TrailHeadDistance;
	
	// Stored trail point rotations
	TArray<FQuat> Trail;

	// Bone hierarchies extending from the root bone. 
	// Note that each branch does not have any sub-branches, since we currently don't need 
	// it and cannot declare a struct containing an array of itself in .as
	TArray<FPoseTrailBoneBranch> BoneTree; 

	// Rotations of all bones along trail. Updated by UpdatePose.
	UPROPERTY()
	TMap<FName, FRotator> Pose;

	// We only store enough trail points to calculate rotations for any registered bones
	int MaxNumTrailPoints = 0;

	float GetBoneOffsetAlongMesh(FName Bone, USkeletalMeshComponent Mesh)
	{
		if (!ensure(Mesh != nullptr))
			return 0.f;
		FTransform Transform = Mesh.GetSocketTransform(Bone, ERelativeTransformSpace::RTS_Component);
		return Transform.Location.X * Mesh.GetWorldScale().X;
	}

	void AddBoneBranch(TArray<FName> Bones, USkeletalMeshComponent Mesh, float TrailHeadOffsetAlongMesh)
	{
		FPoseTrailBoneBranch Branch;
		for (FName Bone : Bones)
		{
			if (Mesh.DoesSocketExist(Bone))
			{
				float DistanceAlongTrail = TrailHeadOffsetAlongMesh - GetBoneOffsetAlongMesh(Bone, Mesh);
				Branch.Bones.Add(FPoseTrailBone(Bone, DistanceAlongTrail));

				// Store enough points that all bones will fit in an interval when trail is full
				MaxNumTrailPoints = FMath::Max(MaxNumTrailPoints, FMath::CeilToInt(DistanceAlongTrail / Interval) + 2);
			}
		}
		if (Branch.Bones.Num() > 0)
			BoneTree.Add(Branch);
	}

	void AddTrailPoint(float DistanceMoved, const FQuat& Rotation)
	{
		TrailHeadRotation = Rotation;
		TrailHeadDistance += DistanceMoved;

	 	if (Trail.Num() == 0)
		{
			// Start a new trail with a copy of this first point.
			Trail.Add(Rotation);
			return;
		}
		
		if (TrailHeadDistance > Interval)
		{
			// Store a new trail point.  
			float Alpha = Interval / TrailHeadDistance;
			FQuat NewRotation = FQuat::Slerp(Trail[0], Rotation, Alpha);

			// Remove last point if we're about to exceed the number of points necessary to store
			if (Trail.Num() + 1 == MaxNumTrailPoints)
				Trail.RemoveAt(Trail.Num() - 1); 
			Trail.Insert(NewRotation, 0);

			TrailHeadDistance -= Interval;
		}
	}

	void UpdatePose(const FQuat& RootBoneRotation, float DeltaTime)
	{
		if (!ensure(Interval > 0.f))
			return; 
		if (!ensure(Trail.Num() > 0))
			return;

		// Update tree
		for (const FPoseTrailBoneBranch& Branch : BoneTree)
		{
			if (Branch.Bones.Num() == 0)
				continue;

			FQuat WorldToActorSpace = RootBoneRotation.Inverse();
			FQuat ParentRot = FQuat::Identity;
			for (int i = 0; i < Branch.Bones.Num(); i++)
			{
				// Target rotation in world space
				FQuat WorldRot = GetRotationAtDistanceAlongTrail(Branch.Bones[i].Distance);

				// Target rotation in actor space
				FQuat ActorLocalRot = WorldToActorSpace * WorldRot;

				// Interpolate rotation in parent bone space
				FQuat ParentLocalRot = ActorLocalRot * ParentRot.Inverse();
				FRotator PrevRot = ParentLocalRot.Rotator();
				Pose.Find(Branch.Bones[i].Bone, PrevRot);
				ParentLocalRot = FQuat::Slerp(FQuat(PrevRot), ParentLocalRot, DeltaTime * BoneInterpolationSpeed);

				// Clamp rotation if applicable
				FName Bone = Branch.Bones[i].Bone;
				FRotator ClampedRot = ParentLocalRot.Rotator();
				if (PoseClamps.Contains(Bone))
				{
					FRotator Clamps = PoseClamps[Bone];
					ClampedRot.Yaw = FMath::ClampAngle(ClampedRot.Yaw, -Clamps.Yaw, Clamps.Yaw);
					ClampedRot.Pitch = FMath::ClampAngle(ClampedRot.Pitch, -Clamps.Pitch, Clamps.Pitch);
					ClampedRot.Roll = FMath::ClampAngle(ClampedRot.Roll, -Clamps.Roll, Clamps.Roll);
				}
				Pose.Add(Bone, ClampedRot);

				ParentRot = ActorLocalRot;
			}
		}
	}

	void BlendOutPose(float BlendSpeed, float DeltaTime)
	{
		for (auto& BonePose : Pose)
		{
			BonePose.Value = FQuat::Slerp(FQuat(BonePose.Value), FQuat::Identity, BlendSpeed * DeltaTime).Rotator();
		}
	}	

	FQuat GetRotationAtDistanceAlongTrail(float DistanceAlongTrail)
	{
		if (DistanceAlongTrail < TrailHeadDistance)
		{
			// In trail head interval
			return FQuat::Slerp(TrailHeadRotation, Trail[0], DistanceAlongTrail / TrailHeadDistance);
		}

		// After trail head interval
		float TrailDistance = DistanceAlongTrail - TrailHeadDistance;
		int NumIntervals = FMath::TruncToInt(TrailDistance / Interval);
		if (NumIntervals > Trail.Num() - 2)
		{
			// After end of trail
			return Trail.Last();
		}

		// In between two trail points
		float Alpha = FMath::Fmod(DistanceAlongTrail, Interval) / Interval;
		return FQuat::Slerp(Trail[NumIntervals], Trail[NumIntervals + 1], Alpha);
	}

	void DrawDebugAlongSpline(UHazeSplineComponent Spline, float HeadDistanceAlongSpline, FVector Offset = FVector::ZeroVector, USkeletalMeshComponent Mesh = nullptr)
	{
		if (Spline == nullptr)
			return;

		Debug::DrawDebugSpline(Spline, FLinearColor::Yellow, bShowRotation = true);

		// Draw trail
		DrawDebugTrailPointAlongSpline(Spline, HeadDistanceAlongSpline, TrailHeadRotation, Offset);
		float Distance = FMath::Fmod(HeadDistanceAlongSpline - TrailHeadDistance, Spline.GetSplineLength());	
		for (const FQuat& Rotation : Trail)
		{
			DrawDebugTrailPointAlongSpline(Spline, Distance, Rotation, Offset);	
			Distance = FMath::Fmod(Distance - Interval, Spline.GetSplineLength());
		}

		DrawDebugPose(Mesh, Offset);
	}

	void DrawDebugTrailPointAlongSpline(UHazeSplineComponent Spline, float DistanceAlongSpline, FQuat Rotation, FVector Offset)
	{
		FTransform SplineTransform = Spline.GetTransformAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector Location = SplineTransform.TransformPosition(Offset);
		DrawDebugTrailPoint(Location, Rotation, FLinearColor::Green); 
	}

	void DrawDebug(FVector HeadLocation)
	{
		DrawDebugTrailPoint(HeadLocation, TrailHeadRotation, FLinearColor::Green);
		FVector Location = HeadLocation - TrailHeadRotation.Vector() * TrailHeadDistance;	
		for (const FQuat& Rotation : Trail)
		{
			DrawDebugTrailPoint(Location, Rotation, FLinearColor::Green);	
			Location -= Rotation.Vector() * Interval;	
		}
	}

	void DrawDebugTrailPoint(FVector Location, FQuat Rotation, FLinearColor Color)
	{
		System::DrawDebugArrow(Location, Location + Rotation.Vector() * Interval * 0.2f, 20.f, Color, 0.f, 5.f);
		System::DrawDebugLine(Location, Location + FVector(0,0,20), Color);
	}

	void DrawDebugPose(USkeletalMeshComponent Mesh, FVector Offset)
	{
		if (Mesh == nullptr)
			return;

		// Draw pose
		FVector WorldOffset = Mesh.Owner.ActorTransform.TransformVector(Offset);
		FQuat ActorToWorld = Mesh.Owner.ActorTransform.Rotation;
		for (FPoseTrailBoneBranch Branch : BoneTree)
		{
			FQuat ParentRot = FQuat::Identity;
			for (FPoseTrailBone Bone : Branch.Bones)
			{
				if (!Mesh.DoesSocketExist(Bone.Bone) || !Pose.Contains(Bone.Bone))
					break; // Branch is broken!
				FVector Loc = Mesh.GetSocketLocation(Bone.Bone) + WorldOffset;
				FQuat Rot = FQuat(Pose[Bone.Bone]);
				Rot = Rot * ParentRot;	
				ParentRot = Rot;			
				Rot = ActorToWorld * Rot;
				System::DrawDebugArrow(Loc, Loc + Rot.Vector() * Interval * 0.3f, 30.f, FLinearColor::Red, 0.f, 5.f);
				System::DrawDebugLine(Loc, Loc - WorldOffset, FLinearColor::Red, 0.f, 3.f);
			}
		}
	}
}
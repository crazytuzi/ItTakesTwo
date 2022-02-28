
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.Attack.SwarmPlayerTakeDamageResponseCapability;
import Cake.LevelSpecific.Tree.Swarm.Collision.SwarmColliderComponent;

/*
	This collider is used to determine when match/sap intersects the swarm.

	We prefer to use a box collision rather then the skelmesh because
	we want to ensure that UE4 doesn't do anything expensive due 
	to the mesh having 120 bones. 

	And we can have multiple swarm skelmeshes on 1 actor.
*/

class USwarmCoreUpdateColliderCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmCollision");
	default CapabilityTags.Add(n"SwarmCoreUpdateCollider");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	// how often the collider should be updated.
	// @TODO: make this based on velocity instead?
	float TimeBetweenUpdates = 1.0f;

	float PerformUpdateThreshold = 35.f;	// ~ Particle diameter
	float PerformUpdateThresholdSQ = FMath::Square(PerformUpdateThreshold);

	float TimestampUpdateExtent = 0.f;
	float TimeSinceParticleNumChanged = 0.f;
	int PrevNumParticlesAlive = 0;

	FVector PrevCenterOfParticles = FVector::ZeroVector;
	FVector PrevExtent = FVector::ZeroVector;

	USwarmColliderComponent Collider = nullptr;
	ASwarmActor SwarmActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);

		// Decrease the chance of all swarms updating the collider at the same frame 
		TimestampUpdateExtent = -FMath::RandRange(0.f, 1.f);

		Collider = SwarmActor.Collider;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		// do an initial update since we offset the updates performed on tick
		const FVector NewExtent = SwarmActor.GetSwarmLocalBoundExtent();
		UpdateColliderExtents(NewExtent);

		TimeSinceParticleNumChanged = TimeBetweenUpdates;
		PrevNumParticlesAlive = SwarmActor.SkelMeshComp.GetNumParticlesAlive();

		PrevCenterOfParticles = SwarmActor.GetSwarmCenterOfParticles();
 	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		// this will update the relative offset from the root (and who knows what else)
		const FVector CurrentCenterOfParticles = SwarmActor.GetSwarmCenterOfParticles();
		const float DeltaMoveSizeSQ = CurrentCenterOfParticles.DistSquared(PrevCenterOfParticles);
		if (DeltaMoveSizeSQ > PerformUpdateThresholdSQ)
		{
			// PrintToScreen("Update location: " + SwarmActor.GetName(), Duration = 0.f);
			Collider.SetWorldLocation(CurrentCenterOfParticles);
			PrevCenterOfParticles = CurrentCenterOfParticles;
		}

		// Update extents based on time or when particles start getting dying 
		const int NumParticlesAlive = SwarmActor.SkelMeshComp.GetNumParticlesAlive();
		const bool bNumParticlesChanged = NumParticlesAlive != PrevNumParticlesAlive;
		if(bNumParticlesChanged)
		{
			const FVector NewExtent = SwarmActor.GetSwarmLocalBoundExtent();
			UpdateColliderExtents(NewExtent);
			PrevNumParticlesAlive = NumParticlesAlive;
		}
		else if(Time::GetGameTimeSince(TimestampUpdateExtent) > TimeBetweenUpdates)
		{
			const FVector NewExtent = SwarmActor.GetSwarmLocalBoundExtent();
			const FVector DeltaExtent = NewExtent - PrevExtent;
			if(!DeltaExtent.IsNearlyZero(PerformUpdateThreshold))
				UpdateColliderExtents(NewExtent);
			TimestampUpdateExtent = Time::GetGameTimeSeconds();
		}

#if EDITOR
		UpdateDebug(DeltaTime);
//		UpdateColliderExtents(SwarmActor.GetSwarmLocalBoundExtent());
#endif

	}

	void UpdateColliderExtents(const FVector& InExtent)
	{
		// PrintToScreen("Update extent: " + SwarmActor.GetName(), Duration = 0.f);

		// if (SwarmActor.bGenerateColliderEvents)
		// {
		// 	Collider.SetGenerateOverlapEvents(true);
		// 	Collider.SetBoxExtent( InExtent, bUpdateOverlaps = true);
		// 	Collider.SetGenerateOverlapEvents(false);
		// }
		// else
		// {
			Collider.SetBoxExtent( InExtent, bUpdateOverlaps = false);
		// }

		PrevExtent = InExtent;
	}

	void UpdateDebug(const float Dt)
	{
//		FVector WorldExtent = SwarmActor.SkelMeshComp.GetWorldBoundExtent();
//		FVector LocalExtent = SwarmActor.SkelMeshComp.GetLocalBoundExtent();
//		float LocalRadius = SwarmActor.SkelMeshComp.GetLocalBoundsRadius();
//		float WorldRadius = SwarmActor.SkelMeshComp.GetBoundsRadius();
//		PrintToScreen("Local extent Size:  " + LocalExtent.Size());
//		PrintToScreen("Local Radius           " + LocalRadius);
//		PrintToScreen("Bounds Radius:      " + WorldRadius);
//		PrintToScreen("World extent Size: " + WorldExtent.Size());
//
//		System::DrawDebugBox(
//			SwarmActor.SkelMeshComp.GetWorldLocation(),
//			WorldExtent,
//			FLinearColor::Red,
//			FRotator::ZeroRotator,
//			0.f,
//			10.f
//		);
//
//		System::DrawDebugBox(
//			Collider.GetWorldLocation(),
//			Collider.GetBoxExtent(),
//			FLinearColor::Red,
//			Collider.GetWorldRotation(),
//			0.f,
//			10.f
//		);
//
//		auto TM_Root = SwarmActor.SkelMeshComp.GetSocketTransform(n"Base");
//		System::DrawDebugCoordinateSystem(
//			TM_Root.GetLocation(),
//			TM_Root.GetRotation().Rotator(),
//			500.f,
//			0.f,
//			20.f
//		);
//
//		auto TM = SwarmActor.SkelMeshComp.GetSocketTransform(n"Align");
//		System::DrawDebugCoordinateSystem(
//			TM.GetLocation(),
//			TM.GetRotation().Rotator(),
//			1000.f,
//			0.f,
//			10.f
//		);
//
//		const FVector AlignOffset = SwarmActor.SkelMeshComp.GetAlignBoneLocalLocation();
//		PrintToScreen("AlignOffset: " + AlignOffset);

//		FName BoneName = SwarmActor.SkelMeshComp.GetBoneName(2);
//		PrintToScreen("" + BoneName, Duration = 0.f);
//		FTransform BoneTM = SwarmActor.SkelMeshComp.GetSocketTransform(BoneName, ERelativeTransformSpace::RTS_World);
//		System::DrawDebugPoint(BoneTM.GetLocation(), 50.f);

		// for(const FSwarmParticle P : SwarmActor.SkelMeshComp.Particles)
		// {
		// 	const int Index = P.Id;
		// 	FName BoneName = SwarmActor.SkelMeshComp.GetParticleBoneName(Index);
		// 	PrintToScreen("Index: " + Index);
		// 	// FName BoneName = SwarmActor.SkelMeshComp.GetParticleBoneName(P.Id);
		// 	FTransform BoneTM = SwarmActor.SkelMeshComp.GetSocketTransform(BoneName, ERelativeTransformSpace::RTS_World);
		// 	// FTransform BoneTM = SwarmActor.SkelMeshComp.GetComponentSpaceTransforms[Index];
		// 	// BoneTM *= SwarmActor.SkelMeshComp.GetComponentSpaceTransforms[0];
		// 	// PrintToScreen("BoneName: " + BoneName + " | " + P.Id);
		// 	System::DrawDebugPoint(BoneTM.GetLocation(), 30.f);
		// 	System::DrawDebugPoint(P.TargetTransform.GetLocation(), 30.f);
		// 	System::DrawDebugPoint(P.CurrentTransform.GetLocation(), 30.f);
		// }

	}

	void DrawExtent(FVector Start, FVector HalfSize, FQuat CapsuleRot)
	{

		//now draw lines from vertices
		TArray<FVector> Vertices;
		Vertices.SetNumZeroed(8);

		Vertices[0] = Start + CapsuleRot.RotateVector(FVector(-HalfSize.X, -HalfSize.Y, -HalfSize.Z));	//flt
		Vertices[1] = Start + CapsuleRot.RotateVector(FVector(-HalfSize.X, HalfSize.Y, -HalfSize.Z));	//frt
		Vertices[2] = Start + CapsuleRot.RotateVector(FVector(-HalfSize.X, -HalfSize.Y, HalfSize.Z));	//flb
		Vertices[3] = Start + CapsuleRot.RotateVector(FVector(-HalfSize.X, HalfSize.Y, HalfSize.Z));	//frb
		Vertices[4] = Start + CapsuleRot.RotateVector(FVector(HalfSize.X, -HalfSize.Y, -HalfSize.Z));	//blt
		Vertices[5] = Start + CapsuleRot.RotateVector(FVector(HalfSize.X, HalfSize.Y, -HalfSize.Z));	//brt
		Vertices[6] = Start + CapsuleRot.RotateVector(FVector(HalfSize.X, -HalfSize.Y, HalfSize.Z));	//blb
		Vertices[7] = Start + CapsuleRot.RotateVector(FVector(HalfSize.X, HalfSize.Y, HalfSize.Z));		//brb


		System::DrawDebugLine(Vertices[0], Vertices[4]);
		System::DrawDebugLine(Vertices[1], Vertices[5]);

		// for (int VertexIdx = 0; VertexIdx < 8; ++VertexIdx)
		// {
		// 	System::DrawDebugLine(
		// 		Vertices[VertexIdx], Vertices[VertexIdx] + TraceVec, Color, bPersistentLines, LifeTime, DepthPriority);
		// }
	}

}



// 
// 
// UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets")
// class UNailWeaponComponent : UHazeSkeletalMeshComponentBase
// {
// 	default bOwnerNoSee = false;
// 	default MeshComponentUpdateFlag = EMeshComponentUpdateFlag::AlwaysTickPose;
// 	default bCastDynamicShadow = true;
// 	default bAffectDynamicIndirectLighting = true;
// 	default SetCollisionProfileName(n"WeaponDefault");
// 	default SetGenerateOverlapEvents(false);
// 	default bCanEverAffectNavigation = false;
// 	default SetAnimationMode(EAnimationMode::AnimationSingleNode);
// 	default SetApplyRootMotionToOwnerRoot(true);
// 	default CollisionEnabled = ECollisionEnabled::QueryAndPhysics;
// 	default SetCollisionProfileName(n"WeaponDefault");
// 	default BodyInstance.bNotifyRigidBodyCollision = true;
// 	default SetGenerateOverlapEvents(true);
// 
// 	// needed for high speed collision. 
// 	// @TODO: Disable it once we no longer use 'Physics' throwing
//   	default BodyInstance.bUseCCD = true;		
// 
// 	UPROPERTY()
// 	float GravityZ = -982.f;
// 
// 	// Settings
// 	//////////////////////////////////////////////////////////////////////////
// 	// Transients
// 
// 	protected TArray<AActor> IgnoreActors;
// 	protected FVector Velocity = FVector::ZeroVector;
// 	protected FVector Acceleration = FVector::ZeroVector;
// 	protected FVector ExternalAccelerations = FVector::ZeroVector;
// 	protected FVector ExternalVelocities = FVector::ZeroVector;
// 	protected bool bSweep = false;
// 
// 	FVector CalculateDeltaMovement(float DeltaTime) const
// 	{
// 		return Velocity * DeltaTime + Acceleration * 0.5 * DeltaTime * DeltaTime;
// 	}
// 
// 	bool SweepDeltaMovement(FVector DeltaMove, TArray<FHitResult>& OutHits) const
// 	{
// // 		const FVector MatchLocation = GetActorLocation();
// 		return System::LineTraceMulti(
// 			MatchLocation,
// 			MatchLocation + DeltaMove,
// 			ETraceTypeQuery::WeaponTrace,
// 			false,
// 			IgnoreActors,
// 			EDrawDebugTrace::None,
// 			OutHits,
// 			true
// 		);
// 	}
// 
// 	void ApplyDeltaMovement(FVector DeltaMovement, float DeltaTime) 
// 	{
// // 		AddActorWorldOffset(DeltaMovement);
// // 		SetActorRotation(Math::MakeRotFromZ(-DeltaMovement));
// 
// 		const FVector Gravity = FVector(0.f, 0.f, GravityZ);
// 		Acceleration = Gravity + ExternalAccelerations;
// 		Velocity += ExternalVelocities;
// 		Velocity += Acceleration * DeltaTime;
// 		ExternalAccelerations = FVector::ZeroVector;
// 		ExternalVelocities = FVector::ZeroVector;
// 	}
// 
// 	FVector GetAcceleration() const 
// 	{
// 		return Acceleration;
// 	}
// 
// 	void AddAcceleration(FVector DeltaAcceleration)
// 	{
// 		ExternalAccelerations += DeltaAcceleration;
// 	}
// 
// 	void AddVelocity(FVector DeltaVelocity)
// 	{
// 		ExternalVelocities += DeltaVelocity;
// 	}
// 
// 	void AddIgnoreActor(AActor ActorToIgnore) 
// 	{
// 		IgnoreActors.AddUnique(ActorToIgnore);
// 	}
// 
// 	void RemoveIgnoreActor(AActor IgnoredActor)
// 	{
// 		IgnoreActors.RemoveSwap(IgnoredActor);
// 	}
// 
// }

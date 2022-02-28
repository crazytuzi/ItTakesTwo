import Cake.Weapons.Hammer.HammerWeaponActor;

UCLASS(HideCategories = "Cooking ComponentReplication Tags AssetUserData Collision Variable Sockets")
class UNailWeaponMovementComponent : UActorComponent
{
	default bAutoActivate = false;

	UPROPERTY(Category = "Physics")
	float GravityZ = -982.f;

	// 0 to 1. Bounciness 
	UPROPERTY(Category = "Physics")
	float Restitution = 0.7f;

	// The nail will always have this initial velocity
	// after colliding for the first time
	UPROPERTY(Category = "Physics")
	float CollisionVelocity = 1300.f;
//	float CollisionVelocity = 2500.f;

	// Settings
	//////////////////////////////////////////////////////////////////////////
	// Transients

	FNailTargetData TargetData;
	float RemainingHomingTime = 0.f;

	protected TArray<AActor> IgnoreActors;
	protected FVector ExternalAccelerations = FVector::ZeroVector;
	protected FVector ExternalVelocities = FVector::ZeroVector;
	FVector Velocity = FVector::ZeroVector;
	FVector Acceleration = FVector::ZeroVector;

	float TimeStampLaunched = 0.f;

	// Transients
	//////////////////////////////////////////////////////////////////////////
	// Functions 

	bool UpdateSweepingMovement(const float Dt, TArray<FHitResult>& OutHits)
	{
		if (TargetData.bHoming)
			RemainingHomingTime -= Dt;

		const FVector DeltaMove = CalculateDeltaMovement(Dt);

#if TEST
		// The sweep will fail if it is zero.
		ensure(!DeltaMove.IsZero());
		ensure(DeltaMove.Size() > KINDA_SMALL_NUMBER);
#endif

		const bool bHit = SweepDeltaMovement(DeltaMove, OutHits);

		// Ignore hammer weapon when aiming for May 
		for (int i = OutHits.Num() - 1; i >= 0 ; i--)
		{
			if(OutHits[i].Actor == nullptr)
				continue;

			if (!OutHits[i].Actor.IsA(AHammerWeaponActor::StaticClass()))
				continue;

			FHitResult HitMayData;
			if(TraceForMay(DeltaMove, OutHits[i].Actor, HitMayData))
			{
				// replace Hammer hit with May Hit
				OutHits[i] = HitMayData;
				break;
			}
		}

#if TEST
		UPrimitiveComponent OwnerRootPrim = Cast<UPrimitiveComponent>(Owner.RootComponent);
		ensure(!OwnerRootPrim.IsSimulatingPhysics());
#endif

		// Make sure that we don't move another step after hitting something
		if (!bHit)
			ApplyDeltaMovement(DeltaMove, Dt);

		// cancel homing in case the nail reaches the auto-aim 
		// component but there is collision to catch the nail
		if(TargetData.bHoming && RemainingHomingTime <= 0.f)
			TargetData.bHoming = false;

		return bHit;
	}

	bool TraceForMay(const FVector& InDeltaMove, AActor InHammerWeapon, FHitResult& InOutMayHitData) const
	{
		const float DeltaMoveSize = InDeltaMove.Size();

		// we got nothing to work with
		if (DeltaMoveSize < SMALL_NUMBER)
			return false;

		// Normalize
		FVector ClampedDeltaMove = InDeltaMove / DeltaMoveSize;

		// Apply MIN trace length
		ClampedDeltaMove *= FMath::Max(DeltaMoveSize, 1000.f);

		const FVector TraceOrigin = GetOwner().GetActorLocation();
		const FVector TraceEnd = TraceOrigin + ClampedDeltaMove;

		const bool bHitMay = Trace::ActorLineTraceSingle(
			Game::GetMay(),
			TraceOrigin,
			TraceEnd,
			ETraceTypeQuery::WeaponTrace,
			false,
			InOutMayHitData
		);

		// TArray<AActor> IgnoreActorsCopy = IgnoreActors;
		// IgnoreActorsCopy.Add(InHammerWeapon);

		// TArray<EObjectTypeQuery> ObjectTypesToLookFor;
		// ObjectTypesToLookFor.Add(EObjectTypeQuery::PlayerCharacter);

		// const bool bHitMay = System::LineTraceSingleForObjects(
		// 	TraceOrigin,
		// 	TraceEnd,
		// 	ObjectTypesToLookFor,
		// 	false,	// complex trace ? 
		// 	IgnoreActorsCopy,
		// 	EDrawDebugTrace::None,
		// 	InOutMayHitData,
		// 	true
		// );

		if (!bHitMay)
			return false;

		// if (InOutMayHitData.Actor == nullptr)
		// 	return false;
		
		// if (InOutMayHitData.Actor != Game::May)
		// 	return false;

		return true;
	}

	void InitHoming(FNailTargetData InTargetData, const float ThrowImpulseMagnitude)
	{
		TargetData = InTargetData;

		if(InTargetData.IsHoming())
		{
			const FVector HomingLocation = TargetData.GetHomingLocation();
			const float DistanceToHomingLocation = HomingLocation.Distance(Owner.GetActorLocation());

//			if(TargetData.GetTargetNormal() != FVector::ZeroVector)
//			{
//				TArray<FVector> SplinePoints;
//
//				SplinePoints.Add(TargetData.StartLocation);
//				SplinePoints.Add(TargetData.GetHomingLocation());
//
//				DistanceToHomingLocation = Math::GetCRSplineLengthConstSpeed(
//					TargetData.StartLocation + (TargetData.Direction * 1000.f),
//					SplinePoints,
//					TargetData.GetHomingLocation() - (TargetData.GetTargetNormal() * 1000.f),
//					1.f
//				);
//			}

			RemainingHomingTime = DistanceToHomingLocation / ThrowImpulseMagnitude;
		}
		else
		{
			RemainingHomingTime = 0.f; 
		}

//		InitHomingTime = RemainingHomingTime;
	}

//	float InitHomingTime = -1.f;

	FVector CalculateDeltaMovement(const float DeltaTime) const
	{
		if (TargetData.IsHoming())
		{
			FVector DeltaMove = TargetData.GetHomingLocation() - Owner.GetActorLocation();

			if(DeltaMove.IsNearlyZero())
			{
				// we can't let the delta be zero. The sweep will fail!
				DeltaMove = Velocity * DeltaTime + Acceleration * 0.5f * DeltaTime * DeltaTime;
			}
			else if (RemainingHomingTime > DeltaTime)
			{
				DeltaMove *= (DeltaTime / RemainingHomingTime);

//				if (TargetData.GetTargetNormal() != FVector::ZeroVector)
//				{
//					TArray<FVector> SplinePoints;
//
//					SplinePoints.Add(TargetData.StartLocation);
//					SplinePoints.Add(TargetData.GetHomingLocation());
//
//					float Alpha = 1.f - (RemainingHomingTime / InitHomingTime);
//					Alpha = FMath::Clamp(Alpha, 0.f, 1.f);
//
//					FVector NewHomingLocation = Math::GetLocationOnCRSplineConstSpeed(
//						TargetData.StartLocation + (TargetData.Direction * 1000.f),
//						SplinePoints,
//						TargetData.GetHomingLocation() - (TargetData.GetTargetNormal() * 1000.f),
//						Alpha
//					);
//					DeltaMove = NewHomingLocation - Owner.GetActorLocation();
//				}
			}

			return DeltaMove;
		}
		else
		{
			return Velocity * DeltaTime + Acceleration * 0.5f * DeltaTime * DeltaTime;
		}
	}

	bool SweepDeltaMovement(FVector DeltaMove, TArray<FHitResult>& OutHits) const
	{
 		const FVector TraceOrigin = GetOwner().GetActorLocation();

#if TEST
		// trace will fail if it is to small
		ensure(!FMath::IsNearlyZero(DeltaMove.Size()));
#endif

		bool bBlockingHit = System::LineTraceMulti(
			TraceOrigin,
			TraceOrigin + DeltaMove,
			ETraceTypeQuery::WeaponTrace,

			// TRACE COMPLEX? It might return faulty hitresults normal point upwards
			// true,
			false,

			IgnoreActors,
			EDrawDebugTrace::None,
			OutHits,
			true
		);

		// retrace penetrating hits due to ImpactNormal == -TraceDirection
		if(bBlockingHit)
		{
			for (int i = OutHits.Num() - 1; i >= 0 ; i--)
			{
				// we do multi trace so we might have overlap hits that aren't blocking?
				if (!OutHits[i].bBlockingHit)
					continue;

				// we only need to replace penetrating hits
				if (!OutHits[i].bStartPenetrating)
					continue;

				// BSPs might be nullptr..
				if (OutHits[i].Actor == nullptr || OutHits[i].Component == nullptr)
					continue;

				// hit something else while homing?
				if(OutHits[i].Component != TargetData.Component)
					continue;

				// ignore auto aim
				if(!OutHits[i].Component.IsA(UPrimitiveComponent::StaticClass()))
					continue;

				// only interested in homing hits
				if(!TargetData.IsHoming() && !TargetData.bWasHoming)
					continue;

				// we need that normal!
				if(TargetData.GetTargetNormal() == FVector::ZeroVector)
					continue;

//				FVector DebugStart = TraceOrigin;
//				FVector DebugEnd  = TraceOrigin + (DeltaMove * 10000.f);
//				System::DrawDebugLine(
//					DebugStart,
//					DebugEnd,
//					FLinearColor::Blue, 10.f, 10.f);

				bBlockingHit = RetracePenetratingHit(OutHits[i]);

				break;
			}

		}

		return bBlockingHit;
	}

	bool RetracePenetratingHit(FHitResult& InOutHitData) const
	{
		ensure(InOutHitData.bStartPenetrating);
		ensure(TargetData.IsHoming() || TargetData.bWasHoming);

		const FVector DeltaTrace = InOutHitData.TraceEnd - InOutHitData.TraceStart;
		const float DeltaTraceMagnitude = DeltaTrace.Size();

		if(DeltaTraceMagnitude < SMALL_NUMBER)
		{
			// our trace are always supposed to be at least KINDA_SMALL_NUMBER in size... What happened!?
			ensure(false);
			return InOutHitData.bBlockingHit;
		}

		float DepenetrationDistance = FMath::Max(DeltaTraceMagnitude, FMath::Abs(InOutHitData.PenetrationDepth));
		DepenetrationDistance = FMath::Max(DepenetrationDistance, 1000.f);

		const FVector HomingTargetLocation = TargetData.GetHomingLocation();
		const FVector HomingTargetNormal = TargetData.GetTargetNormal();

		ensure(HomingTargetNormal != FVector::ZeroVector);

		const FVector NewTraceStart = HomingTargetLocation + (HomingTargetNormal * DepenetrationDistance);
		const FVector NewTraceEnd = HomingTargetLocation - (HomingTargetNormal * DepenetrationDistance);

		FHitResult NewHitData;
		FName DummySocketName = NAME_None;
		FVector DummyLocation, DummyNormal = FVector::ZeroVector; 
		const bool bComponentHit = InOutHitData.Component.LineTraceComponent(
			NewTraceStart,
			NewTraceEnd,
			false, 	// bTraceComplex = true,
			false, 	// bShowtrace = false,
			false, 	// bPersistenShowTrace = false,
			DummyLocation,
			DummyNormal,
			DummySocketName,
			NewHitData
		);

		ensure(bComponentHit);

//		System::DrawDebugLine(
//			NewHitData.ImpactPoint,
//			NewHitData.ImpactPoint + NewHitData.ImpactNormal * 1000.f,
//			 FLinearColor::Red, 10.f, 10.f);
//
//		System::DrawDebugLine(
//			InOutHitData.ImpactPoint,
//			InOutHitData.ImpactPoint + InOutHitData.ImpactNormal * 2000.f,
//			 FLinearColor::Yellow, 10.f, 5.f);

		ensure(!NewHitData.bStartPenetrating);

		// it doesn't update bBlockingHit for some reasons
		NewHitData.SetBlockingHit(bComponentHit);

		// only replace when successful. It will fail in the case the target component rotates really 
		// fast and hits the nail from behind before it actually reaches the target location. 
		if(bComponentHit)
			InOutHitData = NewHitData;

		return bComponentHit;
	}

	void ApplyDeltaMovement(FVector DeltaMovement, float DeltaTime) 
	{

		GetOwner().AddActorWorldOffset(DeltaMovement);
		GetOwner().SetActorRotation(Math::MakeRotFromZ(-DeltaMovement));

#if TEST
		UPrimitiveComponent OwnerRootPrim = Cast<UPrimitiveComponent>(Owner.RootComponent);
		ensure(!OwnerRootPrim.IsSimulatingPhysics());
		ensure(DeltaMovement != FVector::ZeroVector);
#endif

		const FVector Gravity = FVector(0.f, 0.f, GravityZ);
		const FVector NewAcceleration = Gravity + ExternalAccelerations;

		if(TargetData.IsHoming())
		{
			Velocity = DeltaMovement / DeltaTime;
		}
		else
		{
			Velocity += ExternalVelocities;		// This is incorrect, but it's only for impulses so it's fine
			Velocity += (Acceleration + NewAcceleration) * 0.5f * DeltaTime;
		}

		Acceleration = NewAcceleration;
		ExternalAccelerations = FVector::ZeroVector;
		ExternalVelocities = FVector::ZeroVector;
	}

	void AddCollisionBounce(const FVector& ImpactNormal)
	{
		// Clamp the velocity because its to damn high!
		Velocity = Velocity.GetClampedToMaxSize(CollisionVelocity);

		// Collision response. Bounce velocity after the impact using coefficient of restitution.
		const FVector ProjectedVelocity = Velocity.ProjectOnToNormal(ImpactNormal);
		Velocity += (ProjectedVelocity * -1.f * (1.f + Restitution));
	}

	void AddAcceleration(FVector DeltaAcceleration)
	{
		ExternalAccelerations += DeltaAcceleration;
	}

	void AddVelocity(FVector DeltaVelocity)
	{
		ExternalVelocities += DeltaVelocity;
	}

	void ResetPhysics() 
	{
		ExternalVelocities = ExternalAccelerations = Velocity = Acceleration = FVector::ZeroVector;
	}

	void AddIgnoreActor(AActor ActorToIgnore) 
	{
		IgnoreActors.AddUnique(ActorToIgnore);
	}

	void RemoveIgnoreActor(AActor IgnoredActor)
	{
		IgnoreActors.RemoveSwap(IgnoredActor);
	}

}

struct FNailTargetData
{
	bool bHoming = false;
	bool bWasHoming = false;

	FVector Direction;

	FVector TraceEnd;
	USceneComponent Component;
	FName Socket = NAME_None;
	FVector RelativeLocation;
	FVector RelativeNormal;

	bool IsHoming() const
	{
		// the actor might get destroyed while homing 
		if (Component == nullptr)
			return false;

		return bHoming;
	}

	void SetTargetLocation(
		const FVector& InWorldPos,
		const FVector& InWorldNormal,
		USceneComponent InComp,
		FName InSocketName = NAME_None
	) 
	{
		if(!ensure(InComp != nullptr))
			return;

		Component = InComp;
		Socket = InSocketName;

		RelativeLocation = InComp.GetSocketTransform(InSocketName).InverseTransformPosition(InWorldPos);

		if (InWorldNormal != FVector::ZeroVector)
			RelativeNormal = Component.GetSocketQuaternion(InSocketName).UnrotateVector(InWorldNormal);
	}

	FVector GetTargetNormal() const
	{
		// auto aim doesn't have an impact normal
		if(RelativeNormal == FVector::ZeroVector)
			return FVector::ZeroVector;

		ensure(IsHoming() || bWasHoming);

		return Component.GetSocketQuaternion(Socket).RotateVector(RelativeNormal); 
	}

	FVector GetTargetLocation() const
	{
		if(IsHoming())
			return GetHomingLocation();

		return TraceEnd;
	}

	FVector GetHomingLocation() const
	{

#if TEST 
		// we should check IsHoming() before calling this function.
		ensure(bHoming || bWasHoming);
		ensure(Component != nullptr);
#endif TEST

		return Component.GetSocketTransform(Socket).TransformPosition(RelativeLocation);
	}
};


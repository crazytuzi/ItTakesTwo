import Vino.Movement.Components.MovementComponent;

struct FFreeSightToActivationPointParams
{
	TArray<AActor> IgnoredActors = TArray<AActor>();
	TSubclassOf<AActor> IgnoredActorClass = nullptr;

	FName TraceFromPlayerBone = NAME_None;

	float TrazeFromZOffset = 10.f;
	float SphereRadius = 0;
	bool bIgnoreAttachParent = true;
	bool bOnlyValidIfParentComponentIsHit = false;
}

namespace ActivationPointsStatics
{
	bool HasFreeSightToActivationPoint(AHazePlayerCharacter Player, FHazeQueriedActivationPoint QueryPoint, FFreeSightToActivationPointParams FreeSightToActivationParams = FFreeSightToActivationPointParams())
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		
		FHazeTraceParams Settings;
		Settings.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		Settings.IgnoreActor(Game::May);
		Settings.IgnoreActor(Game::Cody);
		Settings.SetToLineTrace();

		// Setup Ignores
		AActor PointOwner = QueryPoint.Point.GetOwner();

		// We require a certain component in the actor to be hit
		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			Settings.IgnoreActor(PointOwner);
		
		// Ignore attach parent if specified
		if(FreeSightToActivationParams.bIgnoreAttachParent)
		{
			AActor AttachParent = PointOwner.GetAttachParentActor();
			if (AttachParent != nullptr)
				Settings.IgnoreActor(AttachParent);
		}

		Settings.IgnoreActors(FreeSightToActivationParams.IgnoredActors);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		// Setup trace target
		Settings.From = Player.ViewLocation;

		// Setup to location
		Settings.To = QueryPoint.Transform.GetLocation();

		// Make the trace
		FHazeHitResult HitResult;
		const bool bImpact = Settings.Trace(HitResult);

		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			return !bImpact;

		if(!ComponentIsParentComponent(HitResult.Component, QueryPoint))
			return false;

		return true;
	}

	bool CanPlayerReachActivationPoint(AHazePlayerCharacter Player, FHazeQueriedActivationPoint QueryPoint, FFreeSightToActivationPointParams FreeSightToActivationParams = FFreeSightToActivationPointParams())
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);

		FHazeTraceParams Settings;
		Settings.DebugDrawTime = -1.f;

		Settings.InitWithMovementComponent(MoveComp);
		Settings.UnmarkToTraceWithOriginOffset();
		Settings.SetToLineTrace();

		// Setup Ignores
		AActor PointOwner = QueryPoint.Point.GetOwner();

		// We require a certain component in the actor to be hit
		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			Settings.IgnoreActor(PointOwner);

		// Ignore attach parent if specified
		if(FreeSightToActivationParams.bIgnoreAttachParent)
		{		
			AActor AttachParent = PointOwner.GetAttachParentActor();
			if (AttachParent != nullptr)
				Settings.IgnoreActor(AttachParent);
		}

		Settings.IgnoreActors(FreeSightToActivationParams.IgnoredActors);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		if(FreeSightToActivationParams.TrazeFromZOffset == 0.f)
			Settings.From = Player.GetActorCenterLocation();
		else
			Settings.From = Player.GetActorLocation();

		if(FreeSightToActivationParams.TraceFromPlayerBone != NAME_None)
			Settings.From = Player.Mesh.GetSocketLocation(FreeSightToActivationParams.TraceFromPlayerBone);

		Settings.From += MoveComp.WorldUp * FreeSightToActivationParams.TrazeFromZOffset;

		// Setup to location
		Settings.To = QueryPoint.Transform.GetLocation();

		// Make the trace
		FHazeHitResult HitResult;
		const bool bImpact = Settings.Trace(HitResult);

		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			return !bImpact;

		if(!ComponentIsParentComponent(HitResult.Component, QueryPoint))
			return false;

		return true;
	}

	bool CanPlayerReachActivationPoint(AHazePlayerCharacter Player, FHazeQueriedActivationPoint QueryPoint, ETraceTypeQuery TraceChannel, FFreeSightToActivationPointParams FreeSightToActivationParams = FFreeSightToActivationPointParams())
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		
		FHazeTraceParams Settings;
		Settings.InitWithTraceChannel(TraceChannel);
		Settings.UnmarkToTraceWithOriginOffset();
		Settings.SetToLineTrace();

		// Setup Ignores
		Settings.IgnoreActor(Player);

		AActor PointOwner = QueryPoint.Point.GetOwner();

		// We require a certain component in the actor to be hit
		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			Settings.IgnoreActor(PointOwner);
		
		// Ignore attach parent if specified
		if(FreeSightToActivationParams.bIgnoreAttachParent)
		{
			AActor AttachParent = PointOwner.GetAttachParentActor();
			if (AttachParent != nullptr)
				Settings.IgnoreActor(AttachParent);
		}

		Settings.IgnoreActors(FreeSightToActivationParams.IgnoredActors);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		if(FreeSightToActivationParams.TrazeFromZOffset == 0.f)
			Settings.From = Player.GetActorCenterLocation();
		else
			Settings.From = Player.GetActorLocation();

		if(FreeSightToActivationParams.TraceFromPlayerBone != NAME_None)
			Settings.From = Player.Mesh.GetSocketLocation(FreeSightToActivationParams.TraceFromPlayerBone);

		Settings.From += MoveComp.WorldUp * FreeSightToActivationParams.TrazeFromZOffset;

		// Setup to location
		Settings.To = QueryPoint.Transform.GetLocation();

		// Make the trace
		FHazeHitResult HitResult;
		const bool bImpact = Settings.Trace(HitResult);

		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			return !bImpact;

		if(!ComponentIsParentComponent(HitResult.Component, QueryPoint))
			return false;

		return true;
	}

	bool CanPlayerReachActivationPoint_Async(AHazePlayerCharacter Player, FHazeQueriedActivationPoint& QueryPoint, ETraceTypeQuery TraceChannel, FFreeSightToActivationPointParams FreeSightToActivationParams = FFreeSightToActivationPointParams())
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		
		FHazeTraceParams Settings;
		Settings.InitWithTraceChannel(TraceChannel);
		Settings.UnmarkToTraceWithOriginOffset();
		Settings.SetToLineTrace();

		// Setup Ignores
		Settings.IgnoreActor(Player);

		AActor PointOwner = QueryPoint.Point.GetOwner();

		// We require a certain component in the actor to be hit
		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			Settings.IgnoreActor(PointOwner);
		
		// Ignore attach parent if specified
		if(FreeSightToActivationParams.bIgnoreAttachParent)
		{
			AActor AttachParent = PointOwner.GetAttachParentActor();
			if (AttachParent != nullptr)
				Settings.IgnoreActor(AttachParent);
		}

		Settings.IgnoreActors(FreeSightToActivationParams.IgnoredActors);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		if(FreeSightToActivationParams.TrazeFromZOffset == 0.f)
			Settings.From = Player.GetActorCenterLocation();
		else
			Settings.From = Player.GetActorLocation();

		if(FreeSightToActivationParams.TraceFromPlayerBone != NAME_None)
			Settings.From = Player.Mesh.GetSocketLocation(FreeSightToActivationParams.TraceFromPlayerBone);

		Settings.From += MoveComp.WorldUp * FreeSightToActivationParams.TrazeFromZOffset;
		Settings.MakeFromRelative(Player.RootComponent);

		// Setup to location
		Settings.To = QueryPoint.Transform.GetLocation();
		Settings.MakeToRelative(QueryPoint.GetPoint());

		// Make the trace
		FHitResult HitResult;
		const bool bImpact = QueryPoint.AsyncTrace(Player, Settings, HitResult) == EHazeActivationAsyncStatusType::TraceFoundCollision;

		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			return !bImpact;

		if(!ComponentIsParentComponent(HitResult.Component, QueryPoint))
			return false;

		return true;
	}

	bool CanPlayerReachActivationPoint_Expensive(AHazePlayerCharacter Player, FHazeQueriedActivationPoint QueryPoint, FFreeSightToActivationPointParams FreeSightToActivationParams = FFreeSightToActivationPointParams())
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		
		float Radius = 0;
		float HalfHeight = 0;
		Player.GetCollisionSize(Radius, HalfHeight);

		FHazeTraceParams Settings;
		Settings.InitWithMovementComponent(MoveComp);
		Settings.UnmarkToTraceWithOriginOffset();

		// Setup Ignores
		AActor PointOwner = QueryPoint.Point.GetOwner();

		// We require a certain component in the actor to be hit
		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			Settings.IgnoreActor(PointOwner);
		
		// Ignore attach parent if specified
		if(FreeSightToActivationParams.bIgnoreAttachParent)
		{
			AActor AttachParent = PointOwner.GetAttachParentActor();
			if (AttachParent != nullptr)
				Settings.IgnoreActor(AttachParent);
		}

		Settings.IgnoreActors(FreeSightToActivationParams.IgnoredActors);

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			Settings.IgnoreActor(ActivePoint.GetOwner());

		// Setup trace target
		Settings.From = Player.GetActorCenterLocation();

		// Setup to location
		Settings.To = QueryPoint.Transform.GetLocation();
		Settings.To += MoveComp.WorldUp * HalfHeight;

		// Make the trace
		if (FreeSightToActivationParams.SphereRadius > 0.f)
		{
			Settings.TraceShape = FCollisionShape::MakeSphere(FreeSightToActivationParams.SphereRadius);
		}
		else
		{
			HalfHeight -= 10.f; // We use a safe margin to not hit the ground
			Settings.TraceShape = FCollisionShape::MakeCapsule(Radius, HalfHeight);
		}

		FHazeHitResult HitResult;
		const bool bImpact = Settings.Trace(HitResult);

		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			return !bImpact;

		if(!ComponentIsParentComponent(HitResult.Component, QueryPoint))
			return false;

		return true;
	}

	bool CanPlayerReachActivationPoint_ExpensiveSphereTrace(AHazePlayerCharacter Player, FHazeQueriedActivationPoint QueryPoint, ETraceTypeQuery TraceChannel, FFreeSightToActivationPointParams FreeSightToActivationParams = FFreeSightToActivationPointParams())
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Player);
		
		float Radius = 0;
		float HalfHeight = 0;
		TArray<AActor> IgnoredActors = FreeSightToActivationParams.IgnoredActors;
		Player.GetCollisionSize(Radius, HalfHeight);

		FMovementQueryParams Settings;

		// Setup Ignores
		AActor PointOwner = QueryPoint.Point.GetOwner();

		// We require a certain component hit to be valid
		if(!FreeSightToActivationParams.bOnlyValidIfParentComponentIsHit)
			IgnoredActors.Add(PointOwner);

		IgnoredActors.Add(Player);
		IgnoredActors.Add(Player.OtherPlayer);

		// Ignore attach parent if specified
		if(FreeSightToActivationParams.bIgnoreAttachParent)
		{
			AActor AttachParent = PointOwner.GetAttachParentActor();
			if (AttachParent != nullptr)
				IgnoredActors.Add(AttachParent);
		}

		UHazeActivationPoint ActivePoint = Player.GetActivePoint();
		if (ActivePoint != nullptr)
			IgnoredActors.Add(ActivePoint.Owner);

		// Setup trace origin
		FVector From = Player.GetActorCenterLocation();

		// Setup trace target
		FVector To;
		To = QueryPoint.Transform.GetLocation();
		To += MoveComp.WorldUp * HalfHeight;

		// Make the trace
		FHitResult HitResult;
		if(System::SphereTraceSingle(From, To, FreeSightToActivationParams.SphereRadius, TraceChannel, false, IgnoredActors, EDrawDebugTrace::None, HitResult, true))
			if(FreeSightToActivationParams.IgnoredActorClass.IsValid() && HitResult.Actor != nullptr)
				return HitResult.Actor.IsA(FreeSightToActivationParams.IgnoredActorClass);
			else
				return false;

		return true;
	}

	bool ComponentIsParentComponent(UPrimitiveComponent ImpactComponent, FHazeQueriedActivationPoint QueryPoint)
	{		
		// The current parent is not a primitive component so we point is valid
		auto ParentComponent = Cast<UPrimitiveComponent>(QueryPoint.Point.GetAttachParent());
		if(ParentComponent == nullptr)
			return true;

		return ImpactComponent == ParentComponent;
	}

	bool IsInsideConeValidation(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float ValidationAngle, float MaxLength = -1, float PointRadius = 1)
	{
		const FVector WorldUp = Player.GetMovementWorldUp();

		// Initiliaze position to test from
		FVector SearchFromPosition = FVector::ZeroVector;
		FVector CameraDirection = Player.ViewRotation.ForwardVector;
		{
			
			FVector CameraLocation = Player.ViewLocation;
			FVector PlayerLocation = Player.GetActorLocation().ConstrainToPlane(WorldUp);
			float HorizontalDistance = CameraLocation.Dist2D(PlayerLocation, WorldUp);	
			SearchFromPosition = CameraLocation + (CameraDirection * HorizontalDistance);
		}

		// Setup search cone
		FHazeIntersectionCone SearchCone;		
		SearchCone.Origin = SearchFromPosition;
		SearchCone.Direction = CameraDirection;
		const float AngleAlpha = FMath::Abs(SearchCone.Direction.DotProduct(WorldUp));
		SearchCone.AngleDegrees = FMath::Lerp(ValidationAngle, ValidationAngle * 0.1f, AngleAlpha);
		SearchCone.MaxLength = MaxLength;
		
		// Setup collision sphere
		FHazeIntersectionSphere QuerySphere;
		QuerySphere.Origin = Query.Transform.GetLocation();
		QuerySphere.Radius = PointRadius;

		// Search cone must overlap the perch radius
		FHazeIntersectionResult Result;
		Result.QuerySphereCone(QuerySphere, SearchCone);

		return Result.bIntersecting;
	}

	/* This function will return a value from 0 to 1 where 1 is the best value
	 * DistanceMax < 0; 100 is used. This value makes the score go up, the closer the target is to the player
	 * CameraMax < 0; 100 is used. This value makes the score go up, the closer the target is to the camera center
	 * InTargetedBonusScore < 0: 5 is used. This value makes the score go up if this was last frames best target
	*/
	float CalculateValidationScoreAlpha(AHazePlayerCharacter Player, FHazeQueriedActivationPoint Query, float CompareDistanceAlpha, float InDistanceMax = -1, float InCameraMax = -1, float InTargetedBonusScore = -1)
	{
		const float DistanceMax = InDistanceMax < 0 ? 100 : InDistanceMax;
		const float CameraMax = InCameraMax < 0 ? 100 : InCameraMax;
		const float TargetedBonusScore = InTargetedBonusScore < 0 ? 5 : InTargetedBonusScore;

		const FVector WorldUp = Player.GetMovementWorldUp();
		const float MaxScore = DistanceMax + CameraMax + TargetedBonusScore;
		if(MaxScore <= 0)
			return 0.f;

		const float DistanceAlpha = (CompareDistanceAlpha + Query.DistanceAlpha) * 0.5f;
		const float DistanceAlphaConverted = 1.f - DistanceAlpha;
		float DistanceScore = DistanceAlphaConverted * DistanceMax;
		FVector CameraDirection = Player.ViewRotation.ForwardVector;
		
		const FVector SearchDirection = CameraDirection.ConstrainToPlane(WorldUp).GetSafeNormal();
		const FVector PointOrigin = Query.Transform.GetLocation();
		const FVector PlayerOrigin = Player.GetActorCenterLocation();

		const FVector DirToPoint = (PointOrigin - PlayerOrigin).GetSafeNormal();
		const float DotValue = DirToPoint.DotProduct(SearchDirection);
		
		// Skip distance score behind that is more behind the player
		if(DotValue <= -0.5f)
			DistanceScore = 0.f;

		// We check if the object is closer to the camera then the player
		const FVector CameraLocation = Player.ViewLocation;
		const float DistanceToPlayerSq = PlayerOrigin.DistSquared(PointOrigin);
		const float DistanceToCameraSq = CameraLocation.DistSquared(PointOrigin);
		if(DistanceToCameraSq * 1.2f < DistanceToPlayerSq)
			DistanceScore = 0.f;

		// Objects that are more focused beneth us are more valid
		const FVector CameraDirectionToTarget = (PointOrigin - CameraLocation).GetSafeNormal();

		FRotator CameraRotation = CameraDirection.Rotation();
		CameraRotation.Pitch += 10.f; 
		CameraDirection = CameraRotation.GetForwardVector();

		const float CameraDot = FMath::Max(CameraDirection.DotProduct(CameraDirectionToTarget), 0.f);

		const float CameraAlpha = FMath::Pow(FMath::SinusoidalIn(0.f, 1.f, CameraDot), 3.f);
	
		// Set the camera score
		float CameraScore = CameraAlpha * CameraMax;

		// Apply Bonus Scores
		float BonusScore = 0;
		if(Query.IsTargeted())
			BonusScore += TargetedBonusScore;

		// Calculate the alpha
		const float TotalScore = DistanceScore + CameraScore + BonusScore;
		return TotalScore / MaxScore;
	}
}

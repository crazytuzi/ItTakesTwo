class UFollowCloudBoundsComponent : UActorComponent
{
	UPROPERTY()
	AActor BoundsCenter = nullptr;

	// 3D radius of ellipsiod, in BoundsCenter local space
	UPROPERTY()
	FVector BoundsEllipsiodRadius = FVector(10000.f, 10000.f, 3700.f);

	// Offset of ellipsoid center in BoundsCenter local space
	UPROPERTY()
	FVector BoundsEllipsoidOffset = FVector(0.f, -500.f, -1000.f);

	// Normal of bottom plane in BoundsCenter local space
	UPROPERTY()
	FVector BoundsPlaneNormal = FVector(0.f, 0.f, 1.f);

	// Offset of bottom plane center in BoundsCenter local space
	UPROPERTY()
	FVector BoundsPlaneOffset = FVector(0.f, 0.f, 0.f);

	FTransform EllipsoidTransform;
	FTransform InverseEllipsoidTransform;
	FVector EllipsoidSpacePlaneCenter;
	FVector EllipsiodSpacePlaneNormal;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Setup();
	}

	void Setup()
	{
		FTransform BoundsTransform = (BoundsCenter != nullptr) ? BoundsCenter.ActorTransform : FTransform::Identity;
		FTransform LocalToEllipsiodTransform = FTransform(FQuat::Identity, BoundsEllipsoidOffset, BoundsEllipsiodRadius);
		EllipsoidTransform = LocalToEllipsiodTransform * BoundsTransform;
		InverseEllipsoidTransform = EllipsoidTransform.Inverse();
		EllipsiodSpacePlaneNormal = LocalToEllipsiodTransform.InverseTransformVector(BoundsPlaneNormal.GetSafeNormal());
		FVector EllipsiodSpacePlaneOffset = LocalToEllipsiodTransform.InverseTransformPosition(BoundsPlaneOffset);
		EllipsoidSpacePlaneCenter = FMath::LinePlaneIntersection(FVector::ZeroVector, EllipsiodSpacePlaneNormal, EllipsiodSpacePlaneOffset, EllipsiodSpacePlaneNormal);
	}

	UFUNCTION(BlueprintPure)
	bool IsWithinBounds(FVector WorldLocation)
	{
		if (BoundsCenter == nullptr)
			return false;

		FVector LocalLoc = InverseEllipsoidTransform.TransformPosition(WorldLocation);

		// Are we within ellipsoid? 
		if (LocalLoc.SizeSquared() > 1.f * 1.f) // In ellipsoid local space it's a sphere with radius 1
			return false;

		if (!Math::IsAbovePlane(LocalLoc, EllipsiodSpacePlaneNormal, EllipsoidSpacePlaneCenter))
			return false; 

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			DebugDrawBounds();
#endif
		// Inside!
		return true; 
	}

	UFUNCTION(BlueprintPure)
	bool IsAbovePlane(FVector WorldLocation)
	{
		if (BoundsCenter == nullptr)
			return false;

		FVector LocalLoc = InverseEllipsoidTransform.TransformPosition(WorldLocation);
		if (!Math::IsAbovePlane(LocalLoc, EllipsiodSpacePlaneNormal, EllipsoidSpacePlaneCenter))
			return false;
		return true;
	}

	UFUNCTION(BlueprintPure)
	bool IsWithinEllipsoid(FVector WorldLocation)
	{
		if (BoundsCenter == nullptr)
			return false;

		FVector LocalLoc = InverseEllipsoidTransform.TransformPosition(WorldLocation);
		if (LocalLoc.SizeSquared() > 1.f * 1.f) // In ellipsoid local space it's a sphere with radius 1
			return false;
		return true;
	}

	UFUNCTION(BlueprintPure)
	FVector GetRandomLocationWithinBounds(float MinDepth)
	{
		// Find a random vector from planes center location within ellisoid, 
		// offset by depth and with a direction within 90 degrees from plane normal.
		// Then move a random distance along that vector within suitable depth bounds.
		// Note that this won't give uniform randomness (unless plane evenly bisects ellipsoid and it is a sphere)
		// It's good enough for our purposes though.
		FVector Dir = Math::GetRandomPointOnSphere();
		if (Dir.DotProduct(EllipsiodSpacePlaneNormal) < 0.f)
			Dir = -Dir;
		FVector DepthOffsetCenter = EllipsoidSpacePlaneCenter + (EllipsiodSpacePlaneNormal * MinDepth);
		FVector EdgeLoc;

		// Line sphere intersection 2nd degree equation to find distance to edge
		float DistToEdge = 0.f;
		float DotDirToStart = Dir.DotProduct(-DepthOffsetCenter);
		float SqrDot = FMath::Square(DotDirToStart);
		float Discriminant = 1.f - DepthOffsetCenter.SizeSquared() + SqrDot;
		if (ensure(Discriminant > SqrDot))
			DistToEdge = DotDirToStart + FMath::Sqrt(Discriminant);

		// Get world space line start and end 
		FVector WorldDepthOffsetCenter = EllipsoidTransform.TransformPosition(DepthOffsetCenter);
		FVector WorldDir = EllipsoidTransform.TransformVector(Dir);
		FVector WorldDepthOffSetEdge = WorldDepthOffsetCenter + WorldDir * DistToEdge - (WorldDir.GetSafeNormal() * MinDepth);

		// Choose random fraction along line. 
		float Fraction = FMath::FRand();
		return FMath::VLerp(WorldDepthOffsetCenter, WorldDepthOffSetEdge, FVector(Fraction)); 
	}

	float LineWidth = 5.f;
	FLinearColor LineColor = FLinearColor::Green;
	void DebugDrawBounds()
	{
		FTransform T = EllipsoidTransform;
		float YawStep = 360.f / 16.f;
		FVector PlaneNormal = T.TransformVector(EllipsiodSpacePlaneNormal);
		FVector PlaneOrigin = T.TransformPosition(EllipsoidSpacePlaneCenter);

		// Draw ellipsoid above the plane
		FVector SphereSweep = FVector::ForwardVector;
		FVector PrevCenterLoc = T.TransformPosition(SphereSweep);
		float PitchStep = 90.f / 4.f;
		FVector TopLoc = T.TransformPosition(FVector::UpVector);
		FVector BottomLoc = T.TransformPosition(-FVector::UpVector);
		TArray<FVector> PlaneIntersections;
		for (float Yaw = YawStep; Yaw < 361.f; Yaw += YawStep)
		{
			FVector CenterDir = SphereSweep.RotateAngleAxis(Yaw, FVector::UpVector);
			FVector CenterLoc = T.TransformPosition(CenterDir);
			DrawEllipsiodLine(PrevCenterLoc, CenterLoc, PlaneNormal, PlaneOrigin, PlaneIntersections);
			FVector PrevUpRingLoc = CenterLoc;
			FVector PrevDownRingLoc = CenterLoc;
			for (float Pitch = PitchStep; Pitch < 89.f; Pitch += PitchStep)
			{
				FVector UpRingDir = (CenterDir.ToOrientationQuat() * FQuat(FRotator(Pitch, 0.f, 0.f))).ForwardVector;
				FVector UpRingLoc = T.TransformPosition(UpRingDir);
				DrawEllipsiodLine(UpRingLoc, PrevUpRingLoc, PlaneNormal, PlaneOrigin, PlaneIntersections);
				DrawEllipsiodLine(UpRingLoc, T.TransformPosition(UpRingDir.RotateAngleAxis(-YawStep, FVector::UpVector)), PlaneNormal, PlaneOrigin, PlaneIntersections);
				PrevUpRingLoc = UpRingLoc;	
				FVector DownRingDir = UpRingDir; 
				DownRingDir.Z *= -1.f;
				FVector DownRingLoc = T.TransformPosition(DownRingDir);
				DrawEllipsiodLine(DownRingLoc, PrevDownRingLoc, PlaneNormal, PlaneOrigin, PlaneIntersections);
				DrawEllipsiodLine(DownRingLoc, T.TransformPosition(DownRingDir.RotateAngleAxis(-YawStep, FVector::UpVector)), PlaneNormal, PlaneOrigin, PlaneIntersections);
				PrevDownRingLoc = DownRingLoc;	
			}
			DrawEllipsiodLine(TopLoc, PrevUpRingLoc, PlaneNormal, PlaneOrigin, PlaneIntersections);
			DrawEllipsiodLine(BottomLoc, PrevDownRingLoc, PlaneNormal, PlaneOrigin, PlaneIntersections);

			PrevCenterLoc = CenterLoc;			
		}

		// Draw bottom plane intersections
		if (PlaneIntersections.Num() > 0)
		{
			System::DrawDebugLine(PlaneIntersections[0], PlaneIntersections[PlaneIntersections.Num() - 1], LineColor, 0.f, LineWidth);
			System::DrawDebugLine(PlaneIntersections[0], PlaneOrigin, LineColor, 0.f, LineWidth);
		}
		for (int i = 1; i < PlaneIntersections.Num(); i++)
		{
			System::DrawDebugLine(PlaneIntersections[i], PlaneIntersections[i - 1], LineColor, 0.f, LineWidth);
			System::DrawDebugLine(PlaneIntersections[i], PlaneOrigin, LineColor, 0.f, LineWidth);
		}
	}	
	void DrawEllipsiodLine(FVector Start, FVector End, FVector PlaneNormal, FVector PlaneOrigin, TArray<FVector>& Intersections)
	{
		// Only draw lines above the plane and report any intersections
		bool bStartAbove = Math::IsAbovePlane(Start, PlaneNormal, PlaneOrigin);
		FVector Intersection;
		if (Math::IsLineSegmentIntersectingPlane(Start, End, PlaneNormal, PlaneOrigin, Intersection))
		{
			// Draw part above plane
			FVector AbovePlane = (bStartAbove ? Start : End);
			System::DrawDebugLine(AbovePlane, Intersection, LineColor, 0.f, LineWidth);	
			Intersections.Add(Intersection);
		}
		else if (bStartAbove)
		{
			// Not intersecting so fully above plane
			System::DrawDebugLine(Start, End, LineColor, 0.f, LineWidth);
		}
		// else fully below plane, do not draw 
	}
}
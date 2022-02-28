import Peanuts.Spline.SplineComponent;
import Rice.Math.MathStatics;

struct FSplineMeshData
{
	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	FName CollisionProfile = n"NoCollision";

	UPROPERTY()
	ECollisionEnabled CollisionType = ECollisionEnabled::QueryOnly;

	UPROPERTY()
	TArray<UMaterialInstance> MaterialOverride;

	UPROPERTY()
	EShadowPriority ShadowPriority = EShadowPriority::Background;

	UPROPERTY()
	float SegmentLengthOffset = 0.f;

	UPROPERTY()
	float MeshSegmentLengthOffset = 0.f;

	UPROPERTY()
	bool bSmoothInterpolate = false;
	
	UPROPERTY()
	float CullingDistanceMultiplier = 1.f;
}

struct FSplineMeshBuildData
{
	UPROPERTY(Transient)
	AHazeActor OwningActor;

	UPROPERTY(Transient)
	UHazeSplineComponent Spline;
	
	UPROPERTY(Transient)
	UStaticMesh Mesh;

	UPROPERTY(Transient)
	FName CollisionProfile = n"NoCollision";

	UPROPERTY(Transient)
	ECollisionEnabled CollisionType = ECollisionEnabled::QueryOnly;

	UPROPERTY(Transient)
	TArray<UMaterialInstance> MaterialOverride;

	UPROPERTY()
	EShadowPriority ShadowPriority = EShadowPriority::Background;

	UPROPERTY()
	float SegmentLengthOffset = 0.f;

	UPROPERTY()
	float MeshSegmentLengthOffset = 0.f;

	UPROPERTY()
	float CullingDistanceMultiplier = 1.f;

	UPROPERTY()
	bool bSmoothInterpolate = false;

	float SegmentLength = 0.f;

	bool IsValid() const
	{
		if (OwningActor == nullptr)
			return false;

		if (Mesh == nullptr)
			return false;

		if (Spline == nullptr)
			return false;

		if (SegmentLength < 10.f)
			return false;

		return true;
	}
}

struct FSplineMeshComponentRangeHolder
{
	FSplineMeshComponentRangeHolder(USplineMeshComponent Mesh, float Start, float End)
	{
		SplineMesh = Mesh;
		StartDistance = Start;
		EndDistance = End;
	}

	USplineMeshComponent SplineMesh;

	float StartDistance = 0.f;
	float EndDistance = 0.f;

	bool IsDistanceWithinRange(float Distance) const
	{
		return Distance >= StartDistance && Distance <= EndDistance;
	}

	bool IsValid() { return SplineMesh != nullptr; }
}

struct FSplineMeshRangeContainer
{
	TArray<FSplineMeshComponentRangeHolder> SplinesMeshes;
	bool bIsLopped = false;
	int LastMainIndex = -1;

	void Reset()
	{
		SplinesMeshes.Reset();
	}

	void AddMesh(USplineMeshComponent Mesh, float StartDistance, float EndDistance)
	{
		SplinesMeshes.Add(FSplineMeshComponentRangeHolder(Mesh, StartDistance, EndDistance));
	}

	// Returns the SplineMesh that contains that distance, also returns its closest neighbour.
	USplineMeshComponent GetMeshAtDistance(float SplineDistance)
	{
		if (SplinesMeshes.IsValidIndex(LastMainIndex))
		{
			if (SplinesMeshes[LastMainIndex].IsDistanceWithinRange(SplineDistance))
			{
				return SplinesMeshes[LastMainIndex].SplineMesh;
			}
			else if (SplinesMeshes.IsValidIndex(LastMainIndex + 1) && SplinesMeshes[LastMainIndex + 1].IsDistanceWithinRange(SplineDistance))
			{
				LastMainIndex = LastMainIndex + 1;
				return SplinesMeshes[LastMainIndex].SplineMesh;
			}
			else if (SplinesMeshes.IsValidIndex(LastMainIndex - 1) && SplinesMeshes[LastMainIndex - 1].IsDistanceWithinRange(SplineDistance))
			{
				LastMainIndex = LastMainIndex - 1;
				return SplinesMeshes[LastMainIndex].SplineMesh;
			}
		}

		int IndexCounter = 0;
		for (const auto& MeshHolder : SplinesMeshes)
		{
			if (MeshHolder.IsDistanceWithinRange(SplineDistance))
			{
				LastMainIndex = IndexCounter;
				return MeshHolder.SplineMesh;
			}

			IndexCounter++;
		}

		return nullptr;
	}
}


FSplineMeshBuildData MakeSplineMeshBuildData(AHazeActor OwningActor, UHazeSplineComponent Spline, FSplineMeshData SplineMeshData)
{	
	FSplineMeshBuildData BuildData;
		
	if (SplineMeshData.Mesh == nullptr)
		return BuildData;

	BuildData.OwningActor = OwningActor;
	BuildData.Spline = Spline;
	BuildData.SegmentLength = SplineMeshData.Mesh.BoundingBox.Extent.X * 2.f;

	BuildData.bSmoothInterpolate = SplineMeshData.bSmoothInterpolate;
	BuildData.CollisionProfile = SplineMeshData.CollisionProfile;
	BuildData.CollisionType = SplineMeshData.CollisionType;
	BuildData.ShadowPriority = SplineMeshData.ShadowPriority;
	BuildData.MaterialOverride = SplineMeshData.MaterialOverride;
	BuildData.Mesh = SplineMeshData.Mesh;
	BuildData.MeshSegmentLengthOffset = SplineMeshData.MeshSegmentLengthOffset;
	BuildData.SegmentLengthOffset = SplineMeshData.SegmentLengthOffset;
	BuildData.CullingDistanceMultiplier = SplineMeshData.CullingDistanceMultiplier;
	return BuildData;
}

void BuildSplineMeshes(FSplineMeshBuildData BuildData, FSplineMeshRangeContainer& OutMeshContainer)
{
	if (!ensure(BuildData.IsValid(), "Trying to build spline mesh with invalid build data"))
		return;

	OutMeshContainer.Reset();

	/* BUILD DAT SPLINE MESH */
	// Okay,
	// So, first of all we want to always have an integer amount of spline-meshes between every spline-point
	// so that we avoid the situation of a spline-mesh spanning in-between a spline-point, which makes perfectly
	// following the spline harder.
	// So inbetween every point we figure out how many segments we can fit (rounded up right now)
	// Then we just make them! Splitting the spline up into chunks and getting position/tangent/roll at those points.
	const ESplineCoordinateSpace Space = ESplineCoordinateSpace::Local;

	OutMeshContainer.bIsLopped = BuildData.Spline.IsClosedLoop();
	FQuat StartPointOrientation = BuildData.Spline.GetQuaternionAtDistanceAlongSpline(0, ESplineCoordinateSpace::Local);
	for(int PointIndex = 0; PointIndex < BuildData.Spline.NumberOfSplinePoints - 1; ++PointIndex)
	{
		float PointDistA = BuildData.Spline.GetDistanceAlongSplineAtSplinePoint(PointIndex);
		float PointDistB = BuildData.Spline.GetDistanceAlongSplineAtSplinePoint(PointIndex + 1);
		FVector ArriveTangent = BuildData.Spline.GetArriveTangentAtSplinePoint(PointIndex + 1, ESplineCoordinateSpace::Local);

		BuildMeshesBetweenNodes(BuildData, PointDistA, PointDistB, ArriveTangent, StartPointOrientation, OutMeshContainer);
	}

	if (BuildData.Spline.IsClosedLoop())
	{
		float PointDistA = BuildData.Spline.GetDistanceAlongSplineAtSplinePoint(BuildData.Spline.NumberOfSplinePoints - 1);
		float PointDistB = BuildData.Spline.GetSplineLength();
		FVector ArriveTangent = BuildData.Spline.GetArriveTangentAtSplinePoint(0, ESplineCoordinateSpace::Local);

		BuildMeshesBetweenNodes(BuildData, PointDistA, PointDistB, ArriveTangent, StartPointOrientation, OutMeshContainer);
	}
}

void BuildMeshesBetweenNodes(FSplineMeshBuildData BuildData, 
							float PointDistA, float PointDistB
							, FVector ArriveTangent
							, FQuat& FirstPointOrientation
							, FSplineMeshRangeContainer& MeshContainer)
{
	UHazeSplineComponent Spline = BuildData.Spline;
	const ESplineCoordinateSpace Space = ESplineCoordinateSpace::Local;

	// Distance of this point to next
	float PointLength = PointDistB - PointDistA;
	uint32 NumSegments = FMath::Max(1, FMath::RoundToInt(PointLength / (BuildData.SegmentLength + BuildData.SegmentLengthOffset)));
	float SegLength = PointLength / NumSegments;

	float LengthOfMeshSegment = SegLength + BuildData.MeshSegmentLengthOffset;

	// Make the segments!
	for(uint32 SegIndex = 0; SegIndex < NumSegments; ++SegIndex)
	{
		// Start and end of this segment (distance)
		float SegDistA = PointDistA + (SegLength) * SegIndex;
		float SegDistB = SegDistA + LengthOfMeshSegment;

		FVector SegPosA;
		FVector SegPosB;
		FVector SegTangA;
		FVector SegTangB;
		FVector SegScaleA;
		FVector SegScaleB;
		float SegRollA = 0.f;
		float SegRollB = 0.f;

		/* POSITION */
		SegPosA = Spline.GetLocationAtDistanceAlongSpline(SegDistA, Space);
		SegPosB = Spline.GetLocationAtDistanceAlongSpline(SegDistB, Space);

		/* SCALING */
		SegScaleA = Spline.GetScaleAtDistanceAlongSpline(SegDistA);
		SegScaleB = Spline.GetScaleAtDistanceAlongSpline(SegDistB);

		/* TANGENT */
		SegTangA = Spline.GetTangentAtDistanceAlongSpline(SegDistA, Space);
		SegTangB = Spline.GetTangentAtDistanceAlongSpline(SegDistB, Space);

		// If this is the last segment, use the arrive tangent of the next point instead
		if (SegIndex == NumSegments - 1)
			SegTangB = ArriveTangent;

		// IMPORTANT: We HAVE to scale the tangents by the ratio between segment length and point-to-next length (just number of segments).
		// I'm not sure if this always works perfectly.
		SegTangA /= NumSegments;
		SegTangB /= NumSegments;
		
		FQuat RotB = Spline.GetQuaternionAtDistanceAlongSpline(SegDistB, ESplineCoordinateSpace::Local);

		// Phew! All data in hand, lets create the spline mesh
		auto MeshSpline = Cast<USplineMeshComponent>(BuildData.OwningActor.CreateComponent(USplineMeshComponent::StaticClass()));
		MeshSpline.StaticMesh = BuildData.Mesh;
		for (int iMaterial = 0; iMaterial < BuildData.MaterialOverride.Num(); ++iMaterial)
		{
			MeshSpline.SetMaterial(iMaterial, BuildData.MaterialOverride[iMaterial]);
		}

		// Collision
		MeshSpline.SetCollisionProfileName(BuildData.CollisionProfile);
		if (BuildData.CollisionType != ECollisionEnabled::ECollisionEnabled_MAX)
			MeshSpline.SetCollisionEnabled(BuildData.CollisionType);

		// Shadows
		if (BuildData.ShadowPriority != EShadowPriority::Background)
			MeshSpline.HazeSetShadowPriority(BuildData.ShadowPriority);

		FQuat RotationDif = FirstPointOrientation.Inverse() * RotB;
		SegRollB = RotationDif.Rotator().Roll;

		// Roll is in radians for some reason ?????
		MeshSpline.SetEndRoll(SegRollB * DEG_TO_RAD);
		MeshSpline.SetSmoothInterpRollScale(BuildData.bSmoothInterpolate, false);

		MeshSpline.SetStartScale(FVector2D(SegScaleA.Y, SegScaleA.Z));
		MeshSpline.SetEndScale(FVector2D(SegScaleB.Y, SegScaleB.Z));

		MeshSpline.SetSplineUpDir(FirstPointOrientation.UpVector);

		MeshSpline.SetStartAndEnd(SegPosA, SegTangA, SegPosB, SegTangB);
		FirstPointOrientation = RotB;

		float CullDistance = Editor::GetDefaultCullingDistance(MeshSpline) * BuildData.CullingDistanceMultiplier * 4.0f;
		MeshSpline.SetCullDistance(CullDistance);

		MeshContainer.AddMesh(MeshSpline, SegDistA, SegDistB);
	}
}

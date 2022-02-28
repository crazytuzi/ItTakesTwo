import Cake.LevelSpecific.Music.LevelMechanics.Classic.FollowCloud.FollowCloudBoundsComponent;

class UFollowCloudBoundsComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UFollowCloudBoundsComponent::StaticClass();

	FLinearColor LineColor = FLinearColor::Green;
	float LineWidth = 10.f;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UFollowCloudBoundsComponent Comp = Cast<UFollowCloudBoundsComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
            return;

		Comp.Setup();
		FTransform T = Comp.EllipsoidTransform;
		float YawStep = 360.f / 16.f;
		FVector PlaneNormal = T.TransformVector(Comp.EllipsiodSpacePlaneNormal);
		FVector PlaneOrigin = T.TransformPosition(Comp.EllipsoidSpacePlaneCenter);

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
			DrawLine(PlaneIntersections[0], PlaneIntersections[PlaneIntersections.Num() - 1], LineColor, LineWidth);
			DrawLine(PlaneIntersections[0], PlaneOrigin, LineColor, LineWidth);
		}
		for (int i = 1; i < PlaneIntersections.Num(); i++)
		{
			DrawLine(PlaneIntersections[i], PlaneIntersections[i - 1], LineColor, LineWidth);
			DrawLine(PlaneIntersections[i], PlaneOrigin, LineColor, LineWidth);
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
			DrawLine(AbovePlane, Intersection, LineColor, LineWidth);	
			Intersections.Add(Intersection);
		}
		else if (bStartAbove)
		{
			// Not intersecting so fully above plane
			DrawLine(Start, End, LineColor, LineWidth);
		}
		// else fully below plane, do not draw 
	}
} 

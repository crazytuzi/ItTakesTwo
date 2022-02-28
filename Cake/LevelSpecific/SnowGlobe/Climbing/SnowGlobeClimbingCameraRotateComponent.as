import Peanuts.Spline.SplineComponent;
class USnowGlobeClimbingCameraRotateComponent : UHazeCameraParentComponent
{
	UHazeSplineComponent Spline;

	FHazeAcceleratedRotator AcceleratedRotation;

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		USnowGlobeClimbingCameraRotateComponent Component = Cast<USnowGlobeClimbingCameraRotateComponent>(Owner.GetComponentByClass(USnowGlobeClimbingCameraRotateComponent::StaticClass()));
		Spline = Component.Spline;

		if (PreviousState == EHazeCameraState::Inactive)
			Snap();
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		AcceleratedRotation.SnapTo(GetTargetRotation());
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if (Camera == nullptr)
			return;

		AcceleratedRotation.AccelerateTo(GetTargetRotation(), 2.f, DeltaSeconds);	
		SetWorldRotation(AcceleratedRotation.Value);
	}

	FRotator GetTargetRotation()
	{
		FVector MaySplineLocation = Spline.FindLocationClosestToWorldLocation(Game::GetMay().GetActorLocation(), ESplineCoordinateSpace::World);
		FVector CodySplineLocation = Spline.FindLocationClosestToWorldLocation(Game::GetCody().GetActorLocation(), ESplineCoordinateSpace::World);
		
		FVector MayToCody = CodySplineLocation - MaySplineLocation;
		MayToCody.Z = 0.f;
		
		if(MayToCody.IsNearlyZero(10.f))
			return AcceleratedRotation.Value;

		FVector TowardsWallOrthogonal = MayToCody.CrossProduct(FVector::UpVector);
		
		if(Spline != nullptr)
		{
			FVector AverageLocation = MaySplineLocation + MayToCody * 0.5f;
			FVector WallFaceNormal = Spline.FindRightVectorClosestToWorldLocation(AverageLocation, ESplineCoordinateSpace::World);
		
			if(WallFaceNormal.DotProduct(TowardsWallOrthogonal) > 0.f)
				TowardsWallOrthogonal = -TowardsWallOrthogonal;
		}

		return TowardsWallOrthogonal.Rotation();
	}
}
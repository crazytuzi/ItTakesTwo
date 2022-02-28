import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineActor;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.SplineLock.ConstraintHandler;
import Vino.Movement.Capabilities.Input.MovementDirectionSplineInputCapability;

class ULighthouseCameraRotatorComponent : UHazeCameraParentComponent
{
	UPROPERTY()
	ASplineActor WallSpline;
	
	// In lighthouse, we do not want the camera to use the first part of the spline
	UPROPERTY()
	float MinDistance = 500.f;
	UHazeSplineComponent Spline;

	FHazeAcceleratedRotator AcceleratedRotation;
	bool bIsSplitScreen;

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		bIsSplitScreen = false; 
		Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);
		Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Hide, EHazeViewPointBlendSpeed::Instant);

		Spline = WallSpline.Spline;

		if (PreviousState == EHazeCameraState::Inactive)
			Snap();
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraDeactivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		Game::GetCody().ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
		Game::GetMay().ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		float MayDistanceAlongSpline = GetDistanceAlongSpline(Game::GetMay().GetActorLocation());
		float CodyDistanceAlongSpline = GetDistanceAlongSpline(Game::GetCody().GetActorLocation());
		AcceleratedRotation.SnapTo(GetTargetRotation(MayDistanceAlongSpline, CodyDistanceAlongSpline));
		Update(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaSeconds)
	{
		if (Camera == nullptr)
			return;
		float MayDistanceAlongSpline = GetDistanceAlongSpline(Game::GetMay().GetActorLocation());
		float CodyDistanceAlongSpline = GetDistanceAlongSpline(Game::GetCody().GetActorLocation());
		AcceleratedRotation.AccelerateTo(GetTargetRotation(MayDistanceAlongSpline, CodyDistanceAlongSpline), 2.f, DeltaSeconds);	

		SetWorldRotation(AcceleratedRotation.Value);
	}

	FRotator GetSplitScreenTargetRotation(float UserDistanceAlongSpline)
	{
		return (-Spline.GetRightVectorAtDistanceAlongSpline(UserDistanceAlongSpline, ESplineCoordinateSpace::World)).Rotation(); 
	}

	FRotator GetTargetRotation(float MayDistanceAlongSpline, float CodyDistanceAlongSpline)
	{
		if((MayDistanceAlongSpline < MinDistance + 0.1f) && (CodyDistanceAlongSpline < MinDistance + 0.1f))
			return FRotator(0.f,149.5f,0.f); 

		FVector MaySplineLocation = Spline.GetLocationAtDistanceAlongSpline(MayDistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector CodySplineLocation = Spline.GetLocationAtDistanceAlongSpline(CodyDistanceAlongSpline, ESplineCoordinateSpace::World);
		FVector MayToCody = CodySplineLocation - MaySplineLocation;
		MayToCody.Z = 0.f;

		if(MayToCody.IsNearlyZero(10.f))
			return AcceleratedRotation.Value;

		FVector TowardsWallOrthogonal = -MayToCody.CrossProduct(FVector::UpVector);

		if(CodyDistanceAlongSpline > MayDistanceAlongSpline)
		{
			TowardsWallOrthogonal = - TowardsWallOrthogonal;
		}
		return TowardsWallOrthogonal.Rotation();
	}

	float GetDistanceAlongSpline(FVector Location)
	{
		float Dist = Spline.GetDistanceAlongSplineAtWorldLocation(Location);
		return FMath::Max(MinDistance, Dist);
	}
}


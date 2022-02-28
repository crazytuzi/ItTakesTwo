import Vino.Camera.Components.CameraSplineFollowerComponent;
import Peanuts.Visualization.DummyVisualizationComponent;
import Vino.Camera.Components.CameraSplineRotationFollowerComponent;

UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData")
class ASplineRotationFollowerCamera : AHazeCameraActor
{
	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponentBase CameraSpline;
#if EDITOR
    default CameraSpline.bShouldVisualizeScale = true;
    default CameraSpline.ScaleVisualizationWidth = 20.f;
#endif

#if EDITOR
	UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (MakeEditWidget = true), Category = "Editor Visualization")
	TArray<FVector> PreviewFocusLocations;
	default if (PreviewFocusLocations.Num() == 0) PreviewFocusLocations.Add(GetActorLocation() + GetActorForwardVector() * 1000.f);
#endif

	// This component will slide along the spline
	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraSplineFollowerComponent SplineFollower;
	default SplineFollower.CameraSpline = CameraSpline;
	default SplineFollower.ClampsModifier = ESplineFollowClampType::None;
	
	// This component will rotate along with the spline
	UPROPERTY(DefaultComponent, Attach = SplineFollower, ShowOnActor)
	UCameraSplineRotationFollowerComponent RotationFollower;
	default RotationFollower.CameraSpline = CameraSpline;

	// ...and camera will thus slide along the spline and aim towards focus target
	UPROPERTY(DefaultComponent, Attach = RotationFollower, ShowOnActor)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UDummyVisualizationComponent DummyVisualizer;
	default DummyVisualizer.Color = FLinearColor::Gray;
	default DummyVisualizer.DashSize = 50.f;
	default DummyVisualizer.ConnectionBase = Camera;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
#if EDITOR // Should be superflous, but just to be sure...
		DummyVisualizer.ConnectedLocalLocations = PreviewFocusLocations;

		// Adjust visualized FOV (we should really do this for all focustrackcamera actors)
		if (Camera.Settings.bUseFOV)
			Camera.FieldOfView = Camera.Settings.FOV;

		// Adjust spline follower location
		if (CameraSpline != nullptr)
		{
			if (SplineFollower.GuideSpline == nullptr)
				SplineFollower.GuideSpline = CameraSpline;

			// Find spline fraction from preview focus targets
			TArray<FSplineFollowTarget> Followees;
			for (FVector EditorFocus : PreviewFocusLocations)
			{
				FSplineFollowTarget FollowTarget;
				FollowTarget.Target.Actor = this;
				FollowTarget.Target.LocalOffset = EditorFocus;
				FollowTarget.Weight = 1.f;
				Followees.Add(FollowTarget); 
			}

			SplineFollower.AllFollowTargets = Followees;
			float SplineFraction = SplineFollower.GetFollowFraction();
			float DistAlongSpline = SplineFraction * CameraSpline.GetSplineLength() - SplineFollower.BackwardsOffset;

			// Move spline follower 
			FVector VisualizedCamLoc = CameraSpline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
			SplineFollower.SetWorldLocation(VisualizedCamLoc);

			// Rotate rotation follower
			RotationFollower.AllFollowTargets = Followees;
			float RotSplineFraction = RotationFollower.GetFollowFraction();
			float RotDistAlongSpline = SplineFraction * CameraSpline.GetSplineLength() - RotationFollower.BackwardsOffset;
			FRotator VisualizedCamRot = CameraSpline.GetRotationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
			RotationFollower.SetWorldRotation(VisualizedCamRot + RotationFollower.RotationOffset);
		}
#endif // EDITOR
    }
};
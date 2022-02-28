import Vino.Camera.Components.CameraSplineFollowerComponent;
import Vino.Camera.Components.FocusTrackerComponent;

// Camera that follows the spline but will never change it's angle, useful for side scroller sections
UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData")
class AStaticSplineCamera : AHazeCameraActor
{
	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponentBase CameraSpline;

	// The spline we use to determine how far along the camera spline the camera should be. Hidden in editor until user sets the bUseGuideSpline option
	UPROPERTY(DefaultComponent)
	UHazeSplineComponentBase GuideSpline;
	default GuideSpline.RelativeLocation = FVector(0,0,-100);
	default GuideSpline.bDrawDebug = false;

#if EDITOR
	default GuideSpline.SetEditorUnselectedSplineSegmentColor(FLinearColor::Green);
	default GuideSpline.SetEditorSelectedSplineSegmentColor(FLinearColor::Blue);

	//UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (InlineEditConditionToggle), Category = "Editor Visualization")
	bool bUsePreviewSplineFraction = false;

	//UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (ClampMin=0, ClampMax=1, EditCondition = "bUsePreviewSplineFraction"), Category = "Editor Visualization")
	float PreviewSplineFraction = 0.f;

	UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (MakeEditWidget = true), Category = "Editor Visualization")
	TArray<FVector> PreviewFocusLocations;
	default if (PreviewFocusLocations.Num() == 0) PreviewFocusLocations.Add(GetActorLocation() + GetActorForwardVector() * 1000.f);
#endif

	// If true, the guide spline will be shown and used, otherwise it remains hidden.
	UPROPERTY()
	bool bUseGuideSpline = false;

	// This component will slide along the spline
	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraSplineFollowerComponent SplineFollower;
	default SplineFollower.CameraSpline = CameraSpline;
	default SplineFollower.ClampsModifier = ESplineFollowClampType::TangentLeft;
	default SplineFollower.bAllowCameraRelativeOffset = true; 

	// ...and camera will thus slide along the spline and aim towards focus target
	UPROPERTY(DefaultComponent, Attach = SplineFollower, ShowOnActor)
	UHazeCameraComponent Camera;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
#if EDITOR // Should be superflous, but just to be sure...
		if ((GuideSpline != nullptr) && (SplineFollower != nullptr))
		{
			if (bUseGuideSpline)
			{
				GuideSpline.bVisualizeSpline = true;
				SplineFollower.GuideSpline = GuideSpline;
				
				// Guide spline should always match camera spline closed loop property
				GuideSpline.SetClosedLoop(CameraSpline.IsClosedLoop());
			}
			else
			{
				GuideSpline.bVisualizeSpline = false;
				SplineFollower.GuideSpline = nullptr;
			}
		}

		// Adjust visualized FOV (we should really do this for all focustrackcamera actors)
		if (Camera.Settings.bUseFOV)
			Camera.FieldOfView = Camera.Settings.FOV;

		// Adjust spline follower location
		float DistAlongSpline = 0.f;
		if (CameraSpline != nullptr)
		{
			if (SplineFollower.GuideSpline == nullptr)
				SplineFollower.GuideSpline = CameraSpline;
			if(bUsePreviewSplineFraction)
			{
				// We've changed the preview spline fraction, move follower based on this
				DistAlongSpline = PreviewSplineFraction * CameraSpline.GetSplineLength();

				// Adjust preview follow targets along guide spline
				// FTransform PrevSplinePos = SplineFollower.GuideSpline.GetTransformAtDistanceAlongSpline(PreviousPreviewSplineFraction * CameraSpline.GetSplineLength(), ESplineCoordinateSpace::World);
				// FTransform NewSplinePos = SplineFollower.GuideSpline.GetTransformAtDistanceAlongSpline(PreviewSplineFraction * CameraSpline.GetSplineLength(), ESplineCoordinateSpace::World);
				// PreviewFocusLocations.SetNum(1);
				// FVector LocalOffset = PrevSplinePos.InverseTransformPosition(GetActorTransform().TransformPosition(PreviewFocusLocations[0]));
				// PreviewFocusLocations[0] = GetActorTransform().InverseTransformPosition(NewSplinePos.TransformPosition(LocalOffset));
			}
			else 
			{
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
				float SplineFraction = SplineFraction = SplineFollower.GetFollowFraction();
				DistAlongSpline = SplineFraction * CameraSpline.GetSplineLength() - SplineFollower.BackwardsOffset;
				PreviewSplineFraction = SplineFraction;
			}

			// Move visualizer spline fraction
			SplineFollower.PreviewSplineFraction = PreviewSplineFraction;
			
			// Move spline follower
			FVector VisualizedCamLoc = CameraSpline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
			SplineFollower.SetWorldLocation(VisualizedCamLoc);
		}

#endif // EDITOR
    }
};
import Vino.Camera.Components.CameraSplineFollowerComponent;
import Peanuts.Visualization.DummyVisualizationComponent;
import Vino.Camera.Components.CameraSplineFocusComponent;
import Vino.Camera.Components.BallSocketCameraComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;
UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData")
class AFocusSplineKeepInViewCamera : AHazeCameraActor
{
    // The spline we will look at
    UPROPERTY()
    AHazeSplineActor FocusSpline;
    // The spline the camera will follow
    UPROPERTY(DefaultComponent)
    UHazeSplineComponentBase CameraSpline;

	UPROPERTY(meta = (ClampMin = "0", ClampMax = "1"))
	float PreviewLocationValue = 0.f;

#if EDITOR
    default CameraSpline.bShouldVisualizeScale = true;
    default CameraSpline.ScaleVisualizationWidth = 20.f;
#endif
    // The spline we use to determine how far along the camera spline the camera should be. Hidden in editor until user sets the bUseGuideSpline option
    UPROPERTY(DefaultComponent)
    UHazeSplineComponentBase GuideSpline;
    default GuideSpline.RelativeLocation = FVector(0,0,-100);
    default GuideSpline.bDrawDebug = false;
#if EDITOR
    default GuideSpline.SetEditorUnselectedSplineSegmentColor(FLinearColor::Green);
    default GuideSpline.SetEditorSelectedSplineSegmentColor(FLinearColor::Blue);
#endif
    UPROPERTY(EditInstanceOnly, BlueprintHidden, meta = (MakeEditWidget = true), Category = "Editor Visualization")
    TArray<FVector> PreviewFocusLocations;
#if EDITOR
    default if (PreviewFocusLocations.Num() == 0) PreviewFocusLocations.Add(GetActorLocation() + GetActorForwardVector() * 1000.f);
#endif
    // If true, the guide spline will be shown and used, otherwise it remains hidden.
    UPROPERTY()
    bool bUseGuideSpline = false;
    
	// This component will slide along the spline
    UPROPERTY(DefaultComponent, ShowOnActor)
    UCameraSplineFollowerComponent SplineFollower;
    default SplineFollower.CameraSpline = CameraSpline;
    default SplineFollower.ClampsModifier = ESplineFollowClampType::None;
    
    // This component will aim towards focus target
	// Needs to be attached to SplineFollower to rotate correctly
    UPROPERTY(DefaultComponent, Attach = SplineFollower, ShowOnActor)
    UCameraSplineFocusComponent SplineFocuser;

	// This component will allow player aim when there is camera input
    UPROPERTY(DefaultComponent, Attach = SplineFocuser, ShowOnActor)
	UBallSocketCameraComponent BallSocket;
	default BallSocket.bBlendToParentWithNoInput = true;

	UPROPERTY(DefaultComponent, Attach = BallSocket, ShowOnActor)
	UCameraKeepInViewComponent KeepInViewComp;

    // ...and camera will thus slide along the spline and aim towards focus spline, except when input moves ball socket
    UPROPERTY(DefaultComponent, Attach = KeepInViewComp, ShowOnActor)
    UHazeCameraComponent Camera;

	// Camera will by default be clamped to SplineFocuser rotation.
	default Camera.ClampSettings.bUseClampYawLeft = true;
	default Camera.ClampSettings.ClampYawLeft = 0.f;
	default Camera.ClampSettings.bUseClampYawRight = true;
	default Camera.ClampSettings.ClampYawRight = 0.f;
	default Camera.ClampSettings.bUseClampPitchDown = true;
	default Camera.ClampSettings.ClampPitchDown = 0.f;
	default Camera.ClampSettings.bUseClampPitchUp = true;
	default Camera.ClampSettings.ClampPitchUp = 0.f;
	default Camera.ClampSettings.CenterType = EHazeCameraClampsCenterRotation::Component;
	default Camera.ClampSettings.CenterComponent = SplineFocuser;

    UPROPERTY(DefaultComponent)
    UDummyVisualizationComponent DummyVisualizer;
    default DummyVisualizer.Color = FLinearColor::Gray;
    default DummyVisualizer.DashSize = 50.f;
    default DummyVisualizer.ConnectionBase = Camera;
    
	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
#if EDITOR // Should be superflous, but just to be sure...

		// We never allow spline follower to affect clamps
		SplineFollower.ClampsModifier = ESplineFollowClampType::None;

        DummyVisualizer.ConnectedLocalLocations = PreviewFocusLocations;
		DummyVisualizer.ConnectedActors.AddUnique(FocusSpline);
        if (FocusSpline != nullptr)
            SplineFocuser.FocusSpline = UHazeSplineComponentBase::Get(FocusSpline);
        else 
            SplineFocuser.FocusSpline = nullptr;
        if (GuideSpline != nullptr) 
        {
			UHazeSplineComponentBase PreviewLocSpline = (bUseGuideSpline ? GuideSpline : CameraSpline);
			PreviewFocusLocations[0] = PreviewLocSpline.GetLocationAtDistanceAlongSpline(PreviewLocationValue * PreviewLocSpline.GetSplineLength(), ESplineCoordinateSpace::Local);
			
			if (SplineFollower != nullptr)
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
            if (SplineFocuser != nullptr)
            {
                if (bUseGuideSpline)
                    SplineFocuser.GuideSpline = GuideSpline;
                else
                    SplineFollower.GuideSpline = nullptr;
                if (SplineFocuser.FocusSpline != nullptr)
                {
                    // Focus spline should always match camera spline loop property
                    SplineFocuser.FocusSpline.SetClosedLoop(CameraSpline.IsClosedLoop());
                }
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
            DistAlongSpline = SplineFraction * CameraSpline.GetSplineLength();
			DistAlongSpline -= SplineFollower.BackwardsOffset;
            // Move visualizer spline fraction
            SplineFollower.PreviewSplineFraction = SplineFraction;
            
            // Move spline follower
            FVector VisualizedCamLoc = CameraSpline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
            SplineFollower.SetWorldLocation(VisualizedCamLoc);
        }
        float FocusDistAlongSpline = 0.f;
        if (SplineFocuser.FocusSpline != nullptr)
        {
            if (SplineFocuser.GuideSpline == nullptr)
                SplineFocuser.GuideSpline = SplineFocuser.FocusSpline;
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
            SplineFocuser.AllFollowTargets = Followees;
            float SplineFraction = SplineFocuser.GetFollowFraction();
            FocusDistAlongSpline = SplineFraction * SplineFocuser.FocusSpline.GetSplineLength();
			FocusDistAlongSpline -= SplineFocuser.BackwardsOffset;
            // Move visualizer spline fraction
            SplineFocuser.PreviewSplineFraction = SplineFraction;
            
            // Move spline follower
            FVector VisualizedFocusLoc = SplineFocuser.FocusSpline.GetLocationAtDistanceAlongSpline(FocusDistAlongSpline, ESplineCoordinateSpace::World);
            SplineFocuser.SetWorldRotation((VisualizedFocusLoc - SplineFocuser.WorldLocation).Rotation());
        }
#endif // EDITOR
    }

	UFUNCTION()
	void SetSplineFocuserBackwardsOffset(float BackwardsOffset, EHazeSelectPlayer AffectedPlayer = EHazeSelectPlayer::Both)
	{
		SplineFocuser.SetBackwardsOffset(BackwardsOffset, AffectedPlayer);
	}
};
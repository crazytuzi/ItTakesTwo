import Vino.Camera.Components.CameraSplineFollowerComponent;
import Vino.Camera.Components.CameraKeyedSplineRotatorComponent;
import Vino.Camera.Actors.StaticCamera;
import Peanuts.Spline.SplineComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.Camera.Actors.KeyedSplineCamera;
import Vino.Camera.Components.CameraPointOfInterestRotationComponent;

// Would be nice if we could inherit this from AKeyedSplineCamera, but we can't 
// insert the point of interest rotator into the component attach hierarchy so
// that the keep in view comp would attach to it.

UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Replication Debug Collision")
class AKeyedSplinePointOfInterestCamera : AHazeCameraActor
{
	// The spline the camera will follow
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent CameraSpline;

	// The spline we use to determine how far along the camera spline the camera should be. Hidden in editor until user sets the bUseGuideSpline option
	UPROPERTY(DefaultComponent)
	UHazeSplineComponent GuideSpline;
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
	UPROPERTY(DefaultComponent)
	UCameraSplineFollowerComponent SplineFollower;
	default SplineFollower.CameraSpline = CameraSpline;
	default SplineFollower.ClampsModifier = ESplineFollowClampType::TangentLeft;
	
	// This component will rotate based on the keyed cameras
	UPROPERTY(DefaultComponent, Attach = SplineFollower)
	UCameraKeyedSplineRotatorComponent KeyedRotator;

	// This component will override rotation of the keyed rotator if there is an active point of interest
	UPROPERTY(DefaultComponent, Attach = KeyedRotator, ShowOnActor)
	UCameraPointOfInterestRotationComponent PointOfInterestRotator;

	UPROPERTY(DefaultComponent, Attach = PointOfInterestRotator, ShowOnActor)
	UCameraKeepInViewComponent KeepInViewComp;
	
	UPROPERTY(DefaultComponent, Attach = KeepInViewComp)
	UHazeCameraComponent Camera;

	UFUNCTION(CallInEditor, Category = "KeyedSplineCamera")
	void AddKeyedCamera()
	{
		KeyedCameraActor::Spawn(this, CameraSpline);
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
#if EDITOR // Should be superflous, but just to be sure...
		KeyedRotator.CleanKeyedCameras();

		if (bUseGuideSpline)
			KeyedRotator.KeyedSpline = GuideSpline;
		else
			KeyedRotator.KeyedSpline = CameraSpline;

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

			// Move visualizer spline fraction
			SplineFollower.PreviewSplineFraction = SplineFraction;
			
			// Move spline follower
			FVector VisualizedCamLoc = CameraSpline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
			SplineFollower.SetWorldLocation(VisualizedCamLoc);
		}

		// Adjust keyed rotator rotation
		if (CameraSpline != nullptr)
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
			KeyedRotator.AllFollowTargets = Followees;
			float SplineFraction = KeyedRotator.GetFollowFraction();
			float DistAlongSpline = SplineFraction * CameraSpline.GetSplineLength() - KeyedRotator.BackwardsOffset;

			// Rotate keyed rotator
			FVector VisualizedCamLoc = CameraSpline.GetLocationAtDistanceAlongSpline(DistAlongSpline, ESplineCoordinateSpace::World);
			KeyedRotator.SetWorldRotation(KeyedRotator.GetTargetRotation(DistAlongSpline));
		}

		// Move back according to keepinview comp 
		FVector Dir = KeepInViewComp.WorldRotation.ForwardVector;
		FVector ClosestLocalLoc = FVector(BIG_NUMBER);
		for (FVector EditorFocus : PreviewFocusLocations)
		{
			FVector LocalLoc = KeyedRotator.WorldTransform.InverseTransformPosition(ActorTransform.TransformPosition(EditorFocus));
			if (LocalLoc.X < ClosestLocalLoc.X)
				ClosestLocalLoc = LocalLoc;
		}
		if (ClosestLocalLoc != FVector(BIG_NUMBER))
		{
			// Move keep in view comp mindistance units back from closest focus location
			// This is simplistic, if there are several preview locations we should really 
			// use the keep in view cam GetTargetLocation, but it's fine with one.
			FVector CamLoc = KeyedRotator.WorldTransform.TransformPosition(ClosestLocalLoc);
			CamLoc -= KeyedRotator.WorldRotation.ForwardVector * KeepInViewComp.MinDistance;
			KeepInViewComp.SetWorldLocation(CamLoc);
		}

		// Clamp rotation as best we can without user
// 		FHazeCameraClampSettings Clamps = Camera.ClampSettings;
// 		SplineFollower.ModifyClamps(DistAlongSpline, Clamps);
// 		if (Clamps.IsUsed())
// 		{
// 			if (Clamps.bUseClampPitchDown || Clamps.bUseClampPitchUp)
// 				ToFocusRot.Pitch = FMath::ClampAngle(ToFocusRot.Pitch, Clamps.CenterOffset.Pitch - Clamps.ClampPitchDown, Clamps.CenterOffset.Pitch + FMath::Min(Clamps.ClampPitchUp, 179.9f));
// 			if (Clamps.bUseClampYawLeft || Clamps.bUseClampYawLeft)
// 				ToFocusRot.Yaw = FMath::ClampAngle(ToFocusRot.Yaw, Clamps.CenterOffset.Yaw - FMath::Min(Clamps.ClampYawLeft, 179.9f), Clamps.CenterOffset.Yaw + FMath::Min(Clamps.ClampYawRight, 179.9f));
// 		}
// 		ToFocusRot.Roll = 0.f;
// 		FocusTracker.SetWorldRotation(ToFocusRot);

#endif EDITOR
    }
};


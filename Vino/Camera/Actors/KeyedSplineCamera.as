import Vino.Camera.Components.CameraSplineFollowerComponent;
import Vino.Camera.Components.CameraKeyedSplineRotatorComponent;
import Vino.Camera.Actors.StaticCamera;
import Peanuts.Spline.SplineComponent;
import Vino.Camera.Components.CameraKeepInViewComponent;


// Todo: 
/*
	- Accelerate rotation between spline points
	- Fix preview
	- Fixed delete cleanup
*/


UCLASS(hideCategories="Rendering Cooking Input Actor LOD AssetUserData Replication Debug Collision")
class AKeyedSplineCamera : AHazeCameraActor
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

	UPROPERTY(DefaultComponent, Attach = KeyedRotator, ShowOnActor)
	UCameraKeepInViewComponent KeepInViewComp;
	
	UPROPERTY(DefaultComponent, Attach = KeepInViewComp)
	UHazeCameraComponent Camera;

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

	UFUNCTION(CallInEditor, Category = "KeyedSplineCamera")
	void AddKeyedCamera()
	{
		KeyedCameraActor::Spawn(this, CameraSpline);
	}
};


namespace KeyedCameraActor
{
	AKeyedCameraActor Spawn(AActor Parent, UHazeSplineComponent CameraSpline)
	{
		if (Parent == nullptr)
			return nullptr;

		UCameraKeyedSplineRotatorComponent KeyedRotator = UCameraKeyedSplineRotatorComponent::Get(Parent);
		if (KeyedRotator == nullptr)
			return nullptr;

		AKeyedCameraActor KeyedCamActor = AKeyedCameraActor::Spawn();
		KeyedCamActor.SplineComp = KeyedRotator.KeyedSpline;

		FKeyedCamera KeyedCamera;		
		KeyedCamera.Camera = KeyedCamActor.Camera;
		KeyedCamera.Camera.AttachTo(Parent.RootComponent);

		FRotator CameraRotation = FRotator::ZeroRotator;
		KeyedCamera.DistanceAlongSpline = 0.f;

		if (KeyedRotator.KeyedCameras.Num() > 0)
		{
			KeyedCamera.DistanceAlongSpline = KeyedRotator.KeyedCameras.Last().DistanceAlongSpline;
			CameraRotation = KeyedRotator.KeyedCameras.Last().Rotation;
			
			if (FMath::IsNearlyEqual(KeyedCamera.DistanceAlongSpline, KeyedRotator.KeyedSpline.SplineLength, 20.f))
				KeyedCamera.DistanceAlongSpline = FMath::Max(0.f, KeyedCamera.DistanceAlongSpline - 1000.f);
			else
				KeyedCamera.DistanceAlongSpline = FMath::Min(KeyedRotator.KeyedSpline.SplineLength, KeyedCamera.DistanceAlongSpline + 1000.f);
		}

		float CameraSplineDistance = (KeyedCamera.DistanceAlongSpline / KeyedRotator.KeyedSpline.SplineLength) * CameraSpline.SplineLength;
		KeyedCamera.Camera.SetWorldLocation(CameraSpline.GetLocationAtDistanceAlongSpline(CameraSplineDistance, ESplineCoordinateSpace::World));

		KeyedRotator.AddKeyedCamera(KeyedCamera);
		return KeyedCamActor;
	}
}

UCLASS(NotPlaceable)
class AKeyedCameraActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeCameraComponent Camera;
	default Camera.SetRelativeScale3D(FVector(0.1f, 0.1f, 0.1f));
	default Camera.bVisible = false;

	UPROPERTY(DefaultComponent, Attach = Camera)
	UStaticMeshComponent DummyCamera;
	default DummyCamera.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default DummyCamera.bHiddenInGame = true;
	default DummyCamera.SetRelativeScale3D(FVector(10.f, 10.f, 10.f));
	default DummyCamera.StaticMesh = Asset("/Engine/EditorMeshes/MatineeCam_SM.MatineeCam_SM");
	default DummyCamera.SetMaterial(0, Asset("/Game/Effects/Environment/Hopscotch/Niagara_Ball_Red.Niagara_Ball_Red"));

	UPROPERTY(EditConst)
	UHazeSplineComponentBase SplineComp;

	UPROPERTY(EditConst)
	float DistanceAlongSpline = 0.f;

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if (RootComponent.GetAttachParent() == nullptr)
			return;

		AActor AttachedTo = RootComponent.GetAttachParent().Owner;
		UCameraKeyedSplineRotatorComponent RotatorComp = UCameraKeyedSplineRotatorComponent::Get(AttachedTo);

		if (RotatorComp == nullptr)
			return;

		if (SplineComp == nullptr)
			return;

		DistanceAlongSpline = SplineComp.GetDistanceAlongSplineAtWorldLocation(Camera.WorldLocation);
		FVector Location = SplineComp.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		FKeyedCamera KeyedCam;
		KeyedCam.Camera = Camera;
		KeyedCam.DistanceAlongSpline = DistanceAlongSpline;
		RotatorComp.ReplaceKeyedCamera(KeyedCam);
		SetActorLocation(Location);
	}
}
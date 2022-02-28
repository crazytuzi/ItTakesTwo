import Vino.Camera.PointOfInterest.PointOfInterestStatics;
import Vino.Camera.Components.CameraUserComponent;

// This component will rotate to look at users current point of interest, disregarding whether there is camera control or not.
class UCameraPointOfInterestRotationComponent : UHazeCameraParentComponent
{
	UPROPERTY()
	float RotationAccelerationDuration = 1.f;

	UPROPERTY()
	float BlendOutDuration = 2.f;

	UCameraUserComponent User;
	FHazeAcceleratedFloat FocusRotationYaw;
	FHazeAcceleratedFloat FocusRotationPitch;

	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent _User, EHazeCameraState PreviousState)
	{
		User = Cast<UCameraUserComponent>(_User);
		ensure(User != nullptr);
		if (PreviousState == EHazeCameraState::Inactive)
			Snap();
	}

	UFUNCTION(BlueprintOverride)
	void Snap()
	{
		FRotator ParentLocalRot = User.WorldToLocalRotation(GetParentRot());
		FRotator LocalRot = ParentLocalRot;

		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		if(POI.PointOfInterest.FocusTarget.IsValid())
		{
			if (POI.PointOfInterest.Blend.BlendTime == 0.f)
				LocalRot = FPointOfInterestStatics::GetPointOfInterestLocalRotation(User, POI.PointOfInterest);	
		}

		FocusRotationYaw.SnapTo(LocalRot.Yaw);
		FocusRotationPitch.SnapTo(LocalRot.Pitch);		

		Update(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Update(float DeltaTime)
	{
		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		if (POI.PointOfInterest.FocusTarget.IsValid())
		{
			// Look towards point of interest
			FRotator POIRot = FPointOfInterestStatics::GetPointOfInterestLocalRotation(User, POI.PointOfInterest);
			float Duration = FMath::Max(0.f, POI.PointOfInterest.Blend.BlendTime); 
			if (!POI.PointOfInterest.bMatchFocusDirection)
				Duration *= 0.8f; // When we aim against a location, the target rotation will change over time, so duration needs to be shorter to compensate. TODO: Fix!

			float TweakedYaw = FPointOfInterestStatics::GetYawByTurnDirection(POIRot.Yaw, FocusRotationYaw.Value, POI.PointOfInterest);
			FocusRotationYaw.AccelerateTo(TweakedYaw, Duration, DeltaTime);
			float ShortestPathPitch = FocusRotationPitch.Value + FRotator::NormalizeAxis(POIRot.Pitch - FocusRotationPitch.Value);
			FocusRotationPitch.AccelerateTo(ShortestPathPitch, Duration, DeltaTime);
		}
		else
		{
			// Go back to parent rotation
			FRotator ParentLocalRot = User.WorldToLocalRotation(GetParentRot());
			float ShortestPathYaw = FocusRotationYaw.Value + FRotator::NormalizeAxis(ParentLocalRot.Yaw - FocusRotationYaw.Value);
			FocusRotationYaw.AccelerateTo(ShortestPathYaw, BlendOutDuration, DeltaTime);
			float ShortestPathPitch = FocusRotationPitch.Value + FRotator::NormalizeAxis(ParentLocalRot.Pitch - FocusRotationPitch.Value);
			FocusRotationPitch.AccelerateTo(ShortestPathPitch, BlendOutDuration, DeltaTime);
		}
		FRotator LocalRot = FRotator(FocusRotationPitch.Value, FocusRotationYaw.Value, 0.f);
		SetWorldRotation(User.LocalToWorldRotation(LocalRot));
	}

	FRotator GetParentRot()
	{
		USceneComponent Parent = GetAttachParent();
		if (Parent != nullptr)
			return Parent.WorldRotation;
		return Owner.ActorRotation;
	}
};

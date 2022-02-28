import Vino.Camera.Capabilities.CameraClampedPointOfInterestCapability;

class UCameraForcedClampedPointOfInterestCapability : UCameraClampedPointOfInterestCapability
{
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkActivation::DontActivate;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::ForcedClamped))
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || (Player == nullptr))
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (!User.HasPointOfInterest(EHazePointOfInterestType::ForcedClamped))
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		if (POI.PointOfInterest.Blend.BlendTime == 0.f)
		{
			// Snap to POI
			FRotator LocalRot = FPointOfInterestStatics::GetPointOfInterestLocalRotation(User, POI.PointOfInterest);
			FocusRotationYaw.Value = LocalRot.Yaw;
			FocusRotationPitch.Value = LocalRot.Pitch;
			FocusRotationYaw.Velocity = 0.f; 
			FocusRotationPitch.Velocity = 0.f; 
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeActivePointOfInterest POI = User.GetPointOfInterest();
		float BlendTime = POI.PointOfInterest.Blend.BlendTime; 
		float POITime = Time::GetGameTimeSince(POI.StartTime);
		if (POITime < BlendTime)
		{
			// Force camera direction towards point of interest over blend time, ignoring input
			ensure(BlendTime > 0.f);
			FRotator HerculePOIrot = FPointOfInterestStatics::GetPointOfInterestLocalRotation(User, POI.PointOfInterest);
			if (!POI.PointOfInterest.bMatchFocusDirection)
				BlendTime *= 0.8f; // When we aim against a location, the target rotation will change over time, so duration needs to be shorter to compensate. TODO: Fix!

			float TweakedYaw = FPointOfInterestStatics::GetYawByTurnDirection(HerculePOIrot.Yaw, FocusRotationYaw.Value, POI.PointOfInterest);
			FocusRotationYaw.AccelerateTo(TweakedYaw, BlendTime, DeltaTime);
			float ShortestPathPitch = FocusRotationPitch.Value + FRotator::NormalizeAxis(HerculePOIrot.Pitch - FocusRotationPitch.Value);
			FocusRotationPitch.AccelerateTo(ShortestPathPitch, BlendTime, DeltaTime);

			FRotator CurDesiredRot =  User.WorldToLocalRotation(User.GetDesiredRotation());
			FRotator DeltaRot = (FRotator(FocusRotationPitch.Value, FocusRotationYaw.Value, 0.f) - CurDesiredRot);
			DeltaRot = FPointOfInterestStatics::ApplyTurnScaling(DeltaRot, POI.PointOfInterest);	
			User.AddDesiredRotation(DeltaRot);
		}
		else 
		{
			// Behave as regular clamped point of interest
			Super::TickActive(DeltaTime);
		}
	}

	float GetInitialDampening(float BlendTime, float POITime)
	{
		if (BlendTime <= 0.f) 
			return 1.f; // Invalid or instant blend time
		
		if (POITime < BlendTime)
			return 0.f; // Still in initial blend

		if (POITime > BlendTime * 2.f)
			return 1.f; // Past initial blend dampening duration

		// Harder POI immediately after blend time
		return (POITime - BlendTime) / BlendTime;
	}
};

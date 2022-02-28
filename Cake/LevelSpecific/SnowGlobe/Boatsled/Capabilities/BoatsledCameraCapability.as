import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledCamera);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 65;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	FHazePointOfInterest FocusPoint;
	UCameraShakeBase CameraShake;

	UHazeSmoothSyncFloatComponent SyncSpeed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
		SyncSpeed = UHazeSmoothSyncFloatComponent::GetOrCreate(Owner, n"BoatsledCameraSpeedSync");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsSledding())
			return EHazeNetworkActivation::DontActivate;

		if(BoatsledComponent.IsJumping())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Push camera settings and add camera shake
		PlayerOwner.ApplyCameraSettings(BoatsledComponent.Boatsled.CameraSpringArmSettings, FHazeCameraBlendSettings(2.f), this);
		CameraShake = PlayerOwner.PlayCameraShake(BoatsledComponent.Boatsled.CameraShake);

		// Setup basic point of interest data
		FocusPoint.Blend = 1.f;
		FocusPoint.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
			SyncSpeed.SetValue(BoatsledComponent.Boatsled.MovementComponent.Velocity.Size());

		float NormalSpeed = Math::Saturate(SyncSpeed.Value / BoatsledComponent.Boatsled.MaxSpeed);

		// Get spline distance at world offset
		float DistanceAheadAlongSpline = BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(BoatsledComponent.Boatsled.GetActorLocation()) + BoatsledComponent.FlexSplineCameraOffset;

		FVector	LocationOfInterest;
		if(BoatsledComponent.CameraLocationOfInterestOverride.IsZero())
		{
			LocationOfInterest = BoatsledComponent.TrackSpline.GetLocationAtDistanceAlongSpline(DistanceAheadAlongSpline, ESplineCoordinateSpace::World);
			LocationOfInterest += BoatsledComponent.Boatsled.ActorForwardVector * BoatsledComponent.FlexSplineCameraOffset * 0.8f;
		}
		else
		{
			LocationOfInterest = BoatsledComponent.CameraLocationOfInterestOverride;
		}

		FocusPoint.FocusTarget.WorldOffset = LocationOfInterest;
		PlayerOwner.ApplyPointOfInterest(FocusPoint, this);

		// Increase camera shake the faster sled goes
		CameraShake = PlayerOwner.PlayCameraShake(BoatsledComponent.Boatsled.CameraShake, NormalSpeed * 0.5f);

		// Increase FOV the faster sled goes
		float Fov = FMath::Lerp(BoatsledComponent.FovRange.Min, BoatsledComponent.FovRange.Max, NormalSpeed);
		PlayerOwner.ApplyFieldOfView(Fov, FHazeCameraBlendSettings(0.1f), this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsSledding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BoatsledComponent.IsJumping())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.StopCameraShake(CameraShake);
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(this);
	}
}
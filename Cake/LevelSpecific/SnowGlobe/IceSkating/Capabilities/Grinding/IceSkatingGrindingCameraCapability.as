import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Effects.PostProcess.PostProcessing;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;

class UIceSkatingGrindingCameraCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Camera);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 145;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UHazeMovementComponent MoveComp;
	UCameraComponent CameraComp;
	UCameraUserComponent CameraUser;
	UPostProcessingComponent PostProcessComp;
	UIceSkatingComponent SkateComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;
	FVector DefaultPivotOffset;

	FHazeAcceleratedFloat AcceleratedLookAtScale;
	float DefaultOffsetDirection = 1.f;

	float InterpedSpeedPercentage = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		PostProcessComp = UPostProcessingComponent::Get(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);

		FHazeCameraSpringArmSettings Settings;
		CameraUser.GetCameraSpringArmSettings(Settings);
		DefaultPivotOffset = Settings.PivotOffset;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!SkateComp.bIsIceSkating)
        	return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);

		InterpedSpeedPercentage = UserGrindComp.SpeedPercentageIncludingBoost;
		SetMutuallyExclusive(GrindingCapabilityTags::Camera, true);

		if (UserGrindComp.CameraSettings != nullptr)
		{
			FHazeCameraBlendSettings Blend;
			Player.ApplyCameraSettings(UserGrindComp.CameraSettings, Blend, this, EHazeCameraPriority::Low);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CameraComp.SetRelativeRotation(FRotator::ZeroRotator);
		Player.ClearCameraSettingsByInstigator(this);
		SetMutuallyExclusive(GrindingCapabilityTags::Camera, false);

		PostProcessComp.SpeedShimmer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		UpdatePivotOffset();
		UpdateDesiredRotation(DeltaTime);

		InterpedSpeedPercentage = FMath::FInterpTo(InterpedSpeedPercentage, UserGrindComp.SpeedPercentageIncludingBoost, DeltaTime, 12.f);
		UpdateFOV(DeltaTime);

		float ShimmerStrength = GrindSettings::Grinding.ShimmerMin + (InterpedSpeedPercentage * GrindSettings::Grinding.ShimmerAddtional);
		PostProcessComp.SpeedShimmer = ShimmerStrength;
	}

	void UpdatePivotOffset()
	{
		FHazeSplineSystemPosition PivotOffsetSystemPosition = UserGrindComp.SplinePosition;
		FVector PivotOffsetLocation;

		float RemainingMoveAmount = 0.f;
		if (!PivotOffsetSystemPosition.Move(GrindSettings::Grinding.CameraFutureTestDistance, RemainingMoveAmount))
			PivotOffsetLocation = PivotOffsetSystemPosition.WorldLocation + (PivotOffsetSystemPosition.WorldForwardVector * RemainingMoveAmount);
		else
			PivotOffsetLocation = PivotOffsetSystemPosition.WorldLocation;

		FVector ToPivotOffsetLocation = PivotOffsetLocation - Owner.ActorLocation;
		ToPivotOffsetLocation.Z = 0.f;
		ToPivotOffsetLocation.Normalize();

		FVector Tangent = PivotOffsetSystemPosition.WorldForwardVector;
		Tangent.Z = 0.f;
		Tangent.Normalize();

		float AngleDifference = Math::DotToDegrees(Tangent.DotProduct(ToPivotOffsetLocation.GetSafeNormal()));
		
		float HorizontalPivotOffsetPercentage = Math::GetPercentageBetweenClamped(0.f, GrindSettings::Grinding.HorizontalPivotOffsetAngleMax, AngleDifference);
		float HorizontalPivotOffsetDistance = GrindSettings::Grinding.HorizontalPivotOffsetMax * HorizontalPivotOffsetPercentage * -FMath::Sign(ToPivotOffsetLocation.DotProduct(PivotOffsetSystemPosition.WorldRightVector));

		FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		FVector MoveInputDirection = MoveInput.GetSafeNormal();

		float MoveTangentAngleDifference = Math::DotToDegrees(MoveInputDirection.DotProduct(Tangent));
		if (MoveTangentAngleDifference > 90.f)
			MoveTangentAngleDifference = 180.f - MoveTangentAngleDifference;

		if (FMath::Abs(HorizontalPivotOffsetDistance) > 10.f)
		{
			DefaultOffsetDirection = FMath::Sign(HorizontalPivotOffsetDistance);
		}
		else if (MoveInput.Size() > 0.25f && MoveTangentAngleDifference >= 35.f)
		{
			FVector TangentRight = UserGrindComp.SplinePosition.WorldRightVector;
			TangentRight.Z = 0.f;
			TangentRight.Normalize();

			DefaultOffsetDirection = FMath::Sign(MoveInputDirection.DotProduct(TangentRight));
		}

		FVector CameraOffset;
		CameraOffset += FVector::RightVector * DefaultOffsetDirection * 50.f;
		CameraOffset += FVector::RightVector * HorizontalPivotOffsetDistance;
		CameraOffset += FVector::ForwardVector * -100.f;

		FHazeCameraSpringArmSettings Settings;
		Settings.bUseCameraOffset = true;
		Settings.CameraOffset = CameraOffset;
		Settings.bUseCameraOffsetBlockedFactor = true;
		Settings.CameraOffsetBlockedFactor = 0.f; // This will reduce camera offset when blocked.
		Settings.bUsePivotLagSpeed = true;
		Settings.PivotLagSpeed = FVector(0.7f, 0.7f, 0.8f);
		Player.ApplyCameraSpringArmSettings(Settings, CameraBlend::Normal(2.f), this, EHazeCameraPriority::High);
		
		// Apply pivot offset additively
		Player.ApplyPivotOffset(FVector::UpVector * 125.f, CameraBlend::Additive(2.f), this, EHazeCameraPriority::High);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FHazeSplineSystemPosition CameraLookAtSystemPosition = UserGrindComp.SplinePosition;
		FVector CameraLookAtLocation;

		float RemainingMoveAmount = 0.f;
		if (!CameraLookAtSystemPosition.Move(1800.f, RemainingMoveAmount))
			CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation + (CameraLookAtSystemPosition.WorldForwardVector * RemainingMoveAmount);
		else
			CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation;

		FVector CameraLocation = Player.ViewLocation;
		FVector ToTarget = CameraLookAtLocation - CameraLocation;
		ToTarget.Z *= 0.8f;

		FRotator CameraRotation = Math::MakeRotFromX(ToTarget);
		CameraRotation.Roll = 0.f;
		
		/*
			- If input is given, the auto look at should be disabled
			- If no input is given, the auto look at should accerate in over time
			- Or there is a point of interest, autolook should be disabled
		*/		
		if (GetAttributeVector(AttributeVectorNames::CameraDirection).IsNearlyZero() || Owner.IsAnyCapabilityActive(CameraTags::PointOfInterest))
			AcceleratedLookAtScale.AccelerateTo(1.f, 2.5f, DeltaTime);
		else
			AcceleratedLookAtScale.SnapTo(0.f);

		AcceleratedTargetRotation.Value = CameraUser.DesiredRotation;
		AcceleratedTargetRotation.AccelerateTo(CameraRotation, 1.f, DeltaTime * AcceleratedLookAtScale.Value);

		if (!Owner.IsAnyCapabilityActive(CameraTags::PointOfInterest))
			CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}

	void UpdateFOV(float DeltaTime)
	{
		float CurrentFOV = Player.GetPlayerViewFOV();
		float NewFOV = GrindSettings::Grinding.CameraDefaultFOV + (InterpedSpeedPercentage * GrindSettings::Grinding.CameraAdditionalFOVAtMaxSpeed);
		
		Player.ApplyFieldOfView(NewFOV, FHazeCameraBlendSettings(1.f), this, EHazeCameraPriority::High);
	}
}

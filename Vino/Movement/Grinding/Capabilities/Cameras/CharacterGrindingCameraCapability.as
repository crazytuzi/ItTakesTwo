import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Effects.PostProcess.PostProcessing;
import Peanuts.SpeedEffect.SpeedEffectStatics;
import Vino.Movement.Grinding.Capabilities.Grinding.CharacterGrindingJumpCapability;

class UCharacterGrindingCameraCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);
	default RespondToEvent(GrindingActivationEvents::TargetGrind);

	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Camera);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	USplineLockComponent SplineLockComp;

	UHazeMovementComponent MoveComp;
	UCameraComponent CameraComp;
	UCameraUserComponent CameraUser;
	UPostProcessingComponent PostProcessComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	FHazeAcceleratedFloat AcceleratedLookAtScale;
	float DefaultOffsetDirection = 1.f;

	float InterpedSpeedPercentage = 0.f;

	FGrindSplineData GrindCameraSplineData;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		SplineLockComp = USplineLockComponent::GetOrCreate(Owner);

		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CameraComp = UCameraComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		PostProcessComp = UPostProcessingComponent::Get(Owner);

		FHazeCameraSpringArmSettings Settings;
		CameraUser.GetCameraSpringArmSettings(Settings);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkActivation::ActivateLocal;

		if (UserGrindComp.HasTargetGrindSpline())
       		return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (UserGrindComp.HasActiveGrindSpline())
       		return EHazeNetworkDeactivation::DontDeactivate;

		if (UserGrindComp.HasTargetGrindSpline())
       		return EHazeNetworkDeactivation::DontDeactivate;

		if (!UserGrindComp.IsSplineLocked())
       		return EHazeNetworkDeactivation::DeactivateLocal;

		if (Player.IsAnyCapabilityActive(UCharacterGrindingJumpCapability::StaticClass()))
       		return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);

		InterpedSpeedPercentage = UserGrindComp.SpeedPercentageIncludingBoost;

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
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (UserGrindComp.HasActiveGrindSpline())
			GrindCameraSplineData = UserGrindComp.ActiveGrindSplineData;
		else if (UserGrindComp.HasTargetGrindSpline())
			GrindCameraSplineData = UserGrindComp.TargetGrindSplineData;
		else if (Player.IsAnyCapabilityActive(UCharacterGrindingJumpCapability::StaticClass()))
		{
			
			FGrindSplineData GrindSplineLocationData;
			float Distance = BIG_NUMBER;
			
			TArray<AGrindspline> NearbyGrindSplines = UserGrindComp.ValidNearbyGrindSplines;
			for (FGrindSplineCooldown GrindCooldown : UserGrindComp.GrindSplineCooldowns)
			{
				if (GrindCooldown.GrindSpline != nullptr)
					NearbyGrindSplines.Add(GrindCooldown.GrindSpline);
			}
			for (AGrindspline PotentialGrindSpline : NearbyGrindSplines)
			{
				if (!PotentialGrindSpline.bGrindingAllowed)
					continue;

				float DistanceAlongSpline = 0.f;
				FGrindSplineData PotentialData = FGrindSplineData(PotentialGrindSpline, Owner.ActorLocation);

				FVector ToPotentialPosition = PotentialData.SystemPosition.WorldLocation - Owner.ActorLocation;
				float PotentialDistance = ToPotentialPosition.Size();

				// Set as current best spline if distance is nearer
				if (PotentialDistance < Distance)
				{
					GrindSplineLocationData = PotentialData;
					Distance = PotentialDistance;
				}
			}


			GrindCameraSplineData = GrindSplineLocationData;
		}

		FVector HorizontalVelocity = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp);
		if (HorizontalVelocity.DotProduct(GrindCameraSplineData.SystemPosition.WorldForwardVector) < 0.f)
			GrindCameraSplineData.SystemPosition.Reverse();

		if (IsDebugActive())
			System::DrawDebugSphere(GrindCameraSplineData.SystemPosition.WorldLocation, 25.f, 12, FLinearColor::Red, 0.f, 3.f);

		UpdatePivotOffset();
		UpdateDesiredRotation(DeltaTime);

		InterpedSpeedPercentage = FMath::FInterpTo(InterpedSpeedPercentage, UserGrindComp.SpeedPercentageIncludingBoost, DeltaTime, 12.f);
		UpdateFOV(DeltaTime);

		float ShimmerStrength = GrindSettings::Grinding.ShimmerMin + (InterpedSpeedPercentage * GrindSettings::Grinding.ShimmerAddtional);
		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(ShimmerStrength, this));
	}

	void UpdatePivotOffset()
	{
		FHazeSplineSystemPosition PivotOffsetSystemPosition = GrindCameraSplineData.SystemPosition;
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
			DefaultOffsetDirection = FMath::Sign(HorizontalPivotOffsetDistance);
		else if (MoveInput.Size() > 0.25f && MoveTangentAngleDifference >= 35.f)
		{
			FVector TangentRight = GrindCameraSplineData.SystemPosition.WorldRightVector;
			//FVector TangentRight = UserGrindComp.SplinePosition.WorldRightVector;
			TangentRight.Z = 0.f;
			TangentRight.Normalize();

			DefaultOffsetDirection = FMath::Sign(MoveInputDirection.DotProduct(TangentRight));
		}

		// Grindspline can become nullptr when a spline is removed (e.g. moving bridge in clockwork town). 
		// Just stop updating camera settings when that happens.
		if (GrindCameraSplineData.GrindSpline == nullptr)
			return;

		FHazeCameraSpringArmSettings Settings;
		Settings.bUseCameraOffset = true;
		Settings.CameraOffset += FVector(0.f, 0.f, -125.f);
		if (GrindCameraSplineData.GrindSpline.bAllowHorizontalCameraOffset)
		{
			Settings.CameraOffset = FVector(0.f, HorizontalPivotOffsetDistance, 0.f);
			Settings.CameraOffset += FVector(0.f, 100.f * DefaultOffsetDirection, 0.f);
		}
		Player.ApplyCameraSpringArmSettings(Settings, CameraBlend::Normal(2.f), this, EHazeCameraPriority::High);

		// Apply pivot offset additively
		Player.ApplyPivotOffset(GrindCameraSplineData.GrindSpline.CameraAdditionalPivotOffset, CameraBlend::Additive(2.f), this, EHazeCameraPriority::High);
	}

	void UpdateDesiredRotation(float DeltaTime)
	{	
		FHazeSplineSystemPosition CameraLookAtSystemPosition = GrindCameraSplineData.SystemPosition;
		FVector CameraLookAtLocation;

		float HeightOnSpline = (Owner.ActorLocation - CameraLookAtSystemPosition.WorldLocation).DotProduct(MoveComp.WorldUp);

		float RemainingMoveAmount = 0.f;
		if ((GrindCameraSplineData.GrindSpline != nullptr) &&  // Can become null when a spline is removed
			!CameraLookAtSystemPosition.Move(GrindCameraSplineData.GrindSpline.DesiredDirectionProjectionDistance, RemainingMoveAmount))
		{
			CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation;
			// Add the overshoot onto the camera location
			CameraLookAtLocation += (CameraLookAtSystemPosition.WorldForwardVector * RemainingMoveAmount);
			// Add the player overshoot to the camera location

			// float PlayerOvershoot = (Player.ActorLocation - CameraLookAtSystemPosition.WorldLocation).DotProduct(CameraLookAtSystemPosition.WorldForwardVector);
			// CameraLookAtLocation += CameraLookAtSystemPosition.WorldForwardVector * PlayerOvershoot;
		}
		else
			CameraLookAtLocation = CameraLookAtSystemPosition.WorldLocation;
		CameraLookAtLocation += MoveComp.WorldUp * HeightOnSpline * 0.6f;

		if (IsDebugActive())
			System::DrawDebugSphere(CameraLookAtLocation, 50.f, 12, FLinearColor::Green, 0.f, 3.f);
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
			AcceleratedLookAtScale.AccelerateTo(1.f, 3.f, DeltaTime);
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

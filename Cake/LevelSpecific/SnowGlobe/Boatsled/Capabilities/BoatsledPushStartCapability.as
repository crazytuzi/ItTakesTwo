import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Peanuts.ButtonMash.ButtonMashComponent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UBoatsledPushStartCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledPushStart);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 61;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MovementComponent;

	ABoatsled Boatsled;
	UBoatsledComponent BoatsledComponent;

	UCameraShakeBase CameraShake;

	FVector InitialLocation;
	float InitialDistanceAlongSpline;
	float TargetDistanceAlongSpline;

	UButtonMashProgressHandle ButtonMashHandle;
	float ButtonMashProgression;

	const float AccelerationMagnitude = 30.f;
	const float PushStartDistance = 2000.f;
	const float PushStartMaxSpeed = 1500.f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.IsPushingSled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(const FCapabilityActivationParams& ActivationParams)
	{
		BlockCapabilities();

		Boatsled = BoatsledComponent.Boatsled;

		// Turn off mesh collision
		Boatsled.MeshComponent.SetCollisionProfileName(n"NoCollision");

		// Store info for progress validation
		InitialDistanceAlongSpline = BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		InitialLocation = BoatsledComponent.TrackSpline.GetLocationAtDistanceAlongSpline(InitialDistanceAlongSpline, ESplineCoordinateSpace::World);
		TargetDistanceAlongSpline = InitialDistanceAlongSpline + PushStartDistance;

		// Place button mash widget
		ButtonMashHandle = StartButtonMashProgressAttachToActor(PlayerOwner, Boatsled, FVector(0.f, PlayerOwner.IsMay() ? -50.f : 50.f, 140.f));

		// Apply push start camera settings
		PlayerOwner.ApplyCameraSettings(BoatsledComponent.Boatsled.PushStartSpringArmSettings, 3.f, this);

		// Immediately set boatsled's mesh rotation to the actor's original before moving ('cause moving will clear actor roll)
		BoatsledComponent.RotateBoatsledMeshOffsetToSlope(Boatsled.ActorForwardVector, Boatsled.ActorUpVector, 0.f);

		if(HasControl())
			if(!ensure(Boatsled.SphereCollider.CollisionProfileName != n"NoCollision"))
				BoatsledComponent.SetBoatsledCollisionEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = Boatsled.MovementComponent.MakeFrameMovement(n"BoatsledPushStart");
		MoveData.OverrideStepDownHeight(80.f);
		MoveData.FlagToMoveWithDownImpact();
		MoveData.OverrideStepUpHeight(5.f);

		float NormalizedSpeed = GetNormalizedPushStartSpeed();

		if(HasControl())
		{
			FVector SplineVector = BoatsledComponent.GetSplineVector();

			FVector BaseAutoAcceleration = SplineVector * AccelerationMagnitude * BoatsledComponent.Boatsled.AccelerationCurve.GetFloatValueNormalized(ActiveDuration / 2.f) * DeltaTime;
			FVector Acceleration = SplineVector * ButtonMashHandle.MashRateControlSide * AccelerationMagnitude * Boatsled.PushStartAccelerationCurve.GetFloatValue(NormalizedSpeed) * DeltaTime;

			FVector RubberBandAcceleration = FVector::ZeroVector;
			float NormalLag = 0.f;
			if(PlayerIsBehind(NormalLag))
				RubberBandAcceleration = SplineVector * FMath::Square(AccelerationMagnitude) * NormalLag * DeltaTime;

			FVector Velocity = Boatsled.MovementComponent.GetVelocity() + BaseAutoAcceleration + Acceleration + RubberBandAcceleration;
			MoveData.ApplyVelocity(Velocity.GetClampedToMaxSize(PushStartMaxSpeed));

			if(!Velocity.IsZero())
			{
				Boatsled.MovementComponent.SetTargetFacingDirection(BoatsledComponent.GetSplineVector());
				MoveData.ApplyTargetRotationDelta();
			}

			Boatsled.MovementComponent.Move(MoveData);
			Boatsled.CrumbComponent.LeaveMovementCrumb();

			// Shake it baby
			float RumbleNoise = FMath::Abs(FMath::PerlinNoise1D(Time::GameTimeSeconds * 2.f)) * FMath::Max(0.1f, ButtonMashProgression) * 0.2f;
			PlayerOwner.SetFrameForceFeedback(RumbleNoise, ButtonMashProgression * 0.012f);
		}
		else
		{
			BoatsledComponent.ConsumeMovementCrumb(MoveData, DeltaTime);
			if(!MoveData.Velocity.IsZero())
				Boatsled.MovementComponent.Move(MoveData);
		}

		// Rotate mesh offset to fit slope
		FVector GroundNormal;
		BoatsledComponent.GetGroundNormal(GroundNormal);
		BoatsledComponent.RotateBoatsledMeshOffsetToSlope(BoatsledComponent.GetSplineVector(), GroundNormal, 2.f);

		// Update le progression
		float DistanceAlongSpline = BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
		ButtonMashProgression = (DistanceAlongSpline - InitialDistanceAlongSpline) / (TargetDistanceAlongSpline - InitialDistanceAlongSpline);
		ButtonMashHandle.Progress = ButtonMashProgression;

		// Update speed BS value and Request locomotion
		BoatsledComponent.PushStartSpeedBlendSpaceValue = NormalizedSpeed;
		BoatsledComponent.RequestPlayerBoatsledLocomotion();

		// Shake dat cam
		CameraShake = PlayerOwner.PlayCameraShake(Boatsled.CameraShake, NormalizedSpeed * 0.5f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!BoatsledComponent.IsPushingSled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(HasControl() && BoatsledHasReachedSleddingStart())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FCapabilityDeactivationParams& DeactivationParams)
	{
		UnblockCapabilities();

		// Clear camera stuff
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.StopCameraShake(CameraShake, false);

		// Start sledding!
		if(HasControl() && DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
			BoatsledComponent.SetStateWithCrumb(EBoatsledState::HalfPipeSledding);

		// Fire event!
		BoatsledComponent.BoatsledEventHandler.OnPlayerHoppingAboard.Broadcast();

		// Cleanup
		ButtonMashHandle.StopButtonMash();
		ButtonMashHandle = nullptr;
		CameraShake = nullptr;
	}

	bool PlayerIsBehind(float& NormalLag)
	{
		bool bIsBehind = false;
		float Delta = BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(BoatsledComponent.Boatsled.ActorLocation) - BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(BoatsledComponent.Boatsled.OtherBoatsled.ActorLocation);
		if(Delta < 0.f)
			bIsBehind = true;

		NormalLag = Math::Saturate(FMath::Abs(Delta) / (TargetDistanceAlongSpline - InitialDistanceAlongSpline));
		return bIsBehind;
	}

	float GetNormalizedPushStartSpeed()
	{
		return FMath::Max(0.1f, Math::Saturate(Boatsled.MovementComponent.ActualVelocity.Size() / PushStartMaxSpeed));
	}

	bool BoatsledHasReachedSleddingStart() const
	{
		return BoatsledComponent.TrackSpline.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation) >= TargetDistanceAlongSpline;
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::MovementAction, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::AirMovement, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementInput, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::MovementAction, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::AirMovement, this);
	}
}
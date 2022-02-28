import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.SwimmingCollisionHandler;
import Vino.Movement.Capabilities.Swimming.Vortex.SwimmingVortexSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USwimmingVortexMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Underwater);
	default CapabilityTags.Add(SwimmingTags::Vortex);
	default CapabilityTags.Add(SwimmingTags::VortexMovement);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 75;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;
	FSwimmingVortexSettings VortexSettings;

	FHazeAcceleratedVector AcceleratedHorizontalVelocity;
	FHazeAcceleratedFloat AcceleratedTurnRate;

	// Used for audio
	bool bIsMovingUp = false;
	bool bIsMovingDown = false;
	bool bIsTurning = false;
	bool bIsUnderwater = false;
	bool bIsUnderwaterPrevious = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bIsUnderwaterPrevious = bIsUnderwater;
		bIsUnderwater = SwimComp.bIsUnderwater	;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const 
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!SwimComp.bVortexActive)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!SwimComp.bVortexActive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"SwimmingSurface", this);
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(n"PlayerShadow", this);
	
		//FVector RelativeVelocity
		AcceleratedHorizontalVelocity.SnapTo(-GetHorizontalToVortex(), MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp));
		SwimComp.SwimmingState = ESwimmingState::Vortex;

		AcceleratedTurnRate.SnapTo(0.f);

		SwimComp.PlaySplashSound(HazeAkComp, MoveComp.Velocity.Size(), ESplashType::Vortex);

		bIsMovingUp = false;
		bIsMovingDown = false;
		bIsTurning = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"SwimmingSurface", this);
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(n"PlayerShadow", this);

		if (SwimComp.AudioData[Player].VortexExited != nullptr)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].VortexExited);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"SwimmingVortex");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"SwimmingVortex");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	

		if (HasControl())
		{
			FVector MoveInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
			FVector CameraInput = GetAttributeVector(AttributeVectorNames::CameraDirection);

			// Horizontal Velocity
			//AcceleratedHorizontalVelocity.SpringTo(FVector::ZeroVector, VortexSettings.VortexStiffness, VortexSettings.VortexDamping, DeltaTime);
			AcceleratedHorizontalVelocity.AccelerateTo(FVector::ZeroVector, 2.2f, DeltaTime);

			FVector HorizontalDelta = AcceleratedHorizontalVelocity.Value - -HorizontalToVortex;
			FrameMove.ApplyDelta(HorizontalDelta);

			// Vertical Velocity
			FVector VerticalVelocity = MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp);

			// Update vertical scale
			float VerticalScale = GetDeadzonedFloat(MoveInput.X, .5f);
			if (IsActioning(ActionNames::MovementJump))
				VerticalScale += 1.f;
			if (IsActioning(ActionNames::MovementCrouch))
				VerticalScale -= 1.f;
			VerticalScale = FMath::Clamp(VerticalScale, -1.f, 1.f);
			SwimComp.VerticalScale = VerticalScale;

			CrumbComp.SetReplicatedInputDirection(FVector(VerticalScale, 0.f, 0.f));			

			VerticalVelocity += MoveComp.WorldUp * VerticalScale * VortexSettings.VerticalAcceleration * DeltaTime;

			// Vertical Drag
			VerticalVelocity -= VerticalVelocity * VortexSettings.VerticalDrag * DeltaTime;
			FVector VerticalFrameMove = VerticalVelocity * DeltaTime;
			
			// Test you aren't going outside of the capsule
			FVector FuturePlayerLocation = Player.CapsuleComponent.WorldLocation + (VerticalVelocity * DeltaTime);
			FVector CenterVortexToPlayer = FuturePlayerLocation - SwimComp.ActiveVortexData.VortexTransform.Location;
			float DistanceFromCenter = CenterVortexToPlayer.DotProduct(SwimComp.ActiveVortexData.VortexTransform.Rotation.UpVector);

			const float Margin = 50.f; //SwimComp.ActiveVortexData.HardLimitMargin;
			FVector ExtraMargin = SwimComp.ActiveVortexData.VortexTransform.Rotation.UpVector * FMath::Sign(DistanceFromCenter) * Margin;
			FVector ExtraCapsuleHalfHeight = SwimComp.ActiveVortexData.VortexTransform.Rotation.UpVector * FMath::Sign(DistanceFromCenter) * Player.CapsuleComponent.CapsuleHalfHeight;
			FVector PeakPlayerLocation = CenterVortexToPlayer + ExtraMargin + ExtraCapsuleHalfHeight;
			

			FVector VortexLimit = SwimComp.ActiveVortexData.VortexTransform.Rotation.UpVector * SwimComp.ActiveVortexData.CapsuleHalfHeight * FMath::Sign(DistanceFromCenter);
			FVector VortexLimitToPlayer = PeakPlayerLocation - VortexLimit;
			float Overshoot = VortexLimitToPlayer.DotProduct(MoveComp.WorldUp * FMath::Sign(DistanceFromCenter));

			if (Overshoot > 0.f)
			{
				VerticalFrameMove -= SwimComp.ActiveVortexData.VortexTransform.Rotation.UpVector * Overshoot;
				VerticalVelocity = FVector::ZeroVector;//SwimComp.ActiveVortexData.VortexTransform.Rotation.UpVector * FMath::Sign(DistanceFromCenter);
			}
			FrameMove.ApplyDeltaWithCustomVelocity(VerticalFrameMove, VerticalVelocity);

			if (IsDebugActive())
			{
				System::DrawDebugLine(SwimComp.ActiveVortexData.VortexTransform.Location, SwimComp.ActiveVortexData.VortexTransform.Location + VortexLimit, FLinearColor::Blue, 0.f, 2.f);
				System::DrawDebugLine(SwimComp.ActiveVortexData.VortexTransform.Location, SwimComp.ActiveVortexData.VortexTransform.Location + PeakPlayerLocation, FLinearColor::Green, 0.f, 4.f);
				System::DrawDebugLine(SwimComp.ActiveVortexData.VortexTransform.Location, SwimComp.ActiveVortexData.VortexTransform.Location + CenterVortexToPlayer, FLinearColor::Red, 0.f, 7.f);
			}

			// Rotation
			float RotationScale = CameraInput.X + MoveInput.Y;
			RotationScale = FMath::Clamp(RotationScale, -1.f, 1.f);
			float RotationRate = VortexSettings.RotationRate * DEG_TO_RAD * RotationScale;			
			AcceleratedTurnRate.AccelerateTo(RotationRate, 0.2f, DeltaTime);


			// Audio:: Turning
			if (!FMath::IsNearlyZero(RotationScale))
			{
				if (!bIsTurning && SwimComp.AudioData[Player].VortexStartedTurning != nullptr)
					HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].VortexStartedTurning);

				bIsTurning = true;
			}
			else
			{
				if (bIsTurning && SwimComp.AudioData[Player].VortexStoppedTurning != nullptr)
					HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].VortexStoppedTurning);

				bIsTurning = false;
			}
			//Print("RotationScale: " + RotationScale);

			// Update facing direction
			FVector FacingDirection = Owner.ActorForwardVector;
			FQuat RotationQuat = FQuat(MoveComp.WorldUp, AcceleratedTurnRate.Value * DeltaTime);
			FacingDirection = RotationQuat * FacingDirection;	

			MoveComp.SetTargetFacingDirection(FacingDirection);
			FrameMove.ApplyTargetRotationDelta();
			
			FrameMove.ApplyAndConsumeImpulses();
			FrameMove.OverrideStepDownHeight(0.f);
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);	

			FVector Input = ConsumedParams.GetReplicatedInput();
			SwimComp.VerticalScale = Input.X;
		}	


		if (SwimComp.VerticalScale > 0.f)
		{
			if (!bIsMovingUp)
			{
				bIsMovingUp = true;
				bIsMovingDown = false;

				if (SwimComp.AudioData[Player].VortexStartedMovingUp != nullptr)
					HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].VortexStartedMovingUp);
			}
		}
		else if (SwimComp.VerticalScale < 0.f)
		{
			if (!bIsMovingDown)
			{
				bIsMovingDown = true;
				bIsMovingUp = false;

				if (SwimComp.AudioData[Player].VortexStartedMovingDown != nullptr)
					HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].VortexStartedMovingDown);
			}
		}
		else if (bIsMovingUp || bIsMovingDown)
		{
			bIsMovingUp = false;
			bIsMovingDown = false;
			
			if (SwimComp.AudioData[Player].VortexStoppedMoving != nullptr)
				HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].VortexStoppedMoving);
		}
	}

	FVector GetHorizontalToVortex() property
	{
		FVector DirToVortex = SwimComp.ActiveVortexData.VortexTransform.Location - Owner.ActorLocation;
		DirToVortex = DirToVortex.ConstrainToPlane(MoveComp.WorldUp);

		return DirToVortex;
	}

	FVector ProjectPointOntoLineFromLocation(FVector ProjectedLocation, FVector LineOrigin, FVector LineDirection)
	{
		FVector ToProjectedLocation = ProjectedLocation - LineOrigin;
		float Length = ToProjectedLocation.DotProduct(LineDirection);
		return LineOrigin + (LineDirection * Length);
	}
}

float GetDeadzonedFloat(float Value, float BottomDeadzone = 0.2f, float TopDeadzone = 0.f)
{
	return FMath::Clamp((FMath::Abs(Value) - BottomDeadzone) / ((1 - TopDeadzone) - BottomDeadzone), 0.f, 1.f) * FMath::Sign(Value);
}

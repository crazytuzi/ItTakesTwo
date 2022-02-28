import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Swimming.SwimmingCollisionHandler;
import Vino.Movement.Capabilities.Swimming.SwimmingSettings;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Vino.Movement.Capabilities.Swimming.Core.SnowGlobeSwimmingStatics;
import Vino.Movement.Jump.AirJumpsComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;

class USnowGlobeSwimmingMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Underwater);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UCharacterAirJumpsComponent AirJumpsComp;
	UPlayerHazeAkComponent HazeAkComp;
	FHazeAcceleratedRotator ControlRotation;

	const float DesiredDeceleration = 250.f;

	bool bStartedSwimming = false;
	ESwimmingSpeedState AudioSwimmingState = ESwimmingSpeedState::Normal;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);	
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SwimComp.DesiredDecayCooldown > 0.f)
			SwimComp.DesiredDecayCooldown -= DeltaTime;

		if (SwimComp.DesiredLockCooldown > 0.f)
			SwimComp.DesiredLockCooldown -= DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SwimComp.bIsInWater)
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (SwimComp.SwimmingState != ESwimmingState::Swimming)
			return EHazeNetworkDeactivation::DeactivateLocal;		

		if (!SwimComp.bIsInWater)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AudioSwimmingState = ESwimmingSpeedState::Normal;
		SwimComp.SwimmingState = ESwimmingState::Swimming;
		ControlRotation.SnapTo(Player.ControlRotation);

		Player.BlockCapabilities(n"AirJump", this);
		Player.BlockCapabilities(n"AirDash", this);
		Player.BlockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::Dash, this);
		Player.BlockCapabilities(n"PlayerShadow", this);


		AirJumpsComp.ResetJumpAndDash();

		/*
			Check what your entry desired should be.
			- If your previous speed was cruise, you are allowed to re-enter in cruise
			- If your previous was not, clamp to fast speed */
		float ClampMax = SwimComp.SwimmingSpeedState != ESwimmingSpeedState::Cruise ? SwimmingSettings::Speed.DesiredCruise : SwimmingSettings::Speed.DesiredMax;
		SwimComp.DesiredSpeed = FMath::Clamp(MoveComp.Velocity.Size(), SwimmingSettings::Speed.DesiredMin, ClampMax);
		SwimComp.DesiredDecayCooldown = 0.f;

		SwimComp.UpdateSwimmingSpeedState();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"AirJump", this);
		Player.UnblockCapabilities(n"AirDash", this);
		Player.UnblockCapabilities(MovementSystemTags::GroundMovement, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::Dash, this);
		Player.UnblockCapabilities(n"PlayerShadow", this);

		if (bStartedSwimming)
		{
			bStartedSwimming = false;
			if (!Player.IsAnyCapabilityActive(FMagneticTags::PlayerMagneticBuoyCapability) && SwimComp.AudioData[Player].SubmergedStoppedMoving != nullptr)
				HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedStoppedMoving);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		SwimmingStatics::UpdateControlRotation(Player, DeltaTime, GetAttributeVector2D(AttributeVectorNames::CameraDirection), ControlRotation);

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Swimming");
		CalculateFrameMove(FrameMove, DeltaTime);
		MoveCharacter(FrameMove, n"Swimming");
		
		CrumbComp.LeaveMovementCrumb();
	}	

	void CalculateFrameMove(FHazeFrameMovement& FrameMove, float DeltaTime)
	{	
		if (HasControl())
		{
			FVector Velocity = MoveComp.Velocity;
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);

			// Update move direction
			SwimComp.VerticalScale = 0.f;
			if (IsActioning(ActionNames::MovementJump))
				SwimComp.VerticalScale += SwimmingSettings::Speed.VerticalInputScale;
			if (IsActioning(ActionNames::MovementCrouch))
				SwimComp.VerticalScale -= SwimmingSettings::Speed.VerticalInputScale;
			
			FVector MoveDirection = ControlRotation.Value.RotateVector(Input) + (MoveComp.WorldUp * SwimComp.VerticalScale);
			MoveDirection = MoveDirection.GetClampedToMaxSize(1.f);

			// Add impulses
			FVector AccumulatedImpulse = MoveComp.ConsumeAccumulatedImpulse(); 
			if (!AccumulatedImpulse.IsNearlyZero())
			{
				// Consume impulses
				Velocity += AccumulatedImpulse;

				float Speed = Velocity.Size();
				if (Speed > SwimComp.DesiredSpeed)
				{
					SwimComp.DesiredSpeed = FMath::Min(SwimmingSettings::Speed.DesiredCruise, Speed);
					SwimComp.DesiredDecayCooldown = SwimmingSettings::Speed.DesiredDecayDelayAfterDash;
				}
			}

			SwimComp.bIsSwimmingForward = !Input.IsNearlyZero();

			float MoveDirectionVelocityDot = MoveDirection.DotProduct(Velocity.SafeNormal);
			if (SwimComp.DesiredLockCooldown <= 0.f && (MoveDirectionVelocityDot < -0.45f || MoveDirection.IsNearlyZero(0.2f)))
			{
				SwimComp.DesiredSpeed = FMath::Min(SwimmingSettings::Speed.DesiredFast, SwimComp.DesiredSpeed);
				SwimComp.DesiredDecayCooldown = 0.f;
			}

			if (SwimComp.DesiredDecayCooldown <= 0.f)
			{
				SwimComp.DesiredSpeed -= SwimmingSettings::Speed.DesiredDecaySpeed * DeltaTime;
				SwimComp.DesiredSpeed = FMath::Max(SwimComp.DesiredSpeed, SwimmingSettings::Speed.DesiredMin);
			}

			SwimComp.UpdateSwimmingSpeedState();

			FVector TargetVelocity = MoveDirection * SwimComp.DesiredSpeed;
			Velocity = FMath::VInterpTo(Velocity, TargetVelocity, DeltaTime, SwimmingSettings::Speed.InterpSpeedTowardsDesired);

			FrameMove.OverrideCollisionSolver(USwimmingCollisionSolver::StaticClass());
			FrameMove.ApplyVelocity(Velocity);
			FrameMove.OverrideStepDownHeight(0.f);
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);

			FVector FacingDirection = Owner.ActorForwardVector;
			if (!Velocity.ConstrainToPlane(MoveComp.WorldUp).IsNearlyZero(20.f))
			{ 
				FacingDirection = Velocity.GetSafeNormal();
			}
			MoveComp.SetTargetFacingDirection(FacingDirection, 6.f);
			FrameMove.ApplyTargetRotationDelta();

			// Audio: Stopped and started moving
			if (!MoveDirection.IsNearlyZero())
			{
				if (!bStartedSwimming)
				{
					bStartedSwimming = true;
					if (SwimComp.AudioData[Player].SubmergedStartedMoving != nullptr)
					{
						HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedStartedMoving);

						if (SwimComp.SwimmingSpeedState == ESwimmingSpeedState::Normal && SwimComp.AudioData[Player].SubmergedEnteredNormal != nullptr)
							HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedEnteredNormal);
						else if (SwimComp.SwimmingSpeedState == ESwimmingSpeedState::Fast && SwimComp.AudioData[Player].SubmergedEnteredFast != nullptr)
							HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedEnteredFast);
					}
				}
				else if (AudioSwimmingState != SwimComp.SwimmingSpeedState)
				{
					AudioSwimmingState = SwimComp.SwimmingSpeedState;
					
					if (AudioSwimmingState == ESwimmingSpeedState::Normal && SwimComp.AudioData[Player].SubmergedEnteredNormal != nullptr)
						HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedEnteredNormal);
					else if (AudioSwimmingState == ESwimmingSpeedState::Fast && SwimComp.AudioData[Player].SubmergedEnteredFast != nullptr)
						HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedEnteredFast);
				}
			}
			else if (bStartedSwimming)
			{
				bStartedSwimming = false;
				if (SwimComp.AudioData[Player].SubmergedStoppedMoving != nullptr)
					HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedStoppedMoving);
			}
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);

			SwimComp.bIsSwimmingForward = !ConsumedParams.ReplicatedInput.IsNearlyZero();

			SwimComp.VerticalScale = 0.f;
			if (ConsumedParams.DeltaTranslation.Z >= 400.f * DeltaTime)
				SwimComp.VerticalScale += SwimmingSettings::Speed.VerticalInputScale;
			if (ConsumedParams.DeltaTranslation.Z <= -400.f * DeltaTime)
				SwimComp.VerticalScale -= SwimmingSettings::Speed.VerticalInputScale;

			float Speed = ConsumedParams.Velocity.Size();
			SwimComp.DesiredSpeed = Speed;
			SwimComp.UpdateSwimmingSpeedState();
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString DebugText = "";
		
		float SpeedToDesired = SwimComp.DesiredSpeed - MoveComp.Velocity.Size();
		FString SpeedColour = "<Blue>";
		if (SpeedToDesired > 80.f)
			SpeedColour = "<Green>";
		else if (SpeedToDesired < 80.f)
			SpeedColour = "<Red>";

		DebugText += "Speed State: " + SwimComp.SwimmingSpeedState + "\n";
		DebugText += "Speed: " + SpeedColour + String::Conv_FloatToStringOneDecimal(MoveComp.Velocity.Size()) + "</>\n";
		DebugText += "Desired: " + String::Conv_FloatToStringOneDecimal(SwimComp.DesiredSpeed) + " / " + String::Conv_FloatToStringOneDecimal(SwimmingSettings::Speed.DesiredMax) + "\n";

		return DebugText;
	}
}

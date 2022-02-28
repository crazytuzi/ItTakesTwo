import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingBoostAirCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Boost);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 120;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingAirSettings AirSettings;
	FIceSkatingBoostSettings BoostSettings;

	bool bCanBoost = false;
	float Timer = 0.f;
	float OriginalHorizontalSpeed = 0.f;

	FVector BoostNormal;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (!bCanBoost)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementDash))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Timer > BoostSettings.AirBoostDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		ActivationParams.DisableTransformSynchronization();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BoostNormal = MoveComp.WorldUp;
		if (SkateComp.HasProjectedGround())
			BoostNormal = SkateComp.ProjectedGroundNormal;

		if (HasControl() && !SkateComp.IsInputPaused())
		{
			FVector Velocity = MoveComp.Velocity;
			float UpVelocity = Velocity.DotProduct(BoostNormal);

			Velocity = Velocity.ConstrainToPlane(BoostNormal);

			// Boost direction is either stick direction, or just player forward
			FVector Direction = GetAttributeVector(AttributeVectorNames::MovementDirection);
			if (Direction.IsNearlyZero())
				Direction = Player.ActorForwardVector;

			Direction = Math::ConstrainVectorToSlope(Direction, BoostNormal, MoveComp.WorldUp);
			Direction.Normalize();

			// If speed is less than the minimum-speed, hard-set it
			float Speed = Velocity.Size();
			if (Speed < BoostSettings.AirMinSpeed)
				Velocity = Direction * BoostSettings.AirMinSpeed;

			OriginalHorizontalSpeed = Velocity.Size();

			float BoostMultiplier = 1.f - Math::Saturate(Speed / SkateComp.MaxSpeed);

			// Add impulse
			Velocity += Direction * BoostMultiplier * BoostSettings.AirForwardImpulse;
			MoveComp.Velocity = Velocity;
		}

		bCanBoost = false;
		SkateComp.CallOnAirBoostEvent();

		Timer = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Avoid spamming skate landing if we're entering/exiting air movement fast
		if (MoveComp.BecameGrounded())
			MoveComp.SetAnimationToBeRequested(n"SkateLanding");

		FVector HoriVelocity;
		FVector VertVelocity;
		Math::DecomposeVector(VertVelocity, HoriVelocity, MoveComp.Velocity, BoostNormal);

		HoriVelocity = HoriVelocity.GetClampedToMaxSize(OriginalHorizontalSpeed);
		MoveComp.Velocity = HoriVelocity + VertVelocity;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsGrounded())
			bCanBoost = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_AirBoost");

		if (HasControl())
		{
			Timer += DeltaTime;
			FVector Velocity = MoveComp.Velocity;

			// Add horizontal drag to get back to original speed
			{
				FVector HoriVelocity;
				FVector VertVelocity;
				Math::DecomposeVector(VertVelocity, HoriVelocity, Velocity, BoostNormal);

				HoriVelocity = FMath::VInterpTo(HoriVelocity, HoriVelocity.GetSafeNormal() * OriginalHorizontalSpeed, BoostSettings.AirBoostFriction, DeltaTime);
				Velocity = HoriVelocity + VertVelocity;
			}

			// Fade in gravity near the end
			{
				float GravityScale = Math::GetPercentageBetweenClamped(BoostSettings.AirBoostGravityFadeStartTime, BoostSettings.AirBoostDuration, Timer);
				float Gravity = AirSettings.Gravity * GravityScale;

				Velocity -= MoveComp.WorldUp * Gravity * DeltaTime;
			}

			// Fade in air control
			{
				float TurnScale = Math::GetPercentageBetweenClamped(BoostSettings.AirBoostGravityFadeStartTime, BoostSettings.AirBoostDuration, Timer);
				TurnScale = 1.f;
				FVector Input = SkateComp.GetScaledPlayerInput_VelocityRelative();
				Velocity = SkateComp.Turn(Velocity, Input.Y * TurnScale * AirSettings.TurnSpeed * DeltaTime);
			}

			FrameMove.OverrideStepDownHeight(5.f);
			FrameMove.ApplyVelocity(Velocity);
			FrameMove.SetRotation(Math::MakeQuatFromX(Velocity));

			MoveCharacter(FrameMove, n"SkateAirBoost");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);

			MoveCharacter(FrameMove, n"SkateAirBoost");
		}
	}
}

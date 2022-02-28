import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UIceSkatingAirMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add( n"IceSkatingMovement");
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingAirSettings AirSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		SkateComp = UIceSkatingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

	    if (ShouldBeGrounded())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (MoveComp.BecameGrounded())
		{
			MoveComp.SetAnimationToBeRequested(n"SkateLanding");
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"IceSkating_Air");

		if (HasControl())
		{
			FVector Input = SkateComp.GetScaledPlayerInput_VelocityRelative();

			FVector Velocity = MoveComp.Velocity;
			Velocity += -FVector::UpVector * AirSettings.Gravity * DeltaTime;

			// Turn it!
			Velocity = SkateComp.Turn(Velocity, Input.Y * AirSettings.TurnSpeed * DeltaTime);

			// Braking
			if (Input.X < 0.f)
			{
				Velocity -= Velocity.ConstrainToPlane(MoveComp.WorldUp) * (-Input.X) * AirSettings.BrakeCoeff * DeltaTime;
			}

			// Brake if going above max speed
			Velocity = SkateComp.ApplyMaxSpeedFriction(Velocity, DeltaTime);

			// Terminal velocity!
			float VerticalSpeed = Velocity.DotProduct(MoveComp.WorldUp);
			if (VerticalSpeed < -AirSettings.MaxFallSpeed)
			{
				FVector VerticalVelocity = MoveComp.WorldUp * VerticalSpeed;
				FVector HorizontalVelocity = Velocity - VerticalVelocity;
				Velocity = HorizontalVelocity - MoveComp.WorldUp * AirSettings.MaxFallSpeed;
			}

			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);
		}

		FrameMove.OverrideStepUpHeight(0);
		FrameMove.OverrideStepDownHeight(0);

		// If we enter air movement while in the input pause grace timer,
		//	remain in air movement until the grace time is over. We don't
		//	want to become grounded and have our velocity redirected and stuff.
		if (SkateComp.InputPauseGraceTimer > 0.f)
		{
			FrameMove.OverrideGroundedState(EHazeGroundedState::Airborne);
		}

		MoveCharacter(FrameMove, n"SkateInAir");
		CrumbComp.LeaveMovementCrumb();
	}
}

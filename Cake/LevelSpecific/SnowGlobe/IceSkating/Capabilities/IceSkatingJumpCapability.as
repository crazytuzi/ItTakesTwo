import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;

class UIceSkatingJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Jump);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 130;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingJumpSettings JumpSettings;
	FIceSkatingAirSettings AirSettings;

	float GroundedTimer = 0.f;

	const float HoldGravityScale = 0.15f;
	const float MaxHoldTime = 0.175f;

	float HoldTime = 0.f;

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
		if (!HasControl())
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.IsAbleToJump())
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
	        return EHazeNetworkActivation::DontActivate;

	    if (GroundedTimer <= 0.f)
	       return EHazeNetworkActivation::DontActivate;

	    if (!WasActionStarted(ActionNames::MovementJump))
	        return EHazeNetworkActivation::DontActivate;

	    if (SkateComp.IsInputPaused())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!SkateComp.bIsIceSkating)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	    if (!IsActioning(ActionNames::MovementJump))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (HoldTime > MaxHoldTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		GroundedTimer = 0.f;

		if (HasControl())
		{
			FVector Normal = SkateComp.GroundNormal;
			FVector PlayerForward = Player.ActorForwardVector;
			FVector SideNormal = Normal.ConstrainToPlane(PlayerForward);
			SideNormal.Normalize();

			FVector Velocity = MoveComp.Velocity;
			Velocity += MoveComp.WorldUp * JumpSettings.GroundImpulse;

			MoveComp.Velocity = Velocity;
		}

		HoldTime = 0.f;
		MoveComp.SetAnimationToBeRequested(n"SkateJump");

		SkateComp.StartJumpCooldown();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		if (MoveComp.IsGrounded())
			MoveComp.SetAnimationToBeRequested(n"SkateLanding");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		GroundedTimer -= DeltaTime;

		if (MoveComp.IsGrounded())
			GroundedTimer = JumpSettings.GracePeriod;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = SkateComp.MakeFrameMovement(n"SkateJump");
		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.OverrideStepDownHeight(0.f);

		if (HasControl())
		{
			HoldTime += DeltaTime;
			FVector Input = SkateComp.GetScaledPlayerInput_VelocityRelative();

			bool bHoldingJump = IsActioning(ActionNames::MovementJump);

			FVector Velocity = MoveComp.Velocity;
			Velocity += MoveComp.WorldUp * (-AirSettings.Gravity) * HoldGravityScale * DeltaTime;

			// Turn it!
			Velocity = SkateComp.Turn(Velocity, Input.Y * AirSettings.TurnSpeed * DeltaTime);

			// Braking
			if (Input.X < 0.f)
			{
				Velocity -= Velocity.ConstrainToPlane(MoveComp.WorldUp) * (-Input.X) * AirSettings.BrakeCoeff * DeltaTime;
			}

			FrameMove.ApplyVelocity(Velocity);
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);
		}

		MoveCharacter(FrameMove, n"SkateInAir");
		CrumbComp.LeaveMovementCrumb();
	}
}

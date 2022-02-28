import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Helpers.MovementJumpHybridData;

class UIceSkatingDoubleJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(IceSkatingTags::IceSkating);
	default CapabilityTags.Add(IceSkatingTags::Jump);
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityDebugCategory = n"IceSkating";
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 135;

	AHazePlayerCharacter Player;
	UIceSkatingComponent SkateComp;

	FIceSkatingJumpSettings JumpSettings;
	FIceSkatingAirSettings AirSettings;

	bool bCanDoubleJump = true;

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

	    if (!bCanDoubleJump)
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.bIsIceSkating)
	        return EHazeNetworkActivation::DontActivate;

		if (!SkateComp.IsAbleToJump())
	        return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
	        return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
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
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		MoveComp.SetAnimationToBeRequested(n"SkateDoubleJump");
		SkateComp.StartJumpCooldown();

		// We remove a _fraction_ of the vertical velocity 
		// Removing the velocity completely makes jumps _gigantic_ when in mountain
		// Not removing at all makes it feel terrible everywhere
		// So this is an inbetweeny solution
		MoveComp.Velocity -= MoveComp.Velocity.ConstrainToDirection(MoveComp.WorldUp) * JumpSettings.AirVelocityRemoval;
		MoveComp.Velocity += MoveComp.WorldUp * JumpSettings.AirImpulse;

		bCanDoubleJump = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (MoveComp.IsGrounded())
			bCanDoubleJump = true;
	}
}
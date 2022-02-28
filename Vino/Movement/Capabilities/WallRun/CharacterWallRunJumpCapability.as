import Vino.Movement.Components.MovementComponent;

import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureWallRun;
import Vino.Movement.MovementSystemTags;

class UCharacterWallRunJumpCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallRun);	
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 3;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	bool bMovementBlocked = false;
	float BlockTime = .8f;
	float BlockTimer = 99.f;

    AHazePlayerCharacter Player;
	ULocomotionFeatureWallRun Feature;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"WallRunJumpRight") || IsActioning(n"WallRunJumpLeft"))
            return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        FVector JumpDir = FVector::ZeroVector;
		Feature = ULocomotionFeatureWallRun::Get(Player);
        if (IsActioning(n"WallRunJumpRight"))
        {
            JumpDir = Player.ActorRightVector;
            Player.SetCapabilityActionState(n"WallRunJumpRight", EHazeActionState::Inactive);
			Player.PlaySlotAnimation(Animation = Feature.LeftWallRunJump.Sequence, bLoop = false, BlendTime = 0.1f);
        }
        else
        {
            JumpDir = Player.ActorRightVector * -1.f;
            Player.SetCapabilityActionState(n"WallRunJumpLeft", EHazeActionState::Inactive);
			Player.PlaySlotAnimation(Animation = Feature.RightWallRunJump.Sequence, bLoop = false, BlendTime = 0.1f);
		}

		BlockTimer = 0.f;

		if (!bMovementBlocked)
		{
			// Print("whathwjaendwajdn", 5.f);
			Player.BlockCapabilities(CapabilityTags::MovementInput, this);
			bMovementBlocked = true;

		}
		else
		{
			// Print("nu är något jävligt kaos", 5.f);
		}


        MoveComp.SetVelocity(FVector::ZeroVector);
        FVector Impulse = (Player.ActorForwardVector * 1420.f) + (JumpDir * 1000.f) + (MoveComp.WorldUp * 1225.f);
        // FVector Impulse = FVector(0.f, 0.f, 15000.f);
        // Print("" + Impulse, 5.f);
        Player.AddImpulse(Impulse);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		BlockTimer += DeltaTime;
		if (BlockTimer >= BlockTime)
		{
			UnblockMovementInput();
		}
	}

	void UnblockMovementInput()
	{
		if (bMovementBlocked)
		{
			bMovementBlocked = false;
			Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		}
	}
}

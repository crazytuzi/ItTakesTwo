import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.DoublePull.DoublePullComponent;
import Vino.Audio.Capabilities.AudioTags;

class UPlayerDoublePullSplineCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"DoublePull");
	default CapabilityTags.Add(AudioTags::FallingAudioBlocker);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default CapabilityDebugCategory = n"Gameplay";

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		auto DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		if (DoublePull == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		auto DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		if (DoublePull == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		auto DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));

		// Take the input from the player
		FVector MovementDirection;
		if (HasControl())
		{
			MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			DoublePull.SetPlayerInputDirection(Player, MovementDirection);
		}
		else
		{
			// Network for animation purposes
			MovementDirection = DoublePull.GetRemoteAnimationInput(Player);
		}

		// Apply animation parameters to player
		DoublePull.SetAnimationParams(Player, MovementDirection);

		// Move the player to follow the box
		USceneComponent TargetPosition = DoublePull.GetTriggerUsedByPlayer(Player);

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"DoublePullSpline");
			Movement.ApplyDelta(TargetPosition.WorldLocation - Player.ActorLocation);
			Movement.SetRotation(TargetPosition.ComponentQuat);
			MoveCharacter(Movement, n"DoublePull");
		}


		// Draw debug info for direction we're pulling for now
		//System::DrawDebugLine(Player.ActorLocation, Player.ActorLocation + MovementDirection * 300.f, FLinearColor::Red, 0.f, 10.f);
	}
};
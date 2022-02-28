import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBirdFlyingComponent;

class UClockworkPlayerBirdInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(CapabilityTags::Input);

	default CapabilityDebugCategory = n"ClockworkInputCapability";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 101;

	AHazePlayerCharacter Player;
	AClockworkBird Bird;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
        if (MountedBird == nullptr)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		auto MountedBird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
		if (MountedBird == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!MountedBird.PlayerIsUsingBird(Player))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Bird = Cast<AClockworkBird>(GetAttributeObject(ClockworkBirdTags::ClockworkBird));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Bird != nullptr)
		{
			Bird.PlayerInput = FVector::ZeroVector;
			Bird.SetNewLerpedInput(FVector::ZeroVector);

			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdJumping, EHazeActionState::Inactive);
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdFlap, EHazeActionState::Inactive);
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdLand, EHazeActionState::Inactive);
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdQuitRiding, EHazeActionState::Inactive);

			Bird = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Bird.PlayerInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		Bird.PlayerRawInput = GetAttributeVector(AttributeVectorNames::MovementRaw);
		
		FVector LeftStickRaw = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		Bird.SetNewLerpedInput(LeftStickRaw);

		// Update Jump input
		if(IsActioning(ActionNames::MovementJump))
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdJumping, EHazeActionState::Active);
		else
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdJumping, EHazeActionState::Inactive);

		if(IsActioning(ActionNames::MovementDash))
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdFlap, EHazeActionState::Active);
		else
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdFlap, EHazeActionState::Inactive);

		if (IsActioning(ActionNames::MovementCrouch))
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdLand, EHazeActionState::Active); 
		else 
			Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdLand, EHazeActionState::Inactive);

		if (WasActionStarted(ActionNames::Cancel))
		{
			if (Bird.PlayerCanQuitRiding())
			{
				Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
				Bird.SetCapabilityActionState(ClockworkBirdTags::ClockworkBirdQuitRiding, EHazeActionState::Active);
			}
		}
	}
}
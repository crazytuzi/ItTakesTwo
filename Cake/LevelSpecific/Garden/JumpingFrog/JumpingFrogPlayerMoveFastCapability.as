import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogPlayerRideComponent;

class UJumpingFrogPlayerMoveFastCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(JumpingFrogTags::Jump);
	default CapabilityTags.Add(JumpingFrogTags::QuickJump);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 40;

	const float FastDurationEachPress = 0.3f;
	float FastDurationTimeLeft = 0;

	AHazePlayerCharacter Player;
	UJumpingFrogPlayerRideComponent RideComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		RideComponent = UJumpingFrogPlayerRideComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!RideComponent.Frog.FrogMoveComp.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if (RideComponent.Frog.bJumping)
			return EHazeNetworkActivation::DontActivate;

		if(RideComponent.Frog.MovementSettings.TriggerFastMoveInputType == EJumpingFrogMoveInputType::Mash)
		{
			if(!WasActionStarted(ActionNames::MovementDash))
				return EHazeNetworkActivation::DontActivate;
		}
		else if(RideComponent.Frog.MovementSettings.TriggerFastMoveInputType == EJumpingFrogMoveInputType::Hold)
		{
			if(!IsActioning(ActionNames::MovementDash))
				return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;
		
		if (RideComponent.Frog.bJumping)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!RideComponent.Frog.FrogMoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(RideComponent.Frog.MovementSettings.TriggerFastMoveInputType == EJumpingFrogMoveInputType::Mash)
		{
			if(FastDurationTimeLeft <= 0)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else if(RideComponent.Frog.MovementSettings.TriggerFastMoveInputType == EJumpingFrogMoveInputType::Hold)
		{
			if(!IsActioning(ActionNames::MovementDash))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FastDurationTimeLeft = FastDurationEachPress;
		RideComponent.Frog.FrogMoveComp.bIsMovingFast = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FastDurationTimeLeft = 0;
		if(RideComponent != nullptr && RideComponent.Frog != nullptr)
			RideComponent.Frog.FrogMoveComp.bIsMovingFast = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FastDurationTimeLeft -= DeltaTime;
		if(WasActionStarted(ActionNames::MovementDash))
			FastDurationTimeLeft = FastDurationEachPress;

	}
}

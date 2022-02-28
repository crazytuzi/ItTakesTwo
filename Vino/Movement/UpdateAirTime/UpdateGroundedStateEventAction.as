import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class UUpdateGroundedStateEventAction : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 4;

	default CapabilityDebugCategory = CapabilityTags::Movement;	

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (MoveComp == nullptr)
        	return EHazeNetworkActivation::DontActivate;

		if(MoveComp.IsDisabled())
			return EHazeNetworkActivation::DontActivate;
		
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MoveComp.IsDisabled())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.IsGrounded())
		{
			Owner.SetCapabilityActionState(MovementActivationEvents::Grounded, EHazeActionState::Active);
			ConsumeAction(MovementActivationEvents::Airbourne);
		}
		else
		{
			Owner.SetCapabilityActionState(MovementActivationEvents::Airbourne, EHazeActionState::Active);
			ConsumeAction(MovementActivationEvents::Grounded);
		}
	}
}

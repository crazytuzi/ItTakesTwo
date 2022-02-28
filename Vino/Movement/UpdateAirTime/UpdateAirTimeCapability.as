import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class UUpdateAirTimeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 3;

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
		
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MoveComp.IsAirborne())
		{
			MoveComp.UpdateAirTime(DeltaTime);
			MoveComp.ResetGroundTime();
		}
		else
		{
			MoveComp.UpdateGroundTime(DeltaTime);
			MoveComp.OnGroundedReset();
		}
	}
}

import Cake.LevelSpecific.PlayRoom.Circus.StrongMan;
/*
    This is a generic example capability showing what functions you can override
*/

namespace ExampleAttribueNamespace
{
	const FName ExampleAttributeName = n"HelloImAExample";
}

namespace ExampleActionsNamespace
{
	const FName ExampleActionName = n"HelloImDoingTheActionExample";
}

class UControlStrongmanCapability : UHazeCapability
{
    // Tags defines what "categories" the capbility belongs to, when this tag is blocked then the capability will be blocked
	default CapabilityTags.Add(CapabilityTags::Input);

	// Capabilites are ticked in order of a tick group, 	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	// Internal tick order for the TickGroup, Lowest ticks first.
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AStrongman LinkedStrongman;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

    /* Checks if the Capability should be active and ticking
    * Will be called every tick when the capability is not active. will tick the same frame as ActiveLocal or ActivateFromControl is called
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AStrongman Strongman = Cast<AStrongman>(GetAttributeObject(n"Strongman"));

		if(Strongman != nullptr)
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
		
	}

    /* Checks if the Capability should deactivate and stop ticking
    *  Will be called every tick when the capability is activate and before it ticks. The Capability will not tick the same frame as DeactivateLocal or DeactivateFromControl is returned
	*/
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(CheckIfShouldDeactive())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

    bool CheckIfShouldDeactive() const
    {
		
        if (WasActionStarted(ActionNames::Cancel))
		{
			return true;
		}

		else
		{
			return false;
		}
    }

    /* Called when the capability is activated, If called when activated by ActivateFromControl it is garanteed to run on the other side */
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AStrongman Strongman = Cast<AStrongman>(GetAttributeObject(n"Strongman"));
		ConsumeAttribute(n"Strongman", Strongman);
		LinkedStrongman = Strongman;

		Owner.BlockCapabilities(CapabilityTags::Movement, this);
		Owner.BlockCapabilities(CapabilityTags::GameplayAction, this);
	}

    /* Called when the capability is deactivated, If called when deactivated by DeactivateFromControl it is garanteed to run on the other side */
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		LinkedStrongman.ResetToDefaultPosition();
		LinkedStrongman = nullptr;

		Owner.UnblockCapabilities(CapabilityTags::Movement, this);
		Owner.UnblockCapabilities(CapabilityTags::GameplayAction, this);
	}
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		float Input = MoveDirection.DotProduct(LinkedStrongman.ActorRightVector.GetSafeNormal());

		if (Input > 0.2f)
		{
			LinkedStrongman.LiftRightArm();
			LinkedStrongman.LowerLeftArm();
		}

		else if (Input < -0.2f)
		{
			LinkedStrongman.LiftLeftArm();
			LinkedStrongman.LowerRightArm();
		}
	}
};
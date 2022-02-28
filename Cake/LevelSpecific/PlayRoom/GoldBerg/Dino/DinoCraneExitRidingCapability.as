import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;

class UDinoCraneExitRidingCapability : UHazeCapability
{
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
    default CapabilityTags.Add(CapabilityTags::CancelAction);

	UDinoCraneRidingComponent RideComp;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		RideComp = UDinoCraneRidingComponent::GetOrCreate(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (RideComp.DinoCrane == nullptr)
            return EHazeNetworkActivation::DontActivate;
		if (RideComp.DinoCrane.GrabbedPlatform != nullptr)
            return EHazeNetworkActivation::DontActivate;
        if (!WasActionStarted(ActionNames::Cancel))
            return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams& Params)
    {
		if (Player.HasControl())
			RideComp.DinoCrane.ReleaseRidingPlayer();
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
    }
};
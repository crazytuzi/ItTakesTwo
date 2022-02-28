import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCranePlatformInteraction;

class UDinoCraneReleasePlatformCapability : UHazeCapability
{
	default TickGroupOrder = 200;
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
    default CapabilityTags.Add(CapabilityTags::CancelAction);

	UDinoCraneRidingComponent RideComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		RideComp = UDinoCraneRidingComponent::GetOrCreate(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (RideComp.DinoCrane == nullptr)
            return EHazeNetworkActivation::DontActivate;
		if (RideComp.DinoCrane.GrabbedPlatform == nullptr)
            return EHazeNetworkActivation::DontActivate;
        if (!WasActionStarted(ActionNames::Cancel))
            return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams& Params)
    {
		auto Platform = Cast<ADinoCranePlatformInteraction>(RideComp.DinoCrane.GrabbedPlatform);
		Platform.ReleasePlatform();
    }
};
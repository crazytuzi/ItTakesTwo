import Vino.Pickups.PickupTags;
import Vino.Pickups.Putdown.PickupPutdownLocation;

class UPlayerPlaceOnPointCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 40;
	// TODO: Start animation with timer etc, trigger when the animation is complete

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(PickupTags::PutdownOnPointCapability))
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(GetAttributeObject(PickupTags::PutdownTargetObject) == nullptr)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UObject TargetObject = GetAttributeObject(PickupTags::PutdownTargetObject);
		ActivationParams.AddObject(PickupTags::PutdownTargetObject, TargetObject);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UObject TargetObject = nullptr;

		// Just in case
		ConsumeAttribute(PickupTags::PutdownTargetObject, TargetObject);

		TargetObject = ActivationParams.GetObject(PickupTags::PutdownTargetObject);
		APickupPutdownLocation PutdownLocation = Cast<APickupPutdownLocation>(TargetObject);
		devEnsure(PutdownLocation != nullptr, "PutdownLocation is null. Something is seriously wrong. buu");
		PutdownLocation.HandlePlayerPlacedObject(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}


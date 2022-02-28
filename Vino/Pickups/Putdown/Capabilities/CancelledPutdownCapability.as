import Vino.Pickups.Putdown.Capabilities.PutdownCapabilityBase;

class UCancelledPutdownCapability : UPutdownCapabilityBase
{
	default CapabilityTags.Add(PickupTags::PutdownCancelledCapability);

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ActivePutdownParams.PutdownType != EPutdownType::Cancelled)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// Hack putdown
		PickupComponent.PutDown();
		PutdownActor.OnPlacedOnFloor(PlayerOwner, PutdownActor);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Disable after one tick, no need to stick around
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}
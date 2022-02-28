
class UCancelMoveToCapability : UHazePathFindingCapabilityBase
{
    default CapabilityTags.Add(CapabilityTags::Movement);
    default CapabilityTags.Add(CapabilityTags::CancelAction);

	default CapabilityDebugCategory = CapabilityTags::Movement;

    default bUsedForMovement = false;

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(!WasActionStarted(ActionNames::Cancel))
            return EHazeNetworkActivation::DontActivate;

		if(!IsGoToCancelable())
			return EHazeNetworkActivation::DontActivate;

		if(!IsValidToActivate())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        if (WasActionStarted(ActionNames::Cancel))
        {
            NetCancelGoTo();
        }
    }

    UFUNCTION(NetFunction)
    void NetCancelGoTo()
    {
        Owner.AbortCurrentMoveTo();
    }
};
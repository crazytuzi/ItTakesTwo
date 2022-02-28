import Vino.Pickups.Throw.Capabilities.PickupAimCapability;

class UPickupConstrainedAimCapability : UPickupAimCapability
{
	default CapabilityTags.Add(PickupTags::PickupConstrainedAimCapability);

	// Tick before normal aim does
	default TickGroupOrder = 99;

	bool bCancelActionThrows = false;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(PickupComponent.CurrentPickup == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PickupComponent.IsHoldingThrowableObject())
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(PickupTags::PutdownCapability))
			return EHazeNetworkActivation::DontActivate;

		if(!MovementComponent.IsGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::Dash))
			return EHazeNetworkActivation::DontActivate;

		if(PlayerOwner.IsAnyCapabilityActive(MovementSystemTags::GroundPound))
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(PickupTags::StartPickupConstrainedAim))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Super::OnActivated(ActivationParams);
		bCancelActionThrows = IsActioning(n"CancelActionThrows");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Don't let regular aiming take over
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::WeaponAim);
		Super::TickActive(DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(PlayerOwner.IsAnyCapabilityActive(PickupTags::PickupCapability))
			return EHazeNetworkDeactivation::DontDeactivate;

		if(PickupComponent.CurrentPickup == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bObjectWasPutdown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!PickupComponent.CurrentPickup.bHoldToChargeThrow)
		{
			if(WasActionStarted(ActionNames::WeaponFire))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;

			if(bCancelActionThrows && WasActionStarted((ActionNames::Cancel)))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if(!IsActioning(ActionNames::WeaponFire) && bIsChargingThrow)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(PlayerOwner.IsAnyCapabilityActive(PickupTags::PutdownCapability))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& SyncParams)
	{
		// Don't throw if aiming was cancelled
		if(!bCancelActionThrows && WasActionStarted(ActionNames::Cancel))
			return;

		if(bObjectWasPutdown)
			return;

		SyncParams.AddActionState(n"CastThatShit!");
		SyncParams.AddVector(n"AimTarget", AimTarget);
		SyncParams.AddValue(n"AimTrajectoryPeak", AimTrajectoryPeak);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{
		Super::OnDeactivated(DeactivationParams);
		bCancelActionThrows = false;
	}
}
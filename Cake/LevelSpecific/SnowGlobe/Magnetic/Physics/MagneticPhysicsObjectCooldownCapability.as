// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticMoveableComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;

// class MagneticPhysicsObjectCooldownCapability : UHazeCapability
// {
// 	// Internal tick order for the TickGroup, Lowest ticks first.
// 	default TickGroupOrder = 1;
// 	default TickGroup = ECapabilityTickGroups::BeforeMovement;
// 	float TimeSinceActivated = 0;
// 	UMagneticComponent MagnetComponent;
	
// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		TimeSinceActivated += DeltaTime;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		MagnetComponent = UMagneticComponent::Get(Owner);
// 		ConsumeAction(FMagneticTags::MagneticCooldown);
// 		Owner.BlockCapabilities(FMagneticTags::MagneticCapabilityTag, this);
// 		MagnetComponent.bIsDisabled = true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		MagnetComponent.bIsDisabled = false;
// 		Owner.UnblockCapabilities(FMagneticTags::MagneticCapabilityTag, this);
// 		TimeSinceActivated = 0;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if(IsActioning(FMagneticTags::MagneticCooldown))
// 		{
// 			return EHazeNetworkActivation::ActivateFromControl;
// 		}

// 		else
// 		{
// 			return EHazeNetworkActivation::DontActivate;
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (TimeSinceActivated > 3)
// 		{
// 			return EHazeNetworkDeactivation::DeactivateFromControl;
// 		}

// 		else
// 		{
// 			return EHazeNetworkDeactivation::DontDeactivate;
// 		}
// 	}
// }
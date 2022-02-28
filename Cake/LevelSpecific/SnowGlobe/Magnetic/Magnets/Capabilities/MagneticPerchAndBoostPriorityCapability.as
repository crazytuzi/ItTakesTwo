import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;

class UMagneticPerchAndBoostPriorityCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::Magnetic);
	default CapabilityTags.Add(FMagneticTags::MagneticPerchAndBoostPriorityCapability);

	// Make sure capability ticks before magnet querying
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 80;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerCharacter;
	UMagneticPerchAndBoostComponent SuperMagnetComponent;

	float PriorityDuration;
	float OriginalSelectableDistance;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"SuperMagnetComponent") == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Consume attributes
		UObject SuperMagnetObject;
		ConsumeAttribute(FMagneticTags::SuperMagnetComponent, SuperMagnetObject);
		SuperMagnetComponent = Cast<UMagneticPerchAndBoostComponent>(SuperMagnetObject);

		UObject PlayerObject;
		ConsumeAttribute(n"PlayerCharacter", PlayerObject);
		PlayerCharacter = Cast<AHazePlayerCharacter>(PlayerObject);

		ConsumeAttribute(FMagneticTags::SuperMagnetPriorityDuration, PriorityDuration);

		// Prioritize magnet and increase activation distance in case player is perch-jumping away from it
		PlayerCharacter.SetPreActivatePoint(SuperMagnetComponent, this);
		UMagneticPlayerComponent::Get(PlayerCharacter).PrioritizedMagnet = SuperMagnetComponent;
		OriginalSelectableDistance = SuperMagnetComponent.GetDistance(EHazeActivationPointDistanceType::Selectable);
		SuperMagnetComponent.InitializeDistance(EHazeActivationPointDistanceType::Selectable, OriginalSelectableDistance * 2.f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ActiveDuration >= PriorityDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Clear prioritization and restore activation distance
		PlayerCharacter.RemovePreActivatePoint(this);
		UMagneticPlayerComponent::Get(PlayerCharacter).PrioritizedMagnet = nullptr;
		SuperMagnetComponent.InitializeDistance(EHazeActivationPointDistanceType::Selectable, OriginalSelectableDistance);

		// Cleanup
		PlayerCharacter = nullptr;
		SuperMagnetComponent = nullptr;
		PriorityDuration = 0.f;

		// Remove capability
		Owner.RemoveCapability(UMagneticPerchAndBoostComponent::StaticClass());
	}
}
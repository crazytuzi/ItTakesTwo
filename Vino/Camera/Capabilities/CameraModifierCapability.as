import Vino.Camera.Capabilities.CameraTags;

// While this capability is active camera shakes, anims and post processing modifiers will be applied
class UCameraModifierCapability : UHazeCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::Modifiers);

    default CapabilityDebugCategory = CameraTags::Camera;
	default TickGroup = ECapabilityTickGroups::PostWork;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Always active unless blocked
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		if (!IsBlocked())
			EnableModifiers();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		EnableModifiers();
	}

	void EnableModifiers()
	{
		UHazeActiveCameraUserComponent User = UHazeActiveCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.Enable();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UHazeActiveCameraUserComponent User = UHazeActiveCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.Disable();
	}
}
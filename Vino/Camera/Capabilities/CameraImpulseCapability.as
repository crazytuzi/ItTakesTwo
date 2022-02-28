import Vino.Camera.Capabilities.CameraTags;

// While this capability is active camera impulses will be applied. If blocked, any ongoing impulses will blend out rapidly and no new ones will have an effect.
class UCameraImpulseCapability : UHazeCapability
{
	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(CameraTags::Impulses);

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
			AllowImpulses();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AllowImpulses();
	}

	void AllowImpulses()
	{
		UHazeActiveCameraUserComponent User = UHazeActiveCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.AllowCameraImpulses();
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UHazeActiveCameraUserComponent User = UHazeActiveCameraUserComponent::Get(Owner);
		UHazeCameraModifierManager Modifiers = (User != nullptr) ? User.GetModifier() : nullptr;
		if (Modifiers != nullptr)
			Modifiers.DisallowCameraImpulses();
	}
}
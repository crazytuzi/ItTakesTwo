import Peanuts.Animation.Components.AnimationLookAtComponent;

class UFullscreenDisableAnimLookAtCapability: UHazeCapability
{
	UAnimationLookAtComponent LookAtComp;

	default CapabilityTags.Add(n"AnimationLookAt");

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		LookAtComp = UAnimationLookAtComponent::Get(Owner);
		ensure(LookAtComp != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SceneView::IsFullScreen())
			return EHazeNetworkActivation::ActivateLocal;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SceneView::IsFullScreen())
			return EHazeNetworkDeactivation::DontDeactivate;
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		LookAtComp.DisableCameraBasedLookAt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		LookAtComp.EnableCameraBasedLookAt(this);
	}

}
import Vino.Animations.ThreeShotAnimation;

class UCancelThreeShotCapability : UHazeCapability
{
    default CapabilityTags.Add(n"CancelAction");
    default CapabilityTags.Add(n"Animation");

	UThreeShotAnimationComponent ThreeShotComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        ThreeShotComponent = UThreeShotAnimationComponent::GetOrCreate(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
    {
        if (ThreeShotComponent.CurrentAnimation == nullptr)
            return EHazeNetworkActivation::DontActivate;
        if (!WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkActivation::DontActivate;
        if (!ThreeShotComponent.HasCancelableThreeShots())
            return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
    {
		return EHazeNetworkDeactivation::DeactivateLocal;
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams Params)
    {
		ThreeShotComponent.NetCancelThreeShots(ThreeShotComponent.CurrentAnimation.AnimationId);
    }
};
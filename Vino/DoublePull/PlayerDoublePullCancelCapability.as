import Vino.DoublePull.DoublePullComponent;
import Vino.DoublePull.LocomotionFeatureDoublePull;

class UPlayerDoublePullCancelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DoublePull");
	default CapabilityTags.Add(n"CancelAction");
	default CapabilityDebugCategory = n"Gameplay";

	// Button to check for cancel
	UPROPERTY()
	FName CancelAction = ActionNames::Cancel;

	// If set, double pull cancels when button is released rather than pressed
	UPROPERTY()
	bool bCancelOnRelease = false;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		auto DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		if (DoublePull == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (bCancelOnRelease)
		{
			if (!IsActioning(CancelAction))
				return EHazeNetworkActivation::ActivateLocal;
		}
		else
		{
			if (WasActionStarted(CancelAction))
				return EHazeNetworkActivation::ActivateLocal;
		}

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	} 

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	 
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
		Player.ConsumeButtonInputsRelatedTo(CancelAction);

		auto DoublePull = Cast<UDoublePullComponent>(GetAttributeObject(n"DoublePull"));
		DoublePull.CancelFromPlayer(Player);
	}
};
import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

UCLASS(Deprecated)
class UMusicalHoverThrowCymbalCapability : UHazeCapability
{
	UMusicalFlyingComponent FlyingComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FlyingComp = UMusicalFlyingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(FlyingComp.CurrentState != EMusicalFlyingState::Hovering)
		{
			return EHazeNetworkActivation::DontActivate;
		}

		if(!WasActionStarted(ActionNames::WeaponFire))
		{
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetCapabilityActionState(n"ForceThrowCymbal", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}

import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifier;

class UMiniatureAmplifierShootCapability : UHazeCapability
{
	UPlayerPickupComponent PickupComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PickupComp = UPlayerPickupComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStarted(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

		if(!PickupComp.IsHoldingObject())
			return EHazeNetworkActivation::DontActivate;

		if(!PickupComp.CurrentPickup.IsA(AMiniatureAmplifier::StaticClass()))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AMiniatureAmplifier Amplifier = Cast<AMiniatureAmplifier>(PickupComp.CurrentPickup);
		Amplifier.ShootImpulse();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}
}

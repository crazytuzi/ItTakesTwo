import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Movement.Components.MovementComponent;

class USapWeaponHoldFireCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Weapon);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
	    if (!IsActioning(ActionNames::WeaponFire))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
	    if (!IsActioning(ActionNames::WeaponFire))
	        return EHazeNetworkDeactivation::DeactivateUsingCrumb;

        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		// This is only for syncing shooting hold LMAO
		Wielder.bAnimIsShooting = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Wielder.bAnimIsShooting = false;
	}
}
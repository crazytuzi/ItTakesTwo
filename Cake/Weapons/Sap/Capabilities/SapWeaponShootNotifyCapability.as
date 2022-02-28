import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Movement.Components.MovementComponent;

class USapWeaponShootNotifyCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Weapon);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;
	UHazeMovementComponent MoveComp;

	float Cooldown = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (!Wielder.bIsAiming)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IsActioning(ActionNames::WeaponFire))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
	    	return EHazeNetworkDeactivation::DeactivateFromControl;

	    if (!Wielder.bIsAiming)
	        return EHazeNetworkDeactivation::DeactivateFromControl;

	    if (!IsActioning(ActionNames::WeaponFire))
	        return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Wielder.Weapon.BP_StartFiring();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Wielder.Weapon.BP_StopFiring();
	}
}
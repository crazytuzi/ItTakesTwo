import Cake.Weapons.Sap.SapWeaponWielderComponent;

class USapWeaponPressureDecreaseCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::PressureRegen);

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
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

		bool bIsShooting = Wielder.bIsAiming && IsActioning(ActionNames::WeaponFire);
		if (!bIsShooting)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		bool bIsShooting = Wielder.bIsAiming && IsActioning(ActionNames::WeaponFire);
		if (!bIsShooting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Player.BlockCapabilities(SapWeaponTags::PressureRegen, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Player.UnblockCapabilities(SapWeaponTags::PressureRegen, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Wielder.RemovePressure(Sap::Pressure::DecreaseRate * DeltaTime);

		float PressurePercent = Wielder.Pressure / Sap::Pressure::Max;
		Wielder.Weapon.Container.SetFuelPercent(PressurePercent);
		Wielder.Weapon.CurrentFireRate = Wielder.GetCurrentFireRate();
	}
}
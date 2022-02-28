import Cake.Weapons.Sap.SapWeaponWielderComponent;

class USapWeaponPressureRegenCapability : UHazeCapability 
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

	float PauseTimer = 0.f;

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

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		PauseTimer = Sap::Pressure::RegenPause;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PauseTimer -= DeltaTime;
		if (PauseTimer <= 0.f)
			Wielder.AddPressure(Sap::Pressure::RegenRate * DeltaTime);

		float PressurePercent = Wielder.Pressure / Sap::Pressure::Max;
		Wielder.Weapon.Container.SetFuelPercent(PressurePercent);
		Wielder.Weapon.CurrentFireRate = Wielder.GetCurrentFireRate();
	}
}
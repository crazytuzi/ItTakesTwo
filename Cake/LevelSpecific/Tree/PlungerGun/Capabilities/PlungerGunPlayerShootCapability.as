import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunPlayerComponent;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager;

class UPlungerGunPlayerShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlungerGunPlayerComponent GunComp;

	float ChargeTime = 0.f;
	float NextShootTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GunComp = UPlungerGunPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GunComp.Gun == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkActivation::DontActivate;

		if (Time::GameTimeSeconds < NextShootTime)
			return EHazeNetworkActivation::DontActivate;

		auto Manager = PlungerGunManager;
		if (Manager.State != EPlungerGunGameState::Idle && Manager.State != EPlungerGunGameState::Active)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChargeTime = 0.f;
		GunComp.Gun.BP_StartCharging();
		GunComp.Widget.OnPlungerGunStartCharging();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		float Charge = ChargeTime / PlungerGun::MaxChargeTime;

		if (HasControl())
		{
			float ForceFeedbackIntensity = FMath::Lerp(0.5f, 1.5f, Charge);
			Player.PlayForceFeedback(GunComp.ShootForceFeedback, false, true, n"PlungerShoot", ForceFeedbackIntensity);
			GunComp.Gun.Fire(Charge);
		}

		GunComp.Gun.ChargeRoot.RelativeLocation = FVector::ZeroVector;
		GunComp.Widget.OnPlungerGunFire();
		GunComp.Widget.ChargePercent = 0.f;
		NextShootTime = Time::GameTimeSeconds + PlungerGun::ShootCooldown;

		if (PlungerGunGameIsActive())
			PlungerGunPlayShootBark(Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ChargeTime += DeltaTime;
		ChargeTime = FMath::Min(ChargeTime, PlungerGun::MaxChargeTime);

		float Charge = ChargeTime / PlungerGun::MaxChargeTime;

		GunComp.Gun.SetCharge(Charge);
		GunComp.Widget.ChargePercent = Charge;
	}
}
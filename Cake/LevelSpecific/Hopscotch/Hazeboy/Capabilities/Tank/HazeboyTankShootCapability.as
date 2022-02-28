import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class UHazeboyTankShootCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 105;

	AHazeboyTank Tank;
	float HoldTime = 0.f;
	float NextShootTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		float Time = Time::GameTimeSeconds;
		if (Time < NextShootTime)
			return EHazeNetworkActivation::DontActivate;

	    if (!IsActioning(ActionNames::WeaponFire))
	        return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkDeactivation::DeactivateFromControl;

	    if (!IsActioning(ActionNames::WeaponFire))
			return EHazeNetworkDeactivation::DeactivateFromControl;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Tank.Reticle.Show();
		HoldTime = 0.f;

		Tank.BP_OnStartCharging();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Tank.Reticle.Hide();

		if (HasControl())
			Tank.NetFire(Tank.MuzzleLocation, CalculateAimTargetLocation());

		float Time = Time::GameTimeSeconds;
		NextShootTime = Time + Hazeboy::ShootCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float ChargeTimeDelta = DeltaTime;

		HoldTime += ChargeTimeDelta;
		HoldTime = FMath::Min(HoldTime, Hazeboy::MaxHoldTime);

		FVector TargetLocation = CalculateAimTargetLocation();

		FTransform Transform;
		Transform.Location = TargetLocation;

		Tank.Reticle.SetActorTransform(Transform);
		Tank.BP_OnCharge(HoldTime / Hazeboy::MaxHoldTime);

		if (Tank.OwningPlayer != nullptr)
			Tank.OwningPlayer.SetFrameForceFeedback(HoldTime / Hazeboy::MaxHoldTime, HoldTime / Hazeboy::MaxHoldTime);
	}

	FVector CalculateAimTargetLocation()
	{
		float HoldTimeAlpha = HoldTime / Hazeboy::MaxHoldTime;
		return Tank.ActorLocation + Tank.AimForward * FMath::Lerp(Hazeboy::MinShootDistance, Hazeboy::MaxShootDistance, HoldTimeAlpha);
	}
}
import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Tree.BeetleRiding.TreeBeetleRidingComponent;

class UTreeBeetleRidingShootCapability : UHazeCapability 
{
	default CapabilityDebugCategory = n"BeetleRiding";

	default CapabilityTags.Add(n"BeetleRiding");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 80;

	AHazePlayerCharacter Player;
	UTreeBeetleRidingComponent BeetleRidingComponent;
	USapWeaponWielderComponent Wielder;

	float Cooldown = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BeetleRidingComponent = UTreeBeetleRidingComponent::Get(Player);
		Wielder = USapWeaponWielderComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder == nullptr)
	        return EHazeNetworkActivation::DontActivate;

		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (!Wielder.bIsAiming)
	        return EHazeNetworkActivation::DontActivate;

	    if (Cooldown > 0.f)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IsActioning(ActionNames::WeaponFire))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Wielder == nullptr)
			return;

		Cooldown -= DeltaTime;
		Wielder.bAnimIsShooting = IsActioning(ActionNames::WeaponFire);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{	
		Params.AddVector(n"Spread", FMath::VRand() * Sap::Shooting::SpreadRadius);

		Params.AddVector(n"RelativeLocation", Wielder.AimTarget.RelativeLocation);
		Params.AddObject(n"Component", Wielder.AimTarget.Component);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		FSapAttachTarget Target;
		if (HasControl())
		{
			Target = Wielder.AimTarget;
		}
		else
		{
			Target.RelativeLocation = Params.GetVector(n"RelativeLocation");
			Target.Component = Cast<USceneComponent>(Params.GetObject(n"Component"));
		}

		Target.WorldOffset = Params.GetVector(n"Spread");

		FVector Velocity = CalculateSapExitVelocity(Wielder.Weapon.MuzzleLocation, Target);

		// Add Beetle Velocity
	//	Velocity *= 1.5f;
	//	Velocity += BeetleRidingComponent.Beetle.BeetleVelocity;

		Wielder.Weapon.FireProjectile(Velocity, Target);

		float FireRate = Wielder.GetCurrentFireRate();
		Cooldown = 1.f / FireRate;

		// Play rumble bro
		float PressurePercent = Wielder.Pressure / Sap::Pressure::Max;
		float RumbleIntensity = FMath::Lerp(Sap::Shooting::ForceMinScale, 1.f, PressurePercent);
		Player.PlayForceFeedback(Wielder.ShootRumbleEffect, false, false, n"SapShoot", RumbleIntensity);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
	}
}
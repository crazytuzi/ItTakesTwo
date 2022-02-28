import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Movement.Components.MovementComponent;

class USapWeaponShootCapability : UHazeCapability 
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

	    if (Cooldown > 0.f)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IsActioning(ActionNames::WeaponFire))
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		Cooldown -= DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{	
		if (!Wielder.AimTarget.bIsAutoAim)
			Params.AddVector(n"Spread", FMath::VRand() * Sap::Shooting::SpreadRadius);
		else
			Params.AddVector(n"Spread", FVector::ZeroVector);

		Params.AddStruct(n"AimTarget", Wielder.AimTarget);
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
			Params.GetStruct(n"AimTarget", Target);
		}

		Target.WorldOffset = Params.GetVector(n"Spread");

		FVector Velocity = CalculateSapExitVelocity(Wielder.Weapon.MuzzleLocation, Target);
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
import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;

class UFlyingMachineImpactDamageCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 95;

	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;

	// Settings
	FFlyingMachineSettings Settings;

	// Last collision to be procssed
	FHitResult LastHit;

	// Cooldown in-between each hit
	float Cooldown = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Machine = Cast<AFlyingMachine>(Owner);
		Machine.OnCollision.AddUFunction(this, n"HandleMachineCollision");
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleMachineCollision(FHitResult Hit)
	{
		LastHit = Hit;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkActivation::DontActivate;

		if (!LastHit.bBlockingHit)
			return EHazeNetworkActivation::DontActivate;

		if (LastHit.ImpactNormal.DotProduct(-Machine.Orientation.Forward) < 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		if (Cooldown <= 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{	
		float AngleDot = LastHit.ImpactNormal.DotProduct(-Machine.Orientation.Forward);
		float AnglePercent = 1.f - FMath::Acos(AngleDot) / HALF_PI;

		float Damage = FMath::Lerp(Settings.CollisionMinDamage, Settings.CollisionMaxDamage, AnglePercent);
		ActivationParams.AddValue(n"Damage", Damage);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Machine.TakeDamage(ActivationParams.GetValue(n"Damage"));
		Cooldown = Settings.ImpactDamageCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		LastHit = FHitResult();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Cooldown -= DeltaTime;
	}
}
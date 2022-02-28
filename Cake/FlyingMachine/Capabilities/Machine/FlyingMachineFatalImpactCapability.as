import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;

class UFlyingMachineFatalImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 110;
	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;

	// Settings
	FFlyingMachineSettings Settings;

	// last registered hit (checked in pretick)
	FHitResult LastHit;

	// Fatal hit result (means that a hit was fatal and the capability should be activated)
	FHitResult FatalHit;

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

		if (!FatalHit.bBlockingHit)
			return EHazeNetworkActivation::DontActivate;

		if (GetGodMode(Game::Cody) == EGodMode::God)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddStruct(n"Hit", FatalHit);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (!HasControl())
			ActivationParams.GetStruct(n"Hit", FatalHit);

		Machine.CallOnFatalImpactEvent(FatalHit);
		Machine.OnDeath.Broadcast();
		FatalHit = FHitResult();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!CanPlayerBeKilled(Game::GetCody()))
		{
			LastHit = FHitResult();
			FatalHit = FHitResult();
			return;
		}

		if (LastHit.bBlockingHit)
		{
			FVector Forward = Machine.Orientation.Forward;
			if (Forward.DotProduct(-LastHit.ImpactNormal) >= Settings.CollisionFatalDotAngle)
			{
				FatalHit = LastHit;
			}

			LastHit = FHitResult();
		}
	}
}
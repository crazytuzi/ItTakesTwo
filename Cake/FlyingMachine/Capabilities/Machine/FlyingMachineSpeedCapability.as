import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;

class UFlyingMachineSpeedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Speed);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 101;

	default CapabilityDebugCategory = FlyingMachineCategory::Machine;

	AFlyingMachine Machine;
	UHazeCrumbComponent CrumbComp;

	// Settings
	FFlyingMachineSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Machine = Cast<AFlyingMachine>(Owner);
		CrumbComp = Machine.CrumbComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkActivation::DontActivate;

		if (Machine.Pilot == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Machine.HasPilot())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Machine.Pilot == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			// - CLAMP SPEED BETWEEN MIN AND MAX -
			{
				float ClampedSpeed = FMath::Clamp(Machine.Speed, Settings.MinSpeed, Settings.MaxSpeed);

				#if TEST
				if(Machine.bDebugLockedSpeed)
					ClampedSpeed = 0;
				#endif

				// Lerp towards it
				Machine.Speed = FMath::Lerp(Machine.Speed, ClampedSpeed, 4.f * DeltaTime);
			}

			// - CHANGE SPEED -
			{
				float CurrentPitchDot = Machine.ActorForwardVector.DotProduct(FVector::UpVector);

				// Make the pitchdot into an exponential curve instead of a linear curve
				//CurrentPitchDot = FMath::Pow(CurrentPitchDot, Settings.SpeedPitchExponent);

				if (CurrentPitchDot < 0.f)
				{
					float TargetSpeed = FMath::Lerp(Settings.MinSpeed, Settings.MaxSpeed, Math::Saturate(-CurrentPitchDot));
					TargetSpeed = FMath::Max(TargetSpeed, Machine.Speed);

					// Just lerp it
					Machine.Speed = FMath::Lerp(Machine.Speed, TargetSpeed, Settings.SpeedLerpCoefficient * DeltaTime);
					Machine.Speed = FMath::Lerp(Machine.Speed, Settings.MinSpeed, Settings.SpeedBaseDrag * DeltaTime);
				}
				else
				{
					// Just lerp it
					Machine.Speed = FMath::Lerp(Machine.Speed, Settings.MinSpeed, Settings.SpeedUpwardsDrag * CurrentPitchDot * DeltaTime);
				}
			}
		}
		else
		{
			FHazeActorReplicationFinalized TargetParams;
			CrumbComp.GetCurrentReplicatedData(TargetParams);

			// We stored the speed in the finalize capability
			Machine.Speed = TargetParams.CustomCrumbVector.X;
		}

		Machine.SpeedPercent = Math::GetPercentageBetween(Settings.MinSpeed, Settings.MaxSpeed, Machine.Speed);
	}
}
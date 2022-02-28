import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineOrientation;

class UFlyingMachineOrientationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::OrientationControl);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

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
		Machine.Orientation.SetFromRotator(Machine.GetActorRotation());
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
			FVector2D Input = GetAttributeVector2D(FlyingMachineAttribute::SteerInput);
			// Calculate roll, pitch and input scaling based on weight
			float WeightRoll = 0.f;
			float WeightPitch = 0.f;
			float WeightInputScalar = 1.f;

			for(FFlyingMachineWeight Weight : Machine.ExtraWeights)
			{
				float Roll = Weight.RelativeLocation.Y / 1500.f;
				Roll *= Weight.Weight;

				float Pitch = Weight.RelativeLocation.X / 1500.f;
				Pitch *= Weight.Weight;

				WeightRoll += Roll * Settings.MaxRollAngle;
				WeightPitch += Pitch;
				WeightInputScalar *= 1.f - 0.7f * Weight.Weight;
			}

			WeightRoll = FMath::Clamp(WeightRoll, -Settings.MaxRollAngle, Settings.MaxRollAngle);
			WeightPitch = FMath::Clamp(WeightPitch, -1.f, 1.f);

			Input *= WeightInputScalar;


			// - ROLLING AND YAWING -
			{
				// Apply turn modifier to max roll angle
				float MaxRoll = Settings.MaxRollAngle * Machine.TurnAngleModifier;

				float TargetRoll = Input.X * MaxRoll;
				TargetRoll += WeightRoll;

				Machine.Orientation.Roll = FMath::Lerp(Machine.Orientation.Roll, TargetRoll, Settings.RollLerpCoefficient * DeltaTime);

				// The yaaaw(n) (based on how much we're rolling)
				Machine.Orientation.AddYaw((Machine.Orientation.Roll / MaxRoll) * Settings.YawRate * Machine.TurnRateModifier * DeltaTime);
			}

			// - PITCHING -
			{
				float PitchInput = Input.Y;
				PitchInput += WeightPitch;

				// We want to limit how much you can pitch, so that you cant for example pitch until you're upside-down

				// How much we're currently pitched [-1, 1]
				float CurrentPitchDot = Machine.Orientation.GetForwardVector().DotProduct(FVector::UpVector);

				// What direction we want to pitch this frame [-1, 1]
				FVector PitchUp = Machine.Orientation.GetUpVector();
				float PitchInputDot = (PitchUp * PitchInput).DotProduct(FVector::UpVector);

				/*
					Calculate how close we are to hitting a singularity-point (where <= 0.0 means we're not close or going in the opposite direction)

					Sign(current pitch) * Sign(pitch input) will give us 1 if we're pitching TOWARDS the closest singularity and -1 if we're pitching AWAY
				*/
				float PitchFactor =
					FMath::Abs(CurrentPitchDot) *
					(FMath::Sign(CurrentPitchDot) * FMath::Sign(PitchInputDot));

				// We dont care if we're going away from a singularity
				PitchFactor = Math::Saturate(PitchFactor * Settings.PitchConstraintScalar);

				// Turn this number into a factor, and make it into an exponential curve, so the pitch will slow, then faster as we're nearing a singularity
				PitchFactor = 1.0 - FMath::Pow(PitchFactor, Settings.PitchConstraintExponent);
				
				// Pitch!
				Machine.Orientation.AddPitch(Settings.PitchRate * PitchInput * PitchFactor * Machine.TurnRateModifier * DeltaTime);
			}	
		}
		else
		{
			FHazeActorReplicationFinalized TargetParams;
			CrumbComp.GetCurrentReplicatedData(TargetParams);
			Machine.Orientation.SetFromRotator(FMath::RInterpConstantTo(Machine.Orientation.Rotator(), TargetParams.Rotation, DeltaTime, 100.f));
		}

		Machine.ClearWeights();
	}
}
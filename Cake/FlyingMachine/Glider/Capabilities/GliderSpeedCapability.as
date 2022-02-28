import Cake.FlyingMachine.Glider.FlyingMachineGlider;
import Cake.FlyingMachine.FlyingMachineOrientation;
import Cake.FlyingMachine.FlyingMachineSettings;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineGliderSpeedCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Glider);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default CapabilityDebugCategory = FlyingMachineCategory::Glider;

	AFlyingMachineGlider Glider;
	UFlyingMachineGliderComponent GliderComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Glider = Cast<AFlyingMachineGlider>(Owner);
		GliderComp = UFlyingMachineGliderComponent::GetOrCreate(Glider);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!GliderComp.bShouldAnimSpeed)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!GliderComp.bShouldAnimSpeed)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		GliderComp.SpeedAnimTimer += DeltaTime;
		if(GliderComp.SpeedAnimDuration > 0.f)
		{
			GliderComp.Speed = FMath::Lerp(
				GliderComp.SpeedAnimStart,
				GliderComp.SpeedAnimEnd,
				Math::Saturate(GliderComp.SpeedAnimTimer / GliderComp.SpeedAnimDuration)
			);
		}


		// Done with animation
		if (GliderComp.SpeedAnimTimer > GliderComp.SpeedAnimDuration)
		{
			GliderComp.bShouldAnimSpeed = false;
		}
	}
}
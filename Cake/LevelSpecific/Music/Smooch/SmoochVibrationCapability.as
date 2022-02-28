import Cake.LevelSpecific.Music.Smooch.Smooch;
import Cake.LevelSpecific.Music.Smooch.SmoochNames;

class USmoochVibrationCapability : UHazeCapability
{
	default CapabilityTags.Add(Smooch::Smooch);
	default CapabilityDebugCategory = n"Smooch";
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	USmoochUserComponent SmoochComp;
	float Intensity = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Intensity = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float TargetIntensity = FMath::Lerp(0.1f, 0.5f, SmoochComp.Progress);
		if (!SmoochComp.bIsHolding)
			TargetIntensity *= 0.35f;

		Intensity = FMath::FInterpTo(Intensity, TargetIntensity, DeltaTime, 2.8f);

		Player.SetFrameForceFeedback(Intensity, Intensity * 0.5f);
	}
}

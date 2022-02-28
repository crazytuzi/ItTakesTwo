import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrain;

class UCourtyardTrainChimneyPulseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gameplay");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 150;

	ACourtyardTrain Train;

	// Speed range used to lerp the pulse rate
	const float MinPulseSpeed = 200.f;
	const float MaxPulseSpeed = 1400.f;

	// Pulse rate range per second
	const float MinPulseRate = 0.1f;
	const float MaxPulseRate = 11.f;

	const float InterpSpeed = 1.f;
	float InterpedPulseDelta = MinPulseRate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Train = Cast<ACourtyardTrain>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (Train == nullptr)
			return;

		const float Alpha = FMath::Clamp((Train.CurrentSpeed - MinPulseSpeed) / (MaxPulseSpeed - MinPulseSpeed), 0.f, 1.f);
		const float PulsesPerSecond = FMath::Lerp(MinPulseRate, MaxPulseRate, Alpha);
		const float PulseDelta = 1.f / PulsesPerSecond;
		InterpedPulseDelta = FMath::FInterpTo(InterpedPulseDelta, PulseDelta, DeltaTime, InterpSpeed);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DeactiveDuration >= InterpedPulseDelta)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Train.OnChimneyPulse.Broadcast();

		Train.ChimneyNiagaraComp.Activate(true);
	}
}
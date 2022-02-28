import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyBeepIndicator;

class UHockeyBeepTimerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyBeepTimerCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHockeyBeepIndicator BeepIndicator;

	int StartingCount = 1.f;
	int CurrentCount;
	float MaxTimer = 1.f;
	float Timer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BeepIndicator = Cast<AHockeyBeepIndicator>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BeepIndicator.BeepIndicatorState == EBeepIndicatorState::BeepTime)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BeepIndicator.BeepIndicatorState != EBeepIndicatorState::BeepTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentCount = StartingCount;
		Timer = MaxTimer;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Timer -= DeltaTime;

		if (Timer <= 0.f)
		{
			CurrentCount--;
			Timer = MaxTimer;

			switch(CurrentCount)
			{
				case 1:
					BeepIndicator.BeepMesh.SetMaterial(0, BeepIndicator.YellowMat);
				break;

				case 0:
					BeepIndicator.BeepMesh.SetMaterial(0, BeepIndicator.GreenMat);
				break;
			}

			if (CurrentCount <= 0)
			{
				if (!BeepIndicator.bIsTimedWithCountdown)
					BeepIndicator.OnTimerCompleteEvent.Broadcast();
				
				BeepIndicator.BeepIndicatorState = EBeepIndicatorState::MoveUp;
			}
		}
	}
}
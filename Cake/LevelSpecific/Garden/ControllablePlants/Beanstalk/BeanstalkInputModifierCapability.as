import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class UBeanstalkInputModifierCapability : UHazeCapability
{
	ABeanstalk Beanstalk;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Beanstalk.InputModifierElapsed > 0.0f)
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Beanstalk.InputModifierElapsed < 0.0f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Beanstalk.InputModifier = 1.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Beanstalk.InputModifierElapsed = FMath::Max(Beanstalk.InputModifierElapsed - DeltaTime, 0.0f);
		Beanstalk.InputModifier = FMath::EaseOut(1.0f, 0.0f, FMath::Min(Beanstalk.InputModifierElapsed, 1.0f), 3.0f);
	}
}

import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class UBeanstalkHurtCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	ABeanstalk Beanstalk;

	float Elapsed = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(Beanstalk.CurrentState != EBeanstalkState::Hurt)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Elapsed = 0.5f;
		if(HasControl())
		{
			Beanstalk.CurrentVelocity = -Beanstalk.HurtPushback;
			Beanstalk.HurtPushback = 0.0f;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Beanstalk.WantedMovementDirection = -1.0f;
		Elapsed -= DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Elapsed < 0.0f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Beanstalk.CurrentState = EBeanstalkState::Active;
		Beanstalk.InputModifierElapsed = 1.0f;
	}
}

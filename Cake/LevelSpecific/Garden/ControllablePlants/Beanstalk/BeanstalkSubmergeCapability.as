import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;

class UBeanstalkSubmergeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 9;

	ABeanstalk Beanstalk;
	bool bHasPlayedDisappearEffect = false;

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

		if(Beanstalk.CurrentState != EBeanstalkState::Submerging)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Beanstalk.ApplySettings(Beanstalk.SubmergeSettings, this, EHazeSettingsPriority::Override);
		Beanstalk.DisableBeanstalkCollisionSphere();
		Beanstalk.SetCapabilityActionState(n"IsMoving_Audio", EHazeActionState::ActiveForOneFrame);
		Beanstalk.CurrentState = EBeanstalkState::Submerging;	// Setting this here for the remote also.
		bHasPlayedDisappearEffect = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasPlayedDisappearEffect)
		{
			const float DistanceCurrent = Beanstalk.VisualSpline.SplineLength;
			if(DistanceCurrent < Beanstalk.AppearVFXDistance)
			{
				bHasPlayedDisappearEffect = true;
				Beanstalk.BP_OnBeanstalkAppear(Beanstalk.HeadRotationNode.WorldLocation, Beanstalk.HeadRotationNode.ForwardVector);
				// Detach player early so the camera will not go through the ground.
				Beanstalk.OwnerPlayer.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
			}
		}
		
		if(!HasControl())
			return;

		Beanstalk.WantedMovementDirection = -1.0f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Beanstalk.CurrentState != EBeanstalkState::Submerging)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		if(Beanstalk.DistanceOnSplineCurrent > Beanstalk.StopDistance)
			OutParams.AddActionState(n"SetCollision");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Beanstalk.ClearSettingsByInstigator(this);
		Beanstalk.SetCapabilityActionState(n"IsNotMoving_Audio", EHazeActionState::ActiveForOneFrame);

		if(DeactivationParams.GetActionState(n"SetCollision"))
		{
			Beanstalk.EnableBeanstalkCollisionSphere();
		}
	}
}

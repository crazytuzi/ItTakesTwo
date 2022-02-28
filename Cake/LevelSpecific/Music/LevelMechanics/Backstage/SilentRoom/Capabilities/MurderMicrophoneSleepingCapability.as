import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneSleepingCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 10;

	AMurderMicrophone Snake;
	UMurderMicrophoneTargetingComponent TargetingComp;
	UMurderMicrophoneMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snake = Cast<AMurderMicrophone>(Owner);
		TargetingComp = UMurderMicrophoneTargetingComponent::Get(Owner);
		MoveComp = UMurderMicrophoneMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Snake.CurrentState != EMurderMicrophoneHeadState::Sleeping)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//Snake.SetCurrentState(EMurderMicrophoneHeadState::Sleeping);
		MoveComp.SetTargetLocation(Snake.HeadStartLocation);
		Snake.ApplySettings(Snake.SleepingSettings, this, EHazeSettingsPriority::Override);
		MoveComp.SetTargetFacingRotation(Snake.HeadStartRotation);
		MoveComp.ResetMovementVelocity();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Snake.HasTarget())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.CurrentState != EMurderMicrophoneHeadState::Sleeping)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Snake.ShouldEnterHypnosis())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HasControl() && !Snake.IsKilled())
		{
			if(Snake.ShouldEnterHypnosis())
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Hypnosis);
			else
				Snake.SetCurrentState(EMurderMicrophoneHeadState::Suspicious);
		}
		
		Snake.ClearSettingsByInstigator(this);
	}
}

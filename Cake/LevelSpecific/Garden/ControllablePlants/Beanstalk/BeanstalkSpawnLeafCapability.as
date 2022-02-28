import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;

class UBeanstalkSpawnLeafCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 0;

	ABeanstalk Beanstalk;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Beanstalk = Cast<ABeanstalk>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Beanstalk.IsLeafPairBlocked())
			return EHazeNetworkActivation::DontActivate;
		
		if (IsActioning(BeanstalkTags::SpawnLeaf) && Beanstalk.HasEnoughDistanceToSpawnLeafPair() && !Beanstalk.bIsStretching)
			return EHazeNetworkActivation::ActivateUsingCrumb;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		float RightLeafTargetScale = 0.0f;
		float LeftLeafTargetScale = 0.0f;

		if(Beanstalk.CanSpawnNewLeafPair(LeftLeafTargetScale, RightLeafTargetScale))
		{
			ActivationParams.AddValue(n"LeftLeafTargetScale", LeftLeafTargetScale);
			ActivationParams.AddValue(n"RightLeafTargetScale", RightLeafTargetScale);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Beanstalk.SpawnLeafPair(ActivationParams.GetValue(n"LeftLeafTargetScale"), ActivationParams.GetValue(n"RightLeafTargetScale"));
		Beanstalk.SetCapabilityActionState(n"AudioSpawnLeaf", EHazeActionState::Active);

		if(Beanstalk.CurrentVelocity < 0.0f)
		{
			Beanstalk.CurrentVelocity *= 0.5f;
			Beanstalk.InputModifierElapsed = 1.0f;
		}

		Game::GetCody().PlayForceFeedback(Beanstalk.SpawnLeafForceFeedback, false, true, n"SpawnLeaf");
	}
}

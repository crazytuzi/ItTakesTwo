import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.Beanstalk;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;
import Vino.Movement.Components.LedgeGrab.LedgeGrabComponent;

class UBeanstalkRemoveLeafCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	float TimeSpenteReversing = 0.0f;

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
		if ((IsActioning(BeanstalkTags::RemoveLeaf) || IsActioning(BeanstalkTags::RemoveLastLeaf)) && Beanstalk.HasSpawnedLeafPairs())
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(IsActioning(BeanstalkTags::RemoveLeaf))
		{
			ActivationParams.AddActionState(BeanstalkTags::RemoveLeaf);
		}
		else if(IsActioning(BeanstalkTags::RemoveLastLeaf))
		{
			ActivationParams.AddActionState(BeanstalkTags::RemoveLastLeaf);
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
		if(ActivationParams.GetActionState(BeanstalkTags::RemoveLeaf))
		{
			Beanstalk.RemoveFirstLeafPair();
		}
		else if(ActivationParams.GetActionState(BeanstalkTags::RemoveLastLeaf))
		{
			Beanstalk.RemoveLastLeafPair();
		}
	}
}

import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;
import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.ShotBySnowCannonComponent;

// Local (de)activation since action state is networkly set
class MagneticSnowCannonMagnetDestroyedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMagnetBasePad Basepad;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Basepad = Cast<AMagnetBasePad>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"ShouldDestroy"))
		{
        	return EHazeNetworkActivation::ActivateLocal;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
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
		ConsumeAction(n"ShouldDestroy");
		UShotBySnowCannonComponent::Get(Basepad).Explode();
	}
}
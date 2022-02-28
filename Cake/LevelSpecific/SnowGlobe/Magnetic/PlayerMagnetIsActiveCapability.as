import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;

class UPlayerMagnetIsActiveCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::IsUsingMagnet);
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(FMagneticTags::IsUsingMagnet))
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"SnowGlobeSideContent", this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(FMagneticTags::IsUsingMagnet))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"SnowGlobeSideContent", this);
	}
}
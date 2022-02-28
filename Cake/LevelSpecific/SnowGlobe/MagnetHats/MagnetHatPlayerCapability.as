import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHat;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHatManager;
import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHatPlayerComp;

class UMagnetHatPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetHatPlayerCapability");
	default CapabilityTags.Add(n"MagnetHat");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 200;

	AHazePlayerCharacter Player;

	UMagnetHatPlayerComp PlayerComp;

	TArray<AMagnetHatManager> MagnetHatManagerArray;
	AMagnetHatManager MagnetHatManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GetAllActorsOfClass(MagnetHatManagerArray);
		MagnetHatManager = MagnetHatManagerArray[0];
		PlayerComp = UMagnetHatPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
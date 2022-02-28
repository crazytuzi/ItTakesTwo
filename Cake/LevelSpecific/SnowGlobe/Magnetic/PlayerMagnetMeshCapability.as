import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Peanuts.Outlines.Outlines;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;

UCLASS(Abstract)
class UPlayerMagnetMeshCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetMesh);
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent MagneticPlayerComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::GetOrCreate(Owner);

		MagneticPlayerComponent.SpawnMagnetActor();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		MagneticPlayerComponent.SetMagnetMeshIsHidden(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		MagneticPlayerComponent.SetMagnetMeshIsHidden(false);
	}
}
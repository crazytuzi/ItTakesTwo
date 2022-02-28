import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Vino.Camera.Capabilities.CameraTags;
class UPlayerCameraBlockCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(CameraTags::ChaseAssistance);
	default CapabilityTags.Add(n"PlayerCameraDefaultCapability");
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default CapabilityDebugCategory = n"GamePlay";	
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;

	UCameraComponent CameraComp;

	UCameraUserComponent CameraUser;

	UPlayerFishingComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraComp = UCameraComponent::Get(Player);
		PlayerComp = UPlayerFishingComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Player.BlockCapabilities(CapabilityTags::Camera, this);
		// Player.BlockCapabilities(CameraTags::Control, this);

	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Player.BlockCapabilities(CameraTags::Control, this);
		// Player.UnblockCapabilities(CapabilityTags::Camera, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

}
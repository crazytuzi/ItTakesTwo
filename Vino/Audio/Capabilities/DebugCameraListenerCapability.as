import Peanuts.Audio.AudioStatics;
import Vino.Camera.CameraStatics;

class UDebugCameraListenerCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityTags.Add(n"Audio");
	default TickGroup = ECapabilityTickGroups::Input;
    default CapabilityDebugCategory = n"Audio";

	AHazePlayerCharacter Player;	
	UHazeListenerComponent Listener;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	
		Listener = UHazeListenerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(FCameraTags::DebugCamera) && (Player != nullptr))
			return EHazeNetworkActivation::ActivateFromControl;
		
		return EHazeNetworkActivation::DontActivate;
	}
 
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(FCameraTags::DebugCamera))
			return EHazeNetworkDeactivation::DeactivateFromControl; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"AudioDefaultListener", this);
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(const FCapabilityDeactivationParams &DeactivationParams)
	{
		Player.UnblockCapabilities(n"AudioDefaultListener", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector DebugCameraLocation = Player.GetPlayerViewLocation();
		FRotator DebugCameraRotator = Player.GetPlayerViewRotation();
		FTransform DebugCameraTrans = FTransform(DebugCameraLocation);
		DebugCameraTrans.SetRotation(DebugCameraRotator);	

		Listener.SetWorldTransform(DebugCameraTrans);
		
	}
}
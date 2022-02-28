import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;

// Capability to match desired rotation to view rotation when there are no cameras that can be controlled by input
class UCameraNonControlledCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::NonControlled);

	// This should overwrite anything we get from input and other camera control capabilities. 
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
    default CapabilityDebugCategory = CameraTags::Camera;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkActivation::DontActivate;
		if (User.CanControlCamera())
			return EHazeNetworkActivation::DontActivate;

		// Ignore on remote side; control rotation is replicated
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((User == nullptr) || User.InitialIgnoreInput())
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (User.CanControlCamera())
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (User != nullptr)
			User.RegisterDesiredRotationReplication(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (User != nullptr)
			User.UnregisterDesiredRotationReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Set desired rotation to current view rotation
		FRotator ViewRot = PlayerUser.GetPlayerViewRotation();
		if (!User.HasScreenSize())
			ViewRot = PlayerUser.OtherPlayer.GetPlayerViewRotation();
		FRotator ViewRotLocal = User.WorldToLocalRotation(ViewRot);
		FRotator CurRotLocal = User.WorldToLocalRotation(User.GetDesiredRotation());
		User.AddDesiredRotation(ViewRotLocal - CurRotLocal);
	}
}

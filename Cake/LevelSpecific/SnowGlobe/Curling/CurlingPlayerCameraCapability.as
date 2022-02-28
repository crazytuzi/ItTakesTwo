import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;

class UCurlingPlayerCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingPlayerCameraCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::PostWork;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UCameraUserComponent CameraUser;

	FRotator StartDesiredRotation;

	UCurlingPlayerComp PlayerComp;

	bool bRemainActive;

	bool bHaveSetTimer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraUser = UCameraUserComponent::Get(Player);
		PlayerComp = UCurlingPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
        	return EHazeNetworkActivation::DontActivate;
		//this should activate before we activate camera 

		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Shooting)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		//this should deactivate half a second after we deactivate camera 
		// if (!bRemainActive)
		if (PlayerComp.PlayerCurlState != EPlayerCurlState::Shooting)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bRemainActive = true;
		bHaveSetTimer = false;

		PlayerComp.BeforeShootCamRotation = CameraUser.DesiredRotation;

		if (CameraUser != nullptr)
			CameraUser.RegisterDesiredRotationReplication(this);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (CameraUser != nullptr)
			CameraUser.UnregisterDesiredRotationReplication(this);

		PlayerComp.bCompleteCamera = false;

		CameraUser.SetDesiredRotation(PlayerComp.BeforeShootCamRotation); 
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		//TODO Move to DEACTIVATE LATER
		// CameraUser.SetDesiredRotation(PlayerComp.BeforeShootCamRotation); 
	}
}
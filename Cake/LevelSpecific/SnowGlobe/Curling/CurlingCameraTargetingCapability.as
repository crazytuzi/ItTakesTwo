import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerComp;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;

class UCurlingCameraTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingCameraTargetingCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UCameraComponent CameraComp;

	UCameraUserComponent CameraUser;

	UCurlingPlayerComp PlayerComp;

	FHazeAcceleratedRotator AcceleratedTargetRotation;

	bool bStartedThrow;

	float DeactivateTimer = 0.8f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UCurlingPlayerComp::Get(Player);
		CameraComp = UCameraComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{				
		if (PlayerComp.PlayerCurlState == EPlayerCurlState::MoveStone)
	        return EHazeNetworkActivation::ActivateLocal;
		
		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Targeting)
	        return EHazeNetworkActivation::ActivateLocal;

		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Engaging)
	        return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Targeting)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (PlayerComp.PlayerCurlState == EPlayerCurlState::MoveStone)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (PlayerComp.PlayerCurlState == EPlayerCurlState::Engaging)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.2f;
		Player.ApplyCameraSettings(PlayerComp.TargetCamSettings, Blend, this);
		AcceleratedTargetRotation.SnapTo(CameraComp.WorldRotation);	

		Player.BlockCameraSyncronization(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this);
		Player.UnblockCameraSyncronization(this);
		
		// Make remote side camera catch up smoother when crumb sync is restored
		CameraUser.SetTemporaryReplicationAccelerationDuration(5.f, 5.f); 
	}

	UFUNCTION()
	void CameraSetView(float DeltaTime)
	{
		FVector Direction = Owner.ActorForwardVector + FVector(0.f, 0.f, -0.3f);
		FRotator MakeRot = FRotator::MakeFromX(Direction);

		AcceleratedTargetRotation.AccelerateTo(MakeRot, 1.f, DeltaTime);

		CameraUser.DesiredRotation = AcceleratedTargetRotation.Value;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CameraSetView(DeltaTime);
	}
}
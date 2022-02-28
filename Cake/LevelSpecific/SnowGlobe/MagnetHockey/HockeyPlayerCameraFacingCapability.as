import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;
import Vino.Camera.Components.CameraUserComponent;

class UHockeyPlayerCameraFacingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerBlockMovementCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UCameraUserComponent UserComp;

	UHockeyPlayerComp PlayerComp;

	FHazeAcceleratedRotator AcceleratedRot;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.HockeyPlayerState == EHockeyPlayerState::MovementBlocked)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.HockeyPlayerState != EHockeyPlayerState::MovementBlocked)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedRot.SnapTo(UserComp.DesiredRotation);
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraSettings(PlayerComp.CameraSettings, Blend, this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5f);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector LookDirection = (PlayerComp.HockeyPuck.ActorLocation - Player.ActorLocation).GetSafeNormal();
		FRotator SmoothRotation = FRotator::MakeFromX(LookDirection);
		AcceleratedRot.AccelerateTo(SmoothRotation, 2.5f, DeltaTime);
		UserComp.SetDesiredRotation(AcceleratedRot.Value);
	}
}
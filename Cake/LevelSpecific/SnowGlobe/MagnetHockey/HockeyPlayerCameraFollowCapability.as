import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;

class UHockeyPlayerCameraFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerCameraFollowCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UCameraUserComponent UserComp;

	UHockeyPlayerComp PlayerComp;

	float MinDistance = 1300.f;

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
		if (PlayerComp.HockeyPlayerState == EHockeyPlayerState::InPlay)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.HockeyPlayerState != EHockeyPlayerState::InPlay)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraSettings(PlayerComp.CameraSettings, Blend, this);

		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5f);
		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);

	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (PlayerComp.HockeyPuck == nullptr)
			return;

		float Distance = (PlayerComp.HockeyPuck.ActorLocation - Player.ActorLocation).Size();

		FVector LookDirection = (PlayerComp.HockeyPuck.ActorLocation - UserComp.PivotLocation).GetSafeNormal();
		FRotator LookAtRot = FRotator::MakeFromX(LookDirection);
		FRotator NewRot = FMath::RInterpTo(UserComp.DesiredRotation, LookAtRot, DeltaTime, 2.5f);
		UserComp.SetDesiredRotation(NewRot);
		// if (PlayerComp.bIsActivatingAbility || Distance <= MinDistance)
		// {
		// }

	}
}
import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Vino.Camera.Components.CameraUserComponent;

class UPlayerBombCameraOnResetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerBombCameraOnResetCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UPlayerTimeBombComp PlayerComp;

	UCameraUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerTimeBombComp::Get(Player);
		UserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.bResetCamOnRespawn)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PlayerComp.bResetCamOnRespawn)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerComp.bResetCamOnRespawn = false;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FRotator Direction = FRotator::MakeFromX(PlayerComp.FacingDirection);
		FRotator DirectionAdjusted = Direction + FRotator(-25.f, 0.f, 0.f);
		UserComp.SetDesiredRotation(DirectionAdjusted);
	}
}
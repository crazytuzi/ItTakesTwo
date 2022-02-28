import Cake.LevelSpecific.Garden.MiniGames.SpiderTag.SpiderTagGameManager;
import Vino.Camera.Components.CameraUserComponent;

class UTagFollowCameraRotResetCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TagFollowCameraRotResetCapability");
	default CapabilityTags.Add(n"Tag");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ASpiderTagGameManager GameManager;

	float Timer;

	TPerPlayer<UCameraUserComponent> UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		GameManager = Cast<ASpiderTagGameManager>(Owner);

		UserComp[0] = UCameraUserComponent::Get(Game::May);
		UserComp[1] = UCameraUserComponent::Get(Game::Cody);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GameManager.bSettingRotation)
        	return EHazeNetworkActivation::ActivateFromControl;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!GameManager.bSettingRotation)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Timer = 0.9f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FRotator DesiredRot1 = FMath::RInterpTo(UserComp[0].DesiredRotation, GameManager.MainCamera.ActorRotation, DeltaTime, 3.5f);
		FRotator DesiredRot2 = FMath::RInterpTo(UserComp[1].DesiredRotation, GameManager.MainCamera.ActorRotation, DeltaTime, 3.5f);

		UserComp[0].DesiredRotation = DesiredRot1;
		UserComp[1].DesiredRotation = DesiredRot2;

		Timer -= DeltaTime;

		if (Timer <= 0.f)
			GameManager.bSettingRotation = false;
	}
}
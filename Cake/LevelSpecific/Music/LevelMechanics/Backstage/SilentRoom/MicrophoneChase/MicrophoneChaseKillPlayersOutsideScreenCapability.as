
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.CharacterMicrophoneChaseComponent;

class UMicrophoneChaseKillPlayersOutsideScreenCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MicrophoneChaseKillPlayersOutsideScreenCapability");

	default CapabilityDebugCategory = n"MicrophoneChaseKillPlayersOutsideScreenCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCharacterMicrophoneChaseComponent CharacterChaseComp;

	private bool bKillPlayer = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CharacterChaseComp = UCharacterMicrophoneChaseComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"CheckingScreen"))
			return EHazeNetworkActivation::DontActivate;

		if(Player.IsPlayerDead())
			return EHazeNetworkActivation::DontActivate;

		if(CharacterChaseComp.bMicrophoneChaseDone)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bKillPlayer = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"CheckingScreen"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bKillPlayer)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Player.IsPlayerDead())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(CharacterChaseComp.bMicrophoneChaseDone)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bKillPlayer && !Player.IsPlayerDead())
			KillPlayer(Player, CharacterChaseComp.OutOfScreenDeathEffect);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D ScreenPos;
		bool bInfronOfCamera;
		bInfronOfCamera = SceneView::ProjectWorldToScreenPosition(Player, Player.ActorLocation, ScreenPos);
		if (!bInfronOfCamera)
			bKillPlayer = true;
	}
}

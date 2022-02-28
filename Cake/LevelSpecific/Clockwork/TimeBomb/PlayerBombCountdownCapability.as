import Cake.LevelSpecific.Clockwork.TimeBomb.PlayerTimeBombComp;
import Cake.LevelSpecific.Clockwork.TimeBomb.WidgetBombTimer;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.TimeBomb.TimeBombGameManager;

class UPlayerBombCountdownCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerBombCountdownCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	TArray<ATimeBombGameManager> TimeBombGameManagerArray;

	ATimeBombGameManager TimeBombGameManager;

	UPlayerTimeBombComp PlayerComp;
	
	float NewLightTime;
	float TotalTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerTimeBombComp::Get(Player);
		GetAllActorsOfClass(TimeBombGameManagerArray);

		if (TimeBombGameManagerArray.Num() > 0)
			TimeBombGameManager = TimeBombGameManagerArray[0];
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.TimeBombState == ETimeBombState::Ticking || PlayerComp.TimeBombState == ETimeBombState::Spawned)
        	return EHazeNetworkActivation::ActivateFromControl;
			
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.TimeBombState != ETimeBombState::Ticking && PlayerComp.TimeBombState != ETimeBombState::Spawned)
        	return EHazeNetworkDeactivation::DeactivateFromControl;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.CountDownStage = PlayerComp.MaxCountDownStage;
		PlayerComp.CurrentStageSeconds = PlayerComp.MaxStageSeconds;
		PlayerComp.LightRate = PlayerComp.MaxLightRate;

		TotalTime = PlayerComp.MaxStageSeconds * PlayerComp.CountDownStage;

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;
		Player.ApplyCameraSettings(PlayerComp.SpringArmSettingsBombRace, Blend, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 1.5f);
	}
}
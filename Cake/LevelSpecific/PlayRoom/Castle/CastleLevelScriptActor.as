import Cake.LevelSpecific.PlayRoom.Castle.CastleCamera.CastleCameraActor;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Checkpoints.Checkpoint;
import Vino.PlayerHealth.PlayerHealthSettings;
import Vino.Camera.Settings.FocusTargetSettings;

class ACastleLevelScriptActor : AHazeLevelScriptActor
{
	bool bTriggeredGameOver;

	UFUNCTION(DevFunction)
	void GrantMaxUltimate()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UCastleComponent CastleComp = UCastleComponent::Get(Player);
			if (CastleComp == nullptr)
				return;

			CastleComp.AddUltimateCharge(CastleComp.UltimateChargeMax);

		}
	}

	UFUNCTION()
	void InitializeCastleLevel(
		ACheckpoint Checkpoint,		
		ACastleCamera CastleCamera,
		UHazeCapabilitySheet BruteSheet,
		UHazeCapabilitySheet MageSheet,
		UPlayerHealthSettings HealthSettings,
		bool bReachedbyNaturalProgression = false)
	{
		if (bReachedbyNaturalProgression)
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				TeleportPlayerToCheckpoint(Player, Checkpoint);
				SetupCastleCamera(Player, CastleCamera);
			}
		}
		else
		{
			for (AHazePlayerCharacter Player : Game::GetPlayers())
			{
				TeleportPlayerToCheckpoint(Player, Checkpoint);
				SetupCastleCamera(Player, CastleCamera);
				SetupPlayerSheets(Player, BruteSheet, MageSheet);
			}

			SetupCastleHealth(HealthSettings);
		}
	}

	UFUNCTION()
	void SetupCastleHealth(UPlayerHealthSettings HealthSettings)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.ApplySettings(HealthSettings, this);			
		}
	}

	UFUNCTION()
	void TeleportPlayerToCheckpoint(AHazePlayerCharacter Player, ACheckpoint Checkpoint)
	{
		if (Player == nullptr || Checkpoint == nullptr)
			return;

		Checkpoint.TeleportPlayerToCheckpoint(Player);
		// Removed other logic, so now it is just a TeleportPlayerToCheckpoint.
	}

	UFUNCTION()
	void SetupCastleCamera(AHazePlayerCharacter Player, ACastleCamera CastleCamera)
	{
		if (Player == nullptr || CastleCamera == nullptr)
			return;

		// Player focus location should be at player feet rather than head throughout this level
		UFocusTargetSettings::SetComponent(Player, Player.RootOffsetComponent, this);
		UFocusTargetSettings::SetCapsuleHeightOffset(Player, 0.f, this);

		CastleCamera.ActivateCamera(Player, 0, this, EHazeCameraPriority::Script);
		if (Player.IsMay())
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant);	
	}

	UFUNCTION()
	void UpdateCamera(ACastleCamera Camera, bool bSnap = false)
	{
		// This has been moved to castle camera comp
	}

	UFUNCTION()
	void SetupPlayerSheets(AHazePlayerCharacter Player, UHazeCapabilitySheet BruteSheet, UHazeCapabilitySheet MageSheet)
	{
		if (Player == nullptr)
			return;

		UHazeCapabilitySheet PlayerSheet = Player.IsMay() ? BruteSheet : MageSheet;

		if (PlayerSheet == nullptr)
			return;
		
		Player.AddCapabilitySheet(PlayerSheet, EHazeCapabilitySheetPriority::Normal, this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		// Clears all composable settings we have applied
		Game::Cody.ClearSettingsByInstigator(this);
		Game::May.ClearSettingsByInstigator(this);
	}

	UFUNCTION()
	void KillAllEnemies(TArray<ACastleEnemy> OptionalExceptions)
	{
		TArray<ACastleEnemy> CastleEnemies;
		CastleEnemies = GetAllCastleEnemies();

		for (ACastleEnemy Enemy : CastleEnemies)
		{
			if (!OptionalExceptions.Contains(Enemy))
				Enemy.Kill();
		}
	}
};
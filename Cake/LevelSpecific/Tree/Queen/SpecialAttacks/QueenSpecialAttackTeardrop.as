import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackComponent;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.FallingBeehiveActor;
import Vino.Camera.CameraStatics;

class UQueenSpecialAttackTeardrop : UQueenSpecialAttackComponent
{
	UPROPERTY()
	TArray<AFallingBeeHiveActor> BombingRun01_Beehives;

	UPROPERTY()
	TArray<AFallingBeeHiveActor> BombingRun02_Beehives;

	UPROPERTY()
	TArray<AActor> SpawnPositions;

	UPROPERTY()
	AHazeCameraVolume CameraVolume;

	UPROPERTY()
	AHazeCameraVolume LookAtQueenCameraVolume;

	UPROPERTY()
	AHazeLevelSequenceActor AirplaneIntro;

	int Iteration = 0;

	UFUNCTION(BlueprintOverride)
	void SpecialAttackActivated()
	{
		bIsRunningAttack = true;
		BlockGrindSplines(true);
		System::SetTimer(this, n"ActivateSpecialAttackSequence", 2.f, false);
	}

	UFUNCTION()
	void ActivateSpecialAttackSequence()
	{
		Super::SpecialAttackActivated();

		ParkAllSwarms(Queen);
		Queen.EnableRailBlockerSwarms();
		LookAtQueenCameraVolume.Enable();
		ActivatePullUpSequence();
        
		System::SetTimer(this, n"TriggerFullScreen", 2, bLooping=false);
		System::SetTimer(this, n"BlockRailGates", 2, bLooping=false);
		System::SetTimer(this, n"StartPlaneIntro", 3, bLooping=false);
		System::SetTimer(this, n"RespawnPlayers", 1, false);

		System::SetTimer(this, n"DisableLookatQueenCameraVolume", 4.f, bLooping=false);

		System::SetTimer(this, n"ActivatePullDownSequence", 38.f, bLooping=false);
		System::SetTimer(this, n"ResumeToBoss", 38.f, bLooping=false);
		
		RestorePlayerHealth();
		Queen.ThrowPlayersIntoArena();
		Queen.StopBossSpawning();
		StartLetterbox();
		BlockWeapons();
	}
	

	UFUNCTION(BlueprintEvent)
	void StartPlaneIntro()
	{

	}

	UFUNCTION()
	void BlockRailGates()
	{
		Queen.SetBlockingVolumesEnabled(true);
		SetGrindingEnabled(false);
	}

	UFUNCTION()
	void DisableLookatQueenCameraVolume()
	{
		LookAtQueenCameraVolume.Disable();
		CameraVolume.Enable();
		
		for (auto var : Game::GetPlayers())
		{
			var.UnblockCapabilities(n"PlayerArrow", var);
		}
	}

	UFUNCTION()
	void StopAllTearDrops()
	{
		bIsRunningAttack = false;
		Iteration = 0;
	}

	UFUNCTION()
	void ResumeToBoss()
	{
		Queen.ResumeBossSpawning();
		Queen.DisableRailBlockerSwarms();
		BlockGrindSplines(false);
		UnparkAllSwarms(Queen);
		UnblockWeapons();
		ResetFullScreen();
		Queen.SetBlockingVolumesEnabled(false);
		SetGrindingEnabled(true);
		RestorePlayerHealth();

		for (auto player : Game::GetPlayers())
		{
			FLookatFocusPointData FocusPointData;
			FocusPointData.Actor = Queen.LookatQueenAfterSpecialAttackActor;
			FocusPointData.Duration = 2;
			FocusPointData.FOV = 60;
			FocusPointData.ShowLetterbox = false;
			LookAtFocusPoint(player, FocusPointData);
		}

		for (auto var : Game::GetPlayers())
		{
			var.BlockCapabilities(n"PlayerArrow", var);
		}
		
		CameraVolume.Disable();
	}
}
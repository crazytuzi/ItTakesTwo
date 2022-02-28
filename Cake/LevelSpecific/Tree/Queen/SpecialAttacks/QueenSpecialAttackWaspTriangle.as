import Cake.LevelSpecific.Tree.Queen.SpecialAttacks.QueenSpecialAttackComponent;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspShapeActorTriangle;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.FallingBeehiveActor;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspScissor.WaspScissorComponent;
import Vino.Camera.CameraStatics;

class UQueenAttackWaspTriangle : UQueenSpecialAttackComponent
{
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlaneDiveAudioEvent;
	
	UPROPERTY()
	TArray<AFallingBeeHiveActor> Beehives;

	UPROPERTY()
	AHazeCameraVolume CameraVolume;

	UPROPERTY()
	AHazeCameraVolume LookAtQueenCameraVolume;

	int Iteration = 0;

	UFUNCTION(BlueprintOverride)
	void SpecialAttackActivated()
	{
		bIsRunningAttack = true;
		BlockGrindSplines(true);
		System::SetTimer(this, n"ActivateSpecialAttackSequence", 2, bLooping=false);
	}

	UFUNCTION()
	void ActivateSpecialAttackSequence()
	{
		Super::SpecialAttackActivated();
		ParkAllSwarms(Queen);
		Queen.EnableRailBlockerSwarms();
		LookAtQueenCameraVolume.Enable();
		ActivatePullUpSequence();
		Queen.ThrowPlayersIntoArena();
		RestorePlayerHealth();
		System::SetTimer(this, n"RespawnPlayers", 1, false);
		System::SetTimer(this, n"TriggerFullScreen", 2, bLooping=false);
		System::SetTimer(this, n"BlockRailGates", 2, bLooping=false);
        System::SetTimer(this, n"DisableLookatQueenCameraVolume", 3.f, bLooping=false);
		System::SetTimer(this, n"DropScissors", 4.f, bLooping=false);
		System::SetTimer(this, n"ActivatePullDownSequence", 40.f, bLooping=false);
		System::SetTimer(this, n"StopAllScissors", 40.f, bLooping=false);

		Queen.StopBossSpawning();
		StartLetterbox();
		BlockWeapons();
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
		StopLetterbox();

		for (auto var : Game::GetPlayers())
		{
			var.UnblockCapabilities(n"PlayerArrow", var);
		}
	}

	UFUNCTION()
	void DropScissors()
	{
		if (!bIsRunningAttack)
		{
			return;
		}

		UHazeAkComponent::HazePostEventFireForget(PlaneDiveAudioEvent, FTransform());
		Beehives[Iteration].StartFalling();
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		UWaspScissorcomponent ScissorComp = UWaspScissorcomponent::Get(Beehives[Iteration].Swarm);
		ScissorComp.Player = Players[Iteration % 2];
		Iteration++;

		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightSecondPhaseScissorsWaspQueen", Queen);

		if (Iteration < Beehives.Num())
		{
			System::SetTimer(this, n"DropScissors", 4.f, bLooping = false);
		}
	}

	UFUNCTION()
	void StopAllScissors()
	{
		for (auto var : Game::GetPlayers())
		{
			var.BlockCapabilities(n"PlayerArrow", var);
		}

		bIsRunningAttack = false;
		Iteration = 0;
		CameraVolume.Disable();

		for (auto hive : Beehives)
		{
			hive.Stop();
		}

		Queen.ResumeBossSpawning();
		Queen.DisableRailBlockerSwarms();
		Queen.SetBlockingVolumesEnabled(false);
		
		UnparkAllSwarms(Queen);
		UnblockWeapons();
		
		for (auto player : Game::GetPlayers())
		{
			FLookatFocusPointData FocusPointData;
			FocusPointData.Actor = Queen.LookatQueenAfterSpecialAttackActor;
			FocusPointData.Duration = 2;
			FocusPointData.FOV = 60;
			FocusPointData.ShowLetterbox = false;
			LookAtFocusPoint(player, FocusPointData);
		}

		SetGrindingEnabled(true);
		ResetFullScreen();
		RestorePlayerHealth();
		BlockGrindSplines(false);
	}
}
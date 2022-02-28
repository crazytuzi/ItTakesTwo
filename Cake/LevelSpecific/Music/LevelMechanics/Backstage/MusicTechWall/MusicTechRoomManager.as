import Vino.Camera.Components.CameraKeepInViewComponent;
import Peanuts.Spline.SplineComponent;
import Peanuts.Movement.SplineLockStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechKnobs;
import Peanuts.Spline.SplineActor;
import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechWallPowerCable;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BackstagePowerSwitch;
import Vino.Checkpoints.Volumes.DeathVolume;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechWallDoor;
import Peanuts.AutoMove.CharacterAutoMoveComponent;
import Peanuts.DamageFlash.DamageFlashStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechWallEqualizerSweeper;

event void FMusicTechRoomManagerSignature();

class AMusicTechRoomManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	bool bTechWallActive = false;
	bool bKnobTurnActive = false;
	bool bShouldTickDestinationTimer = false;

	bool bMayEnteredTrigger = false;

	/* Splines */ 
	UPROPERTY(Category = "References|Spline")
	AHazeCameraActor MaySplineCam01;

	UPROPERTY(Category = "References|Spline")
	ASplineActor MaySplineLock01;

	UPROPERTY(Category = "References|Spline")
	ASplineActor MaySplineLock02;

	UPROPERTY(Category = "References|Spline")
	ASplineActor MaySplineLock03;

	UPROPERTY(Category = "References|Spline")
	ASplineActor CodySplineLock01;

	/* Cameras */
	UPROPERTY(Category = "References|Cameras")
	AHazeCameraActor SweeperCamera;

	UPROPERTY(Category = "References|Cameras")
	AHazeCameraActor KnobCam;

	UPROPERTY(Category = "References|Cameras")
	AHazeCameraActor ChimeCamera;

	UPROPERTY(Category = "References|Cameras")
	AHazeCameraActor AfterChimeCamera;

	/* Triggers */ 
	UPROPERTY(Category = "References|Trigger")
	APlayerTrigger HideChimeTrigger;

	UPROPERTY(Category = "References|Trigger")
	APlayerTrigger TeleportMayToEqSweeper;

	UPROPERTY(Category = "References|Trigger")
	APlayerTrigger ChangeToSweeperCameraTrigger;

	UPROPERTY(Category = "References|Trigger")
	APlayerTrigger StartSplineLockOnChime;

	UPROPERTY(Category = "References|Trigger")
	APlayerTrigger AfterChimeTrigger;

	/* Actors */
	UPROPERTY(Category = "References|Actors")
	AStaticMeshActor ChimeHolder;
	
	UPROPERTY(Category = "References|Actors")
	AMusicTechKnobs MusicTechKnobs;

	UPROPERTY(Category = "References|Actors")
	AActor CodyMoveToLocation;

	UPROPERTY(Category = "References|Actors")
	AMusicTechWallDoor MusictechWallDoor01;

	UPROPERTY(Category = "References|Actors")
	AMusicTechWallDoor MusictechWallDoor02;

	UPROPERTY(Category = "References|Actors")
	ABlockingVolume BlockingVolumeAfterChime;

	UPROPERTY(Category = "References|Actors")
	AMusicTechWallEqualizerSweeper EqualizerSweeper;
	
	/* Event Actors */
	UPROPERTY(Category = "References|EventActors")
	AMusicTechWallPowerCable MusicTechPowerCable;

	UPROPERTY(Category = "References|EventActors")
	ABackstagePowerSwitch BackstagePowerSwitch;

	/* Timers */
	float Timer = 0.f;

	
	/* Other */
	UPROPERTY(Category = "References|Other")
	UMaterialParameterCollection WorldShaderParameters;

	UPROPERTY(Category = "References|Other")
	ADeathVolume SweeperDeathVolume;

	UPROPERTY(Category = "References|Other")
	FLinearColor MayEmissiveColor;

	UPROPERTY()
	FMusicTechRoomManagerSignature StartSequenceEvent;

	UPROPERTY()
	FMusicTechRoomManagerSignature MusicTechPowerSwitchActivated;

	AHazePlayerCharacter PlayerOnMusicTech;

	AHazePlayerCharacter PlayerOnKnob;

	FHazeCameraBlendSettings Blend;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HideChimeTrigger.OnPlayerEnter.AddUFunction(this, n"HideChimeTriggerEvent");
		TeleportMayToEqSweeper.OnPlayerEnter.AddUFunction(this, n"TeleportMayToEqSweeperEvent");
		ChangeToSweeperCameraTrigger.OnPlayerEnter.AddUFunction(this, n"ChangeToSweeperCameraTriggerEvent");
		StartSplineLockOnChime.OnPlayerEnter.AddUFunction(this, n"StartSplineLockOnChimeEvent");
		AfterChimeTrigger.OnPlayerEnter.AddUFunction(this, n"AfterChimeTriggerEvent");
		MusicTechPowerCable.StartedPowerCable.AddUFunction(this, n"StartedPowerCable");
		BackstagePowerSwitch.SwitchActivatedEvent.AddUFunction(this, n"SwitchActivated");
		BackstagePowerSwitch.OnPlayerStartedInteraction.AddUFunction(this, n"OnPlayerStartedPowerSwitch");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	
	}

	UFUNCTION()
	void InitMusicTechRoom()
	{
		FConstraintSettings LockSettings;
		LockSettings.SplineToLockMovementTo = MaySplineLock01.Spline;
		LockSettings.ConstrainType = EConstrainCollisionHandlingType::FreeVertical;
		BlockingVolumeAfterChime.SetActorEnableCollision(false);
		
		if(Game::GetMay().HasControl())
		{
			Game::GetMay().StartSplineLockMovement(LockSettings);
		}

		MusicTechKnobs.ActivateTechKnobs();

		FHazeCameraBlendSettings BlendSettings;

		KnobCam.ActivateCamera(Game::GetCody(), BlendSettings, this);
		MaySplineCam01.ActivateCamera(Game::GetMay(), BlendSettings, this);

		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Horizontal);
		
		Game::GetCody().ApplyViewSizeOverride(this, EHazeViewPointSize::Small);
		Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Large);
	}

	UFUNCTION()
	void HideChimeTriggerEvent(AHazePlayerCharacter Player)
	{
		ChimeHolder.SetActorHiddenInGame(true);
	}

	UFUNCTION()
	void TeleportMayToEqSweeperEvent(AHazePlayerCharacter Player)
	{
		EqualizerSweeper.SetSweeperActive(true);
		//Material::SetScalarParameterValue(WorldShaderParameters, n"MayPixelation", 1.f);
	}

	UFUNCTION()
	void ChangeToSweeperCameraTriggerEvent(AHazePlayerCharacter Player)
	{
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 2.f;
		SweeperCamera.ActivateCamera(Game::GetMay(), BlendSettings, this);
		FlashActor(Game::GetMay(), BIG_NUMBER, MayEmissiveColor);
	}

	UFUNCTION()
	void StartedPowerCable()
	{
		if(Game::GetMay().HasControl())
		{
			Game::GetMay().StopSplineLockMovement();
		}
		
		EqualizerSweeper.SetSweeperActive(false);

		if (SweeperDeathVolume != nullptr)
			SweeperDeathVolume.DestroyActor();

		ChimeHolder.SetActorHiddenInGame(false);
		Material::SetScalarParameterValue(WorldShaderParameters, n"MayPixelation", 0.f);
		Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal);
		StartSequenceEvent.Broadcast();
		FlashActor(Game::GetMay(), 1.f, MayEmissiveColor);
	}

	UFUNCTION()
	void MusicTechWallSequenceFinished()
	{
		ChimeCamera.ActivateCamera(Game::GetMay(), Blend, this);
		MusicTechKnobs.StopInteractingWithKnobs();
		
		Game::GetCody().TeleportActor(CodyMoveToLocation.ActorLocation, FRotator::ZeroRotator);

		FConstraintSettings LockSplineSettings;
		LockSplineSettings.SplineToLockMovementTo = CodySplineLock01.Spline;
		LockSplineSettings.ConstrainType = EConstrainCollisionHandlingType::FreeVertical;
		LockSplineSettings.bLockToEnds = true;
		Game::GetCody().StartSplineLockMovement(LockSplineSettings);
		
	}

	UFUNCTION()
	void HandleCrumb_MoveCody(const FHazeDelegateCrumbData& CrumbData)
	{
		if(!HasControl())
		{
			return;
		}
	}

	UFUNCTION()
	void StartSplineLockOnChimeEvent(AHazePlayerCharacter Player)
	{
		FConstraintSettings LockSplineSettings;
		LockSplineSettings.SplineToLockMovementTo = MaySplineLock02.Spline;
		//LockSplineSettings.bLockToEnds = true;
		
		if(Game::GetMay().HasControl())
		{
			Game::GetMay().StartSplineLockMovement(LockSplineSettings);
		}

		if(StartSplineLockOnChime != nullptr)
			StartSplineLockOnChime.DestroyActor();
	}

	UFUNCTION()
	void AfterChimeTriggerEvent(AHazePlayerCharacter Player)
	{
		// If Cody clears the Chime, switch May's lock spline so she can get off the chime
		if(Player == Game::GetCody() && !bMayEnteredTrigger)
		{
			if(Game::GetMay().HasControl())
			{
				Game::GetMay().StopSplineLockMovement();
				FConstraintSettings LockSplineSettings;
				LockSplineSettings.SplineToLockMovementTo = MaySplineLock03.Spline;
				Game::GetMay().StartSplineLockMovement(LockSplineSettings);
			}
		}
		// We can only reach this code if May has switched spline lock
		else if (Player == Game::GetMay() && !bMayEnteredTrigger)
		{
			bMayEnteredTrigger = true;
			AfterChimeCamera.ActivateCamera(Game::GetMay(), Blend, this);
			BlockingVolumeAfterChime.SetActorEnableCollision(true);
		} 
	}

	UFUNCTION()
	void OnPlayerStartedPowerSwitch(AHazePlayerCharacter Player)
	{
		Player.StopSplineLockMovement();
	}

	UFUNCTION()
	void SwitchActivated()
	{
		MusictechWallDoor01.MoveDoor();
		MusictechWallDoor02.MoveDoor();
		//Delay here... maybe?
		
		// if(Game::GetCody().HasControl())
		// {
		// 	Game::GetCody().StopSplineLockMovement();
		// }
		
		// if(Game::GetMay().HasControl())
		// {
		// 	Game::GetMay().StopSplineLockMovement();
		// }
		
		Game::GetCody().DeactivateCameraByInstigator(this);
		Game::GetMay().DeactivateCameraByInstigator(this);

		for (auto Player : Game::GetPlayers())
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Normal);

		SceneView::SetSplitScreenMode(EHazeSplitScreenMode::Vertical);
	}
}
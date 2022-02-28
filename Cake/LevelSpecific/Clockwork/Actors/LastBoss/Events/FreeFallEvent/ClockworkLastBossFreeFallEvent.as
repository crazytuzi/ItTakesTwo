import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossEventBase;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObject;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallContainVolume;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallCogWheelManager;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.FreeFallEvent.ClockworkLastBossFreeFallRewindComponent;
import Vino.Time.ActorTimeDilationStatics;

event void FPreRewindStarted();

class AClockworkLastBossFreeFallEvent : AClockworkLastBossEventBase
{
	
	UPROPERTY()
	AClockworkLastBossFreeFallContainVolume FreeFallContainVolume;
	
	UPROPERTY()
	AClockworkLastBossMovingObject PlatformToDestroy;

	UPROPERTY()
	AClockworkLastBossFreeFallCogWheelManager CogWheelManager;
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet FreeFallCapabilitySheet;

	UPROPERTY()
	AClockworkLastBossFreeFallCogWall CogWall;

	UPROPERTY()
	FPreRewindStarted PreRewindStarted;

	float AcitvateTimer = 1.f;
	float EventTimer = 35.f;

	bool bPreRewindTimerActive = false;
	float PreRewindTimer = 3.f;
	float PreRewindSlowDownTimer = 2.f;
	float PreRewindSlowDownTimerMax = 2.f;

	bool bRewindTimerActive = false;
	float RewindTimer = 5.f;

	bool bTimerActive = false;
	bool bEventTimerActive = false;

	float CurrentHeight = 0.f;
	float FallSpeed = 3500.f;
	float PreRewindFallSpeed = 0.f;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Super::Tick(DeltaTime);

		if (bEventTimerActive)
		{
			CogWheelManager.SetCurrentHeight(CurrentHeight);
			FreeFallContainVolume.SetCurrentHeight(CurrentHeight);

			if (!bPreRewindTimerActive)
			{
				CurrentHeight -= DeltaTime * FallSpeed;
				for (auto Player : Game::Players)
					Player.SetCapabilityAttributeValue(n"FallCurrentHeight", CurrentHeight);	
			}

			EventTimer -= DeltaTime;
			PrintToScreen("EventTimer: " + EventTimer);
			PrintToScreen("Cody Height: " + Game::GetCody().ActorLocation.Z);

			if (EventTimer <= 0.f)
			{
				PreRewind();
			}
			
			if (bTimerActive)
			{
				AcitvateTimer -= DeltaTime;

				if (AcitvateTimer <= 0.f)
				{
					bTimerActive = false;
					SetFreeFallContainerActive();
					SetCamShakeActive(true);
					SetCogManagerActive(true);
				}
			}
		}

		if (bPreRewindTimerActive)
		{
			PreRewindSlowDownTimer -= DeltaTime;
			PreRewindTimer -= DeltaTime;

			if (PreRewindSlowDownTimer >= 0.f)
			{
				//Lerp goes from 1 to 0
				float Lerp = FMath::Min((PreRewindSlowDownTimer / PreRewindSlowDownTimerMax), 1.f);
				PreRewindFallSpeed = FMath::Lerp(1.f, FallSpeed, Lerp);
				CurrentHeight -= DeltaTime * PreRewindFallSpeed;
				
				for (auto Player : Game::Players)
				{
					ModifyActorTimeDilation(Player, Lerp, this);	
					Player.SetCapabilityAttributeValue(n"FallCurrentHeight", CurrentHeight);
				}
			}

			if (PreRewindTimer <= 0.f)
			{
				bPreRewindTimerActive = false;
				RewindEvent();
				bEventTimerActive = false;
			}
		}
		
		if (bRewindTimerActive)
		{
			CogWheelManager.SetCurrentHeight(CurrentHeight);
			FreeFallContainVolume.SetCurrentHeight(CurrentHeight);

			CurrentHeight += DeltaTime * FallSpeed * (35.f / 5.f);

			for (auto Player : Game::Players)
				Player.SetCapabilityAttributeValue(n"FallCurrentHeight", CurrentHeight);

			RewindTimer -= DeltaTime;
			if (RewindTimer <= 0.f)
			{
				bRewindTimerActive = false;
				StopEvent02();
			}
		}	
	}

	UFUNCTION()
	void StartFreeFallEvent()
	{
		CurrentHeight = Game::GetCody().ActorLocation.Z - FallSpeed * ActorDeltaSeconds; // Need to start falling or we'll stand still for one tick
		StartedEvent.Broadcast(EventNumber);

		AddFreeFallCapability();
		SetCharacterRotationForFreeFall();
		DestroyLaunchingPlatform();
		SetCogWallVisible(true);
		ActivateFreeFallCamera();
		bTimerActive = true;
		bEventTimerActive = true;
	}

	UFUNCTION()
	void PreRewind()
	{
		bPreRewindTimerActive = true;
		PreRewindStarted.Broadcast();
		ActivateFreeFallCamera();
	}

	UFUNCTION()
	void RewindEvent()
	{		
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(AHazePlayerCharacter Player : Players)
		{
			Player.SetCapabilityActionState(n"FreeFalling", EHazeActionState::Inactive);	
			Player.SetCapabilityActionState(n"FreeFallRewind", EHazeActionState::Active);	
			ClearActorTimeDilation(Player, this);
		}

		TArray<AClockworkLastBossFreeFallCog> CogArray;
		GetAllActorsOfClass(CogArray);
		for (auto Cog : CogArray)
			Cog.SetToTargetLocation();

		TArray<AClockworkLastBossFreeFallBar> BarArray;
		GetAllActorsOfClass(BarArray);
		for (auto Bar : BarArray)
			Bar.SetToTargetLocation();

		bRewindTimerActive = true;
	}

	UFUNCTION()
	void StopEvent02()
	{
		CogWheelManager.SetManagerActive(false);
		FinishedEvent.Broadcast(EventNumber);
		
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(AHazePlayerCharacter Player : Players)
		{
			Player.RemoveAllCapabilitySheetsByInstigator(this);
		}
		
		FreeFallContainVolume.UnHideFloor();
		FreeFallContainVolume.SetShimmerActive(false);
		FreeFallContainVolume.bEnableDynamicCamera = false;
		//SetCogWallVisible(false);
		Game::GetCody().DeactivateCameraByInstigator(this);
		FreeFallContainVolume.DestroyActor();
		
	}

	UFUNCTION()
	void AddFreeFallCapability()
	{
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(AHazePlayerCharacter Player : Players)
		{
			Player.TriggerMovementTransition(this);
			Player.AddCapabilitySheet(FreeFallCapabilitySheet, Instigator = this);
			Player.SetCapabilityActionState(n"FreeFalling", EHazeActionState::Active);
			Player.SetCapabilityAttributeValue(n"FallCurrentHeight", CurrentHeight);
			UClockworkLastBossFreeFallRewindComponent::Get(Player).StartStampingTransform();
		}
	}
	
	UFUNCTION()
	void ActivateFreeFallCamera()
	{
		Game::GetCody().ActivateCamera(FreeFallContainVolume.Camera, CameraBlend::Normal(2.f), this);
	}

	UFUNCTION()
	void SetCharacterRotationForFreeFall()
	{
		FVector FreeFallForwardVec = FreeFallContainVolume.PlayerFacingDirection.GetForwardVector();
		Game::GetCody().SetActorRotation(FreeFallForwardVec.Rotation());
		Game::GetMay().SetActorRotation(FreeFallForwardVec.Rotation());
	}

	UFUNCTION()
	void DestroyLaunchingPlatform()
	{
		//PlatformToDestroy.DestroyActor();
	}

	UFUNCTION()
	void SetFreeFallContainerActive()
	{
		FreeFallContainVolume.SetFreeFallContainerActive(true);
	}

	UFUNCTION()
	void SetCamShakeActive(bool bActive)
	{
		if (bActive)
		{
			Game::GetCody().PlayCameraShake(CamShake);
		} else 
		{
			Game::GetCody().StopAllCameraShakes();
		}
	}

	UFUNCTION()
	void SetCogManagerActive(bool bActive)
	{
		CogWheelManager.SetCogBoundaries(FreeFallContainVolume.CogTopLeft, FreeFallContainVolume.CogBotRight);
		CogWheelManager.SetManagerActive(bActive);
	}

	UFUNCTION()
	void SetCogWallVisible(bool bNewVisible)
	{
		CogWall.SetCogWallVisible(bNewVisible);
	}
}
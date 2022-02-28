import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Clockwork.Windup.WindupKeyActor;
import Cake.LevelSpecific.Clockwork.VOBanks.ClockworkClockTowerLowerVOBank;

class AHopscotchWindupKey : AWindupKeyActor
{
	UPROPERTY()
	bool ClampCamera = true;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	float BlendTime = 2.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnActivatedEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnTurnEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnStopTurnEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnStopTurnLockedEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnTurnCompletedEvent;

	UPROPERTY()
	UClockworkClockTowerLowerVOBank VOBank;


	private FHazeAudioEventInstance TurningEventInstance;
	private float LastWindupPercentageRtpcValue = -1.f;
	private float LastWindupPercentage = -1.f;

	private float LastTurningDelta = 0.f;
	private float LastBlockedRtpcValue = 1.f;

	private bool bHasPlayedMovementBlocked = false;
	private bool bHasPlayedAudioHitLock = false;
	private bool bHasPlayedFullyTurned = false;

	private float WrongWayBarkDelayTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();	
		
		OnLockHit.AddUFunction(this, n"AudioHitLock");
		AudioOnWindupFinishedEvent.AddUFunction(this, n"AudioTurnFinished");
	}
	
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player) override
    {
		Super::OnInteractionActivated(Component, Player);
		ApplyCamera(Player);
    }

	protected void OnSingleInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player) override
	{
		Super::OnSingleInteractionActivated(Component, Player);
		ApplyCamera(Player);
	}

	protected void ApplyCamera(AHazePlayerCharacter Player)
	{
		if(ClampCamera)
		{
			FHazeCameraClampSettings ClampSettings;
			ClampSettings.ClampPitchDown = 0.f;
			ClampSettings.bUseClampPitchDown = true;
			ClampSettings.ClampPitchUp = 0.f;
			ClampSettings.bUseClampPitchUp = true;
			ClampSettings.ClampYawLeft = 0.f;
			ClampSettings.bUseClampYawLeft = true;
			ClampSettings.ClampYawRight = 0.f;
			ClampSettings.bUseClampYawRight = true;
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = BlendTime;
			Player.ApplyCameraClampSettings(ClampSettings, Blend, this);
		}

		if(CameraSettings != nullptr)
		{
			FHazeCameraBlendSettings BlendSettings;
			BlendSettings.BlendTime = BlendTime;
			Player.ApplyCameraSettings(CameraSettings, BlendSettings, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		if(CurrentWindupPercentage != LastWindupPercentageRtpcValue)
		{
			if(!bWasFinishedLastFrame)
			{
				HazeAkComp.SetRTPCValue(HazeAudio::RTPC::WindupKeyTurnPercentage, CurrentWindupPercentage);
				HazeAkComp.SetRTPCValue(HazeAudio::RTPC::WindupKeyTurnDelta, 1.f, 700.f);
			}

			LastWindupPercentageRtpcValue = CurrentWindupPercentage;
			LastTurningDelta = 1.f;
		}
		else if(LastTurningDelta != 0.f && CurrentWindupPercentage != 1)
		{
			LastTurningDelta = 0.f;
			HazeAkComp.SetRTPCValue(HazeAudio::RTPC::WindupKeyTurnDelta, LastTurningDelta);
		}	

		EHazePlayer CorrectPlayer = EHazePlayer::MAX;
		EHazePlayer WrongPlayer = EHazePlayer::MAX;
		if(PlayersAreWindingInTheOppositeDirection(CorrectPlayer, WrongPlayer))
		{
			if(VOBank != nullptr)
			{
				WrongWayBarkDelayTime += DeltaSeconds;
				if(WrongWayBarkDelayTime >= 0.75f)
				{
					if(WrongPlayer == EHazePlayer::Cody)
						PlayFoghornVOBankEvent(VOBank, n"FoghornDBClockworkLowerTowerDoubleInteractHintMay");
					else
						PlayFoghornVOBankEvent(VOBank, n"FoghornDBClockworkLowerTowerDoubleInteractHintCody");
				}
			}
		}
		else
		{
			WrongWayBarkDelayTime = 0;
		}

		if(PlayersAreWinding()) 
		{
			if(!HazeAkComp.EventInstanceIsPlaying(TurningEventInstance) && CurrentWindupPercentage != LastWindupPercentage)
			{
				TurningEventInstance = HazeAkComp.HazePostEvent(OnTurnEvent);
			}

			if(CurrentWindupPercentage == LastWindupPercentage && CurrentWindupPercentage != 1)			
			{
				if(!bHasPlayedMovementBlocked)
				{
					HazeAkComp.HazePostEvent(OnStopTurnEvent);
					bHasPlayedMovementBlocked = true;
				}				
			}
			else
			{
				bHasPlayedMovementBlocked = false;
				bHasPlayedAudioHitLock = false;
			}
		}
		else
		{ 
			if(HazeAkComp.EventInstanceIsPlaying(TurningEventInstance))
			{
				HazeAkComp.HazePostEvent(OnStopTurnEvent);
				HazeAkComp.HazePostEvent(OnStopTurnLockedEvent);
			}
		}

		if(!bLockWhenFinished)
		{
			if(bHasPlayedFullyTurned && CurrentWindupPercentage < 1)
				bHasPlayedFullyTurned = false;
		}
		
		LastWindupPercentage = CurrentWindupPercentage;
	}

	void DeactivatePlayerInteracting(AHazePlayerCharacter Player)
	{
		Super::DeactivatePlayerInteracting(Player);
		if (Player != nullptr)
		{
			Player.ClearCameraClampSettingsByInstigator(this, BlendTime);
			if(CameraSettings != nullptr)
			{
				Player.ClearCameraSettingsByInstigator(this, BlendTime);
			}
		}			
	}

	UFUNCTION()
	void OnKeyInserted(UHazeTriggerComponent Component, AHazePlayerCharacter PlayerCharacter)
	{
		Super::OnKeyInserted(Component, PlayerCharacter);
		HazeAkComp.HazePostEvent(OnActivatedEvent);
	}

	UFUNCTION()
	void AudioHitLock(AWindupActor WindupActor, FName LockName)
	{		
		if(!bHasPlayedAudioHitLock)
		{
			HazeAkComp.HazePostEvent(OnStopTurnEvent);
			bHasPlayedAudioHitLock = true;
		}	
	}

	UFUNCTION()
	void AudioTurnFinished(AWindupActor WindupActor)
	{
		if(bHasPlayedFullyTurned)
			return;

		HazeAkComp.HazePostEvent(OnTurnCompletedEvent);
		bHasPlayedFullyTurned = true;
	}

	bool PlayersAreWinding() const
	{
		if(PlayerData.Num() < 2)
			return false;

		return PlayerData[0].CurrentWindInput != EWindupInputActorDirection::None && PlayerData[1].CurrentWindInput == PlayerData[0].CurrentWindInput;
	}

	bool PlayersAreWindingInTheOppositeDirection(EHazePlayer& OutCorrectTurningPlayer, EHazePlayer& OutWrongTurningPlayer) const
	{
		if(PlayerData.Num() < 2)
			return false;

		if(PlayerData[0].CurrentWindInput == EWindupInputActorDirection::None
			|| !PlayerData[0].bIsInteracting)
			return false;

		if(PlayerData[1].CurrentWindInput == EWindupInputActorDirection::None
			|| !PlayerData[1].bIsInteracting)
			return false;

		if(PlayerData[0].CurrentWindInput == PlayerData[1].CurrentWindInput)
			return false;
		
		if(PlayerData[0].CurrentWindInput != EWindupInputActorDirection::Forward)
		{
			OutCorrectTurningPlayer = PlayerData[0].Player;
			OutWrongTurningPlayer = PlayerData[1].Player;
		}	
		else
		{
			OutCorrectTurningPlayer = PlayerData[1].Player;
			OutWrongTurningPlayer = PlayerData[0].Player;
		}

		return true;
	}
}
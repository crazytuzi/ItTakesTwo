
import Vino.Interactions.InteractionComponent;
import Peanuts.Triggers.PlayerTrigger;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FOnChangeSpeedUp(AHazePlayerCharacter Player);
class AVinylPlayer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent RotatingRoot;
	UPROPERTY(DefaultComponent, Attach = RotatingRoot)	
	UStaticMeshComponent RotatingMesh;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	USceneComponent RotatingRootNeedle;
	UPROPERTY(DefaultComponent, Attach = RotatingRoot)	
	UStaticMeshComponent RotatingMeshNeedle;

	UPROPERTY()
	FOnChangeSpeedUp OnChangeSpeedUp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	AHazeInteractionActor SpeedParamInteraction;
	UPROPERTY()
	AHazeInteractionActor StartButton;
	UPROPERTY()
	APlayerTrigger AreaTrigger;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartVinylPlayerMusicAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopVinylPlayerMusicAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartStopButtonAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RPMButtonAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpOffPickupAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JumpOnPickupAudioEvent;

	FHazeAcceleratedFloat AcceleratedFloat;
	float TargetRotationSpeed;
	FHazeAcceleratedFloat AcceleratedFloatNeedle;
	float TargetFloatNeedle = 1.f;


	UPROPERTY()
	float SpeedParam = 33.f;
	UPROPERTY()
	float RTPCStandingOnNeedle = 1.f;

	bool VinylPlayerActive;
	bool bRotationAllowed = false;
	UPROPERTY()
	float AutoDisableTimer = 30.f;
	float AutoDisableTimerTemp = 30.f;

	bool bPlayersInsideVinylArea = false;
	int PlayerInt = 0;
	int PlayerIntOnNeedle = 0;
	bool bPlayerOnNeedle = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AreaTrigger.OnPlayerEnter.AddUFunction(this, n"AddPlayer");
		AreaTrigger.OnPlayerLeave.AddUFunction(this, n"RemovePlayer");
		AcceleratedFloatNeedle.Value = 1;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds) 
	{
	//	PrintToScreen("AutoDisableTimerTemp "+ AutoDisableTimerTemp);
	//	PrintToScreen("bPlayerOnNeedle "+ bPlayerOnNeedle);
	//	PrintToScreen("PlayerIntOnNeedle " + PlayerIntOnNeedle);

		AcceleratedFloatNeedle.SpringTo(TargetFloatNeedle, 100, 1.0, DeltaSeconds);
		RTPCStandingOnNeedle = AcceleratedFloatNeedle.Value;
		RTPCStandingOnNeedle = FMath::GetMappedRangeValueClamped(FVector2D(0.05f,0.95f), FVector2D(0.f,1.f), RTPCStandingOnNeedle);

		//PrintToScreen("RTPCStandingOnNeedle " + RTPCStandingOnNeedle);

		if(VinylPlayerActive)
		{
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_VinylPlayer_Speed", SpeedParam);
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_VinylPlayer_Pause", RTPCStandingOnNeedle);

			if(SpeedParam == 33)
				TargetRotationSpeed = 70;
			if(SpeedParam == 45)
				TargetRotationSpeed = 130;

			if(bPlayersInsideVinylArea == false)
			{
				AutoDisableTimerTemp -= DeltaSeconds;
				if(AutoDisableTimerTemp <0)
				{
					if(HasControl())
					{
						ButtonAutoDisable();
					}
				}
			}
		}

		if(bRotationAllowed)
		{
			if(bPlayerOnNeedle == false)
			{
				AcceleratedFloat.SpringTo(TargetRotationSpeed, 30, 0.9, DeltaSeconds);
			}
			else
			{
				AcceleratedFloat.SpringTo(0, 30, 0.9, DeltaSeconds);
			}

			RotatingRoot.AddLocalRotation(FRotator(0, AcceleratedFloat.Value * DeltaSeconds, 0));
		}
	}

	UFUNCTION(NetFunction)
	void ButtonAutoDisable()
	{
		ButtonPressed();
	}

	UFUNCTION()
	void ButtonPressed()
	{
		if(VinylPlayerActive == false)
		{
			AutoDisableTimerTemp = AutoDisableTimer;
			bRotationAllowed = true;
			AcceleratedFloat.Value = 0;
			SpeedParam = 33;
			VinylPlayerActive = true;
			HazeAkComp.HazePostEvent(StartVinylPlayerMusicAudioEvent);
			HazeAkComp.HazePostEvent(StartStopButtonAudioEvent);
			SpeedParamInteraction.EnableInteraction(n"StartDisabled");
			//StartButton.DisableInteraction(n"StartDisabled");
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_VinylPlayer_Off", 0.f);
		}
		else if(VinylPlayerActive == true)
		{
			VinylPlayerActive = false;
			TargetRotationSpeed = 0;
			System::SetTimer(this, n"DisableRotation", 0.5f, false);
			HazeAkComp.HazePostEvent(StopVinylPlayerMusicAudioEvent);
			HazeAkComp.HazePostEvent(StartStopButtonAudioEvent);
			//StartButton.EnableInteraction(n"StartDisabled");
			SpeedParamInteraction.DisableInteraction(n"StartDisabled");
			HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_Interactions_VinylPlayer_Off", 1.f, 500);
		}
	}
	UFUNCTION()
	void DisableRotation()
	{
		if(VinylPlayerActive)
			return;

		bRotationAllowed = false;
	}

	UFUNCTION()
	void ChangeSpeedParam(AHazePlayerCharacter Player)
	{
		if(SpeedParam == 33)
		{
			OnChangeSpeedUp.Broadcast(Player);
			SpeedParam = 45;
		}
		else if(SpeedParam == 45)
		{
			SpeedParam = 33;
		}

		HazeAkComp.HazePostEvent(RPMButtonAudioEvent);
	}


	UFUNCTION()
	void AddPlayer(AHazePlayerCharacter Player)
	{
		PlayerInt ++;
		AutoDisableTimerTemp = AutoDisableTimer;
		bPlayersInsideVinylArea = true;
	}
	UFUNCTION()
	void RemovePlayer(AHazePlayerCharacter Player)
	{
		PlayerInt --;
		if(PlayerInt == 0)
		{
			bPlayersInsideVinylArea = false;
		}
	}

	UFUNCTION()
	void AddPlayerNeedle(AHazePlayerCharacter Player)
	{
		if(PlayerIntOnNeedle < 2)
			PlayerIntOnNeedle ++;

		if(bPlayerOnNeedle == false)
		{
			if(Player.HasControl())
			{
				StartSound();
			}
			else
			{
				NetRequestSound();
			}
		}

		bPlayerOnNeedle = true;
		TargetFloatNeedle = 0;
	}
	UFUNCTION()
	void RemovePlayerNeedle()
	{
		if(PlayerIntOnNeedle > 0)
			PlayerIntOnNeedle --;

		if(PlayerIntOnNeedle == 0)
		{
			bPlayerOnNeedle = false;
			TargetFloatNeedle = 1;

			if(!VinylPlayerActive)
				return;

			HazeAkComp.HazePostEvent(JumpOffPickupAudioEvent);
		}
	}


	UFUNCTION()
	void StartSound()
	{
		if(HasControl())
		{
			NetPlayAudioScatchSound();
		}
	}

	void NetRequestSound()
	{
		if(!HasControl())
			return;
		if(bPlayerOnNeedle == false)
			NetPlayAudioScatchSound();
	}

	UFUNCTION(NetFunction)
	void NetPlayAudioScatchSound()
	{
		if(!VinylPlayerActive)
			return;

		HazeAkComp.HazePostEvent(JumpOnPickupAudioEvent);
	}
}


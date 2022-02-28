import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingActor;

/*
	Remove Hackedness bar from failed screen.
	change barprogress fill curve to be exponential
	Lerp Increase in speed/ScrollSpeed based on baboon eventprogress.
*/

//
class UTVCounterHackCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ATVHackingActor TVActor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CounterHackStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CounterHackStopAudioEvent;
	
	//This is the progress bar progress.
	float HackProgress = 0.75f;
	float HackLossSpeed = 0.04f;
	UPROPERTY(Category = "Settings")
	float HackLossSpeedLevel1 = 0.125f;
	UPROPERTY(Category = "Settings")
	float HackLossSpeedLevel2 = 0.14f;
	UPROPERTY(Category = "Settings")
	float HackLossSpeedLevel3 = 0.16f;
	UPROPERTY(Category = "Settings")
	float HackLossSpeedLevel4 = 0.2f;

	float CurrentMashMultiplier = 0.2f;
	float Level2MashMultiplier = 0.15f;
	float Level3MashMultipler = 0.10f;

	UPROPERTY(Category = "VO Settings")
	float CounterHackVODelay = 1.f;
	float CounterHackVoTimer = 0.f;
	bool bCounterHackVOTriggered = false;

	float CurrentTime = 0.f;
	float CurrentTimer = 3.f;
	float EventTimeLevel2 = 7.f;
	float EventTimeLevel3 = 12.f;
	
	bool bLastLevelReached = false;
	bool EventCurrentlyTriggering = false;

	float PlayerHackMultiplier = 0.20f;
	bool bCounterHackCompleted = false;
	int MaterialIndexToUse = 1;

	bool bVOEventHasPlayed = false;

	ECounterHackStates CurrentState = ECounterHackStates::Level1;

	UPROPERTY(Category = "Setup")
	FHazeTimeLike EventLevel2TimeLike;
	UPROPERTY(Category = "Setup")
	FHazeTimeLike EventLevel3TimeLike;
	UPROPERTY(Category = "Setup")
	FHazeTimeLike EventLevel4TimeLike;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TVActor = Cast<ATVHackingActor>(Owner);

		EventLevel2TimeLike.BindUpdate(this, n"OnEventLevel2Update");
		EventLevel3TimeLike.BindUpdate(this, n"OnEventLevel3Update");
		EventLevel4TimeLike.BindUpdate(this, n"OnEventLevel4Update");

		EventLevel2TimeLike.BindFinished(this, n"OnEventFinished");
		EventLevel3TimeLike.BindFinished(this, n"OnEventFinished");
		EventLevel4TimeLike.BindFinished(this, n"OnEventFinished");
		
		if(HasControl())
		{

		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TVActor.TVState == ETVStateEnum::CounterHack)
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TVActor.TVState != ETVStateEnum::CounterHack)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TVActor.HazeAkComp.HazePostEvent(CounterHackStartAudioEvent);
		
		SetScalarParam(n"Hackedness", HackProgress);
		HackLossSpeed = HackLossSpeedLevel1;
		SetScalarParam(n"HackingSpeed", HackLossSpeed);

		if(HasControl())
		{
			TVActor.SwitchInputEnabled(true);
			TVActor.HackProgressSynchedFloat.Value = HackProgress;
		}
		
		TVActor.ActivateButtonMash();
		TVActor.ActivateCounterHackCamera();
		TVActor.SwitchToCounterhackLightColor();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TVActor.HazeAkComp.HazePostEvent(CounterHackStopAudioEvent);
		
		TVActor.SwitchInputEnabled(false);
		TVActor.DeactivateButtonMash();
		ResetState();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			//Game is still running, calculate current Progress
			if(HackProgress > 0 && !bCounterHackCompleted)
			{
				HackProgress -= HackLossSpeed * DeltaTime;
				HackProgress += CalculateButtonMash(DeltaTime);

				if(HackProgress > 0.9f)
				{
					PlayerHackMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(0.9, 0.99f), FVector2D(CurrentMashMultiplier, 0.f), HackProgress);
				}
				else if(PlayerHackMultiplier != CurrentMashMultiplier)
				{
					PlayerHackMultiplier = CurrentMashMultiplier;
				}

				TVActor.HackProgressSynchedFloat.Value = HackProgress;

				VerifyTimedEvent(DeltaTime);

				if(!EventCurrentlyTriggering)
				{
					//Countdown to trigger CounterHack Reaction VO
					if(!bVOEventHasPlayed && CounterHackVoTimer >= CounterHackVODelay)
					{
						TVActor.TriggerCounterhackDialogue();
						bVOEventHasPlayed = true;
					}
					else
						CounterHackVoTimer += DeltaTime;
				}
			}
			//Players "Lost", broadcast event to level BP.
			else if(HackProgress <= 0)
			{
				NetSetHackedness(0.f);
				TriggerCompletion();
			}
		}
		else
		{
			HackProgress = FMath::FInterpConstantTo(HackProgress, TVActor.HackProgressSynchedFloat.Value, DeltaTime, 0.5f);
		}

		TVActor.HazeAkComp.SetRTPCValue("Rtpc_World_Playroom_Pillowfort_Interactable_TVHacking_CounterHack_Progress", HackProgress);
		SetHackProgress(HackProgress);

		if(!bCounterHackCompleted)
			TVActor.ApplyForceFeedback(0.4f);

		//Players have reached final difficulty, keep ramping speed loss.
		if(bLastLevelReached)
		{
			HackLossSpeed += (0.025f * DeltaTime);
			SetScalarParam(n"HackingSpeed", HackLossSpeed);
		}
	}

	float CalculateButtonMash(float DeltaTime)
	{
		float P1Rate = TVActor.Player1ButtonMashRate;
		float P2Rate = TVActor.Player2ButtonMashRate;

		return (P1Rate + P2Rate) * PlayerHackMultiplier * DeltaTime;
	}

	UFUNCTION(NetFunction)
	void TriggerCompletion()
	{
		bCounterHackCompleted = true;
		TVActor.ChangeState(ETVStateEnum::GameFailed);
		TVActor.DeactivateCounterHackCamera();
		TVActor.CompleteGame();
	}

	void VerifyTimedEvent(float DeltaTime)
	{
		if(bLastLevelReached)
			return;

		CurrentTime += DeltaTime;

		if(CurrentTime >= CurrentTimer && !EventCurrentlyTriggering)
		{
			TriggerEvent();
		}
	}

	void ForceTriggerEvent()
	{
		TriggerEvent();
		CurrentTime = CurrentTimer;
	}

	//Triggers moonbaboon appearance, difficulty changes of buttonmash.
	UFUNCTION(NetFunction)
	void TriggerEvent()
	{
		//Trigger Start MoonBaboon Sound
		TVActor.HazeAkComp.SetRTPCValue("Rtpc_World_Playroom_Pillowfort_Interactable_TVHacking_CounterHack_MoonBaboon", 1.f);

		if(TVActor != nullptr)
			TVActor.ShakeCounterHackCamera(CurrentState);
		
		EventCurrentlyTriggering = true;

		switch(CurrentState)
		{
			case(ECounterHackStates::Level1):
				EventLevel2TimeLike.Play();
				break;

			case(ECounterHackStates::Level2):
				EventLevel3TimeLike.Play();
				break;

			case(ECounterHackStates::Level3):
				EventLevel4TimeLike.Play();
				break;
			
			default:
				break;
		}
	}

	UFUNCTION(NetFunction)
	void ChangeHackSpeed()
	{
		switch(CurrentState)
		{
			case(ECounterHackStates::Level1):
				HackLossSpeed = HackLossSpeedLevel2;
				CurrentState = ECounterHackStates::Level2;
				CurrentMashMultiplier = Level2MashMultiplier;
				CurrentTimer = EventTimeLevel2;
				SetScalarParam(n"HackingSpeed", HackLossSpeed);
				break;
			case(ECounterHackStates::Level2):
				HackLossSpeed = HackLossSpeedLevel3;
				CurrentState = ECounterHackStates::Level3;
				CurrentMashMultiplier = Level3MashMultipler;
				CurrentTimer = EventTimeLevel3;
				SetScalarParam(n"HackingSpeed", HackLossSpeed);

				if(HasControl())
					TVActor.TriggerCounterHackExertDialogue();
				
				break;
			case(ECounterHackStates::Level3):
				HackLossSpeed = HackLossSpeedLevel4;
				CurrentState = ECounterHackStates::Level4;
				bLastLevelReached = true;
				SetScalarParam(n"HackingSpeed", HackLossSpeed);
				break;
			default:
				break;
		}

		PlayerHackMultiplier = CurrentMashMultiplier;
	}

	UFUNCTION()
	void OnEventLevel2Update(float Value)
	{
		SetScalarParam(n"ShowBaboon", Value);
	}

	UFUNCTION()
	void OnEventLevel3Update(float Value)
	{
		SetScalarParam(n"ShowBaboon", Value);
	}

	UFUNCTION()
	void OnEventLevel4Update(float Value)
	{
		SetScalarParam(n"ShowBaboon", Value);
	}

	UFUNCTION()
	void OnEventFinished()
	{
		if(HasControl())
			ChangeHackSpeed();

		//Stop MoonBaboon Sound
		TVActor.HazeAkComp.SetRTPCValue("Rtpc_World_Playroom_Pillowfort_Interactable_TVHacking_CounterHack_MoonBaboon", 0.f);

		EventCurrentlyTriggering = false;

/* 		if(TVActor != nullptr)
			TVActor.ShakeCounterHackCamera(CurrentState); */
	}

	void ResetState()
	{
		HackProgress = 1.f;
		SetScalarParam(n"Hackedness", 1.f);
	}

	void SetHackProgress(float Value)
	{
		SetScalarParam(n"Hackedness", Value);
	}

	UFUNCTION(NetFunction)
	void NetSetHackedness(float Value)
	{
		SetScalarParam(n"Hackedness", Value);
	}

	void SetScalarParam(FName ParamName, float Value)
	{
		TVActor.BaseMesh.SetScalarParameterValueOnMaterialIndex(MaterialIndexToUse, ParamName, Value);
	}
}
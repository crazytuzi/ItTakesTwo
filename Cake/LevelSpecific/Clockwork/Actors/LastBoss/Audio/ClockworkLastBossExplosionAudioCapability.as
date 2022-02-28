import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossCodyExplosionComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.Audio.CharacterTimeControlAudioComponent;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionActorBase;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionDebris;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionDebrisAudioComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionAudioStatics;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionFX;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionFXAudioComponent;

class UClockworkLastBossExplosionAudioCapability : UHazeCapability
{
	AHazePlayerCharacter Player; 
	UClockworkLastBossCodyExplosionComponent ExplosionComp;			
	UTimeControlActorComponent ExplosionActorTimeControlComp;
	UClockworkLastBossExplosionAudioManager ExplosionAudioManager;
	UCharacterTimeControlAudioComponent AudioTimeComp;

	private float LastTimeValue = 0.f;
	private float LastDeltaTimeValue = 0.f;
	private float LastManipulationDeltaValue = 0.f;
	private float LastActiveManipulation = 0.f;

	private bool bSequenceFinished = false;

	UPROPERTY(Category = "Sequence Loops")
	UAkAudioEvent StartExplosionSequenceLoopingEvent;	

	UPROPERTY(Category = "Sequence Loops")
	UAkAudioEvent StopExplosionSequenceLoopingEvent;	

	UPROPERTY(Category = "Transition Events")
	UAkAudioEvent PrepareFinalExplosionEvent;

	UPROPERTY(Category = "Transition Events")
	UAkAudioEvent StartFinalExplosionEvent;	 

	UPROPERTY(Category = "Transition Events")
	UAkAudioEvent PrepareSprintToCoupleEvent;

	UPROPERTY(Category = "Transition Events")
	UAkAudioEvent StartSprintToCoupleEvent;

	private bool bExplosionStarted = false;
	private FHazeAudioEventInstance SequenceEventInstance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ExplosionComp = UClockworkLastBossCodyExplosionComponent::Get(Player);	
		AudioTimeComp = UCharacterTimeControlAudioComponent::Get(Player);
		ExplosionAudioManager = GetExplosionsAudioManagerComp();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Player == nullptr || !Player.IsCody())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		SequenceEventInstance = Player.PlayerHazeAkComp.HazePostEvent(StartExplosionSequenceLoopingEvent);
		Player.BlockCapabilities(n"CharacterTimeControlAudio", this);

		//VO Slowmo RTPC
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Clockwork_UpperTower_SlowMo", 1.f);	
		//PrintToScreenScaled("IsSlowMo", 5.f);

		AudioTimeComp.StartManipulationForwards();

		bSequenceFinished = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bSequenceFinished)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(Player.PlayerHazeAkComp.EventInstanceIsPlaying(SequenceEventInstance))
		{
			Player.PlayerHazeAkComp.HazePostEvent(StopExplosionSequenceLoopingEvent);
			AudioTimeComp.EndTimeControl();
		}					

		ExplosionAudioManager.DestroyComponent(ExplosionAudioManager);
		UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Clockwork_UpperTower_SlowMo", 0.f);
		Player.UnblockCapabilities(n"CharacterTimeControlAudio", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Check if we need to consume transitions into the next explosion-section
		QueryTransitions();

		// Query progression index from debris platforms
		QueryDebrisProgression();

		// Update current time in timeline
		float RawCurrentTime = 0.f;
		if(ConsumeAttribute(n"AudioCurrentTime", RawCurrentTime))
		{			
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_TimeControl_ClockworkLastBoss_Manipulation_Value", RawCurrentTime);
			ExplosionAudioManager.SetCurrentTimeForAudioObjects(RawCurrentTime);			
		}

		const float CurrentTime = RawCurrentTime;
		const float ManipulationDeltaValue = GetCurrentManipulationValue(CurrentTime);					

		if(ManipulationDeltaValue != LastManipulationDeltaValue)
		{
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_TimeControl_ClockworkLastBoss_ManipulationDelta_Value", ManipulationDeltaValue);
			LastManipulationDeltaValue = ManipulationDeltaValue;
		}		

		// Check if components from debris need to start playing sound
		if(bExplosionStarted)
			QueryRegisteredAudioObjects(CurrentTime);	

		LastTimeValue = CurrentTime;
		LastDeltaTimeValue = DeltaSeconds;		

		if(ConsumeAction(n"AudioSprintToCoupleFinished") == EActionStateStatus::Active)
		{		
			bSequenceFinished = true;
		}
	}

	float GetCurrentManipulationValue(const float& CurrentTime)
	{
		float ManipValue;

		if(IsActivelyManipulating())
		{
			if(CurrentTime > LastTimeValue)
				ManipValue = 1.f;
			else if(CurrentTime < LastTimeValue)
				ManipValue = -1.f;
		}
		else
			ManipValue = 0.f;

		return ManipValue;		
	}

	bool IsActivelyManipulating()
	{		
		if(ExplosionActorTimeControlComp == nullptr)
			return false;

		return ExplosionActorTimeControlComp.GetCurrentPlayerActionEnum() != ETimeControlPlayerAction::HoldTime;
	}

	void GetNewExplosionActor(const AClockworkLastBossExplosionActorBase NewExplosionActor)
	{		
		ExplosionActorTimeControlComp = UTimeControlActorComponent::Get(NewExplosionActor);
	}

	void QueryTransitions()
	{
		// Handle transition into Explosion
		if(ConsumeAction(n"AudioStartExplosion") == EActionStateStatus::Active)
		{
			ExplosionAudioManager.OnExplosionStarted();
			bExplosionStarted  = true;
		}

		// Handle transition to Final Explosion
		if(ConsumeAction(n"AudioPrepareFinalExplosion") == EActionStateStatus::Active)
		{
			//AudioTimeComp.EndTimeControl();
			Player.PlayerHazeAkComp.HazePostEvent(PrepareFinalExplosionEvent);
		}

		if(ConsumeAction(n"AudioStartFinalExplosion") == EActionStateStatus::Active)
		{
			Player.PlayerHazeAkComp.HazePostEvent(StartFinalExplosionEvent);			
		}

		// Handle transition to Sprint to Couple
		if(ConsumeAction(n"AudioPrepareSprintToCouple") == EActionStateStatus::Active)
		{
			AudioTimeComp.EndTimeControl();
			Player.PlayerHazeAkComp.HazePostEvent(PrepareSprintToCoupleEvent);
			//VO Slowmo RTPC
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_Clockwork_UpperTower_SlowMo", 0.f);	
			//PrintToScreenScaled("NOSlowMo", 5.f);
		}

		if(ConsumeAction(n"AudioStartSprintToCouple") == EActionStateStatus::Active)
		{
			Player.PlayerHazeAkComp.HazePostEvent(StartSprintToCoupleEvent);
		}

		UObject RawExplosionActor;
		if(ConsumeAttribute(n"AudioExplosionActor", RawExplosionActor))
		{
			const AClockworkLastBossExplosionActorBase NewExplosionActor = Cast<AClockworkLastBossExplosionActorBase>(RawExplosionActor);
			// We've received a new explosion actor to read timeline data from, update references
			if(NewExplosionActor != nullptr)
				GetNewExplosionActor(NewExplosionActor);
		}
	}

	void QueryDebrisProgression()
	{
		UObject RawObject;
		if(ConsumeAttribute(n"AudioDebrisProgression", RawObject))
		{
			AClockworkLastBossExplosionDebris Debris = Cast<AClockworkLastBossExplosionDebris>(RawObject);
			UHazeAkComponent DebrisHazeAkComp = UHazeAkComponent::Get(Debris);

			if(DebrisHazeAkComp != nullptr)
				DebrisHazeAkComp.SetRTPCValue("Rtpc_Clockwork_LastBoss_Explosion_Debris_Progression", Debris.DebrisProgressionIndex);						
		}
	}

	void QueryRegisteredAudioObjects(const float& CurrentTime)
	{
		for(auto AudioComp : ExplosionAudioManager.DebrisComps)
		{			
			for(FClockworkExplosionTimelineSound& TimelineSound : AudioComp.TimelineSounds)
				CheckShouldTriggerTimelineSound(TimelineSound, CurrentTime);			
		}
	}

	void CheckShouldTriggerTimelineSound(FClockworkExplosionTimelineSound& TimelineSound, const float& CurrentTimeValue)
	{
		// Timeline sound triggered from forwards progression
		if(CurrentTimeValue >= TimelineSound.ForwardTimelinePos && LastTimeValue < TimelineSound.ForwardTimelinePos)
			TimelineSound.HazeAkComp.HazePostEvent(TimelineSound.ForwardsEvent);
		
		// Timeline sound triggered from reverse progression
		else if(CurrentTimeValue <= TimelineSound.ReverseTimelinePos && LastTimeValue > TimelineSound.ReverseTimelinePos)
			TimelineSound.HazeAkComp.HazePostEvent(TimelineSound.ReverseEvent);
	}
}
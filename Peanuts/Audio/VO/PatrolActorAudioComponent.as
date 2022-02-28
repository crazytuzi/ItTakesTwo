import void RegisterPatrolAudioComp(UPatrolActorAudioComponent) from "Peanuts.Audio.VO.PatrolActorAudioManagerComponent"; 
import void UnregisterPatrolAudioComp(UPatrolActorAudioComponent) from "Peanuts.Audio.VO.PatrolActorAudioManagerComponent"; 

import Peanuts.Audio.AudioStatics;
import Peanuts.Audio.VO.PatrolAudioStatics;

class UPatrolActorAudioComponent : UActorComponent
{
	FHazeAudioEventInstance MovementEventInstance;
	FHazeAudioEventInstance PatrolIdleEventInstance;
	UHazeAkComponent PatrolActorHazeAkComp;

	UAkAudioEvent IdleEvent;
	UAkAudioEvent OnInterruptedEvent;
	UAkAudioEvent OnPerformDeathEvent;

	float TimeSincePlaying = 0.f;

	bool bCanTrigger = false;
	bool bPendingTrigger = false;
	bool bPendingStop = false;
	bool bIsPlaying = false;
	bool bTriggerIsBlocked = false;
	bool bIsRegistered = false;

	float TriggerTime;
	float StopTime;
	float ActiveTime;

	FVector LastLocation;
	float LastMovementSpeed;

	UPROPERTY()
	UAkAudioEvent MovementEvent;

	UPROPERTY()
	UAkAudioEvent OnTackledEvent;

	UPROPERTY()
	FPatrolAudioEvents OverridePatrolEvents;

	UPROPERTY()
	EPatrolAudioActorType PatrolActorType = EPatrolAudioActorType::None;

	UPROPERTY()
	const float MinTriggerTime = 0.5f;

	UPROPERTY()
	const float MaxTriggerTime = 10.f;
	
	UPROPERTY()
	const float MinActiveTime = 0.5f;

	UPROPERTY()
	const float MaxActiveTime = 5.f;

	UPROPERTY()
	const float PitchOffset = 0.f;

	UPROPERTY()
	const float MaxMovementSpeed = 15.f;

	UPROPERTY()
	bool bAutoRegister = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PatrolActorHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);

		if(bAutoRegister)
			RegisterPatrolAudioComp(this);

		if (PatrolActorHazeAkComp.bIsEnabled && PitchOffset != 0)
			PatrolActorHazeAkComp.SetRTPCValue("Rtpc_VO_Design_Reaction_Barks_Pitch_Offset", PitchOffset);
	}

	void UpdateCanTrigger(bool bIsActive)
	{
		if(!bIsActive)
		{
			if(bIsPlaying)
			{	
				// If Idle VO is playing, stop it
				PatrolActorHazeAkComp.HazeStopEvent(PatrolIdleEventInstance.PlayingID);
				bIsPlaying = false;			 
			}

			// Stop movement event
			PatrolActorHazeAkComp.HazeStopEvent(MovementEventInstance.PlayingID, 100.f);
		}
		// If we were flipped from not triggering to triggering, start movement event 
		else if(!bCanTrigger)
		{
			MovementEventInstance = PatrolActorHazeAkComp.HazePostEvent(MovementEvent, PostEventType = EHazeAudioPostEventType::LocalOrRandom);
		}

		bCanTrigger = bIsActive;
	}

	bool CheckVOIsActive()
	{
		const bool bIsActive = PatrolActorHazeAkComp.EventInstanceIsPlaying(PatrolIdleEventInstance);
		if(!bIsActive && bPendingStop)	
		{
			bPendingStop = false;
			return false;
		}

		return bIsActive;
	}

	bool HasListenerInRange()
	{
		float DistanceRange;
		if(IdleEvent != nullptr)
		{
			DistanceRange = MovementEvent != nullptr ? 
			FMath::Max(IdleEvent.HazeMaxAttenuationRadius, MovementEvent.HazeMaxAttenuationRadius) : IdleEvent.HazeMaxAttenuationRadius;
		}
		else if(MovementEvent != nullptr)
		{
			DistanceRange = IdleEvent != nullptr ? 
			FMath::Max(IdleEvent.HazeMaxAttenuationRadius, MovementEvent.HazeMaxAttenuationRadius) : MovementEvent.HazeMaxAttenuationRadius;
		}

		return DistanceRange > 0 && PatrolActorHazeAkComp.AnyListenerInRange(DistanceRange);
	}

	void SetRandomStopTime(const float& Min, const float& Max)
	{
		StopTime = FMath::RandRange(Min, Max);
	}

	void SetRandomTriggerTime(const float& Min, const float& Max)
	{
		TriggerTime = FMath::RandRange(Min, Max);
	}

	void HandleInteruption(bool bPostInterruptionEvent = true)
	{
		UpdateCanTrigger(false);

		if(bPostInterruptionEvent)
			PatrolActorHazeAkComp.HazePostEvent(OnInterruptedEvent, PostEventType = EHazeAudioPostEventType::LocalOrRandom);
			
		bTriggerIsBlocked = true;
	}

	void FinishInteruption()
	{
		bTriggerIsBlocked = false;
		const bool bTriggerReady = (HasListenerInRange() && bIsRegistered);
		UpdateCanTrigger(bTriggerReady);
	}

	void HandleDeath()
	{
		PatrolActorHazeAkComp.HazePostEvent(OnPerformDeathEvent, PostEventType = EHazeAudioPostEventType::LocalOrRandom);
		UnregisterPatrolAudioComp(this);
	}

	void SetMovementRTPC()
	{
		if(MovementEvent == nullptr)
			return;

		FVector CurrentLocation = Owner.GetActorLocation();
		const float Movement = (CurrentLocation - LastLocation).Size();
		const float MovementSpeed = HazeAudio::NormalizeRTPC01(Movement, 0.f, MaxMovementSpeed);

		if(MovementSpeed != LastMovementSpeed)
		{
			if (PatrolActorHazeAkComp.bIsEnabled)
				PatrolActorHazeAkComp.SetRTPCValue("Rtpc_SideCharacter_Patrolling_Movement_Speed", MovementSpeed);
			LastMovementSpeed = MovementSpeed;
		}

		LastLocation = CurrentLocation;
	}

	UFUNCTION(BlueprintCallable)
	void BP_RegisterToManager() {RegisterPatrolAudioComp(this);}	

	UFUNCTION(BlueprintCallable)
	void BP_UnregisterToManager() {UnregisterPatrolAudioComp(this);}	

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UnregisterPatrolAudioComp(this);
	}
}
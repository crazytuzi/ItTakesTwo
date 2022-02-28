import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.Audio.ObjectTimeControlAudioComponent;

class UObjectTimeControlAudioCapability : UHazeCapability
{
	UHazeAkComponent HazeAkComp;
	UTimeControlActorComponent TimeControlComp;
	UObjectTimeControlAudioComponent AudioTimeComp;
	UTimelineComponent TimelineComp;
	UPlayerHazeAkComponent CodyHazeAkComp;

	UHazeSkeletalMeshComponentBase SkeletalMeshComp;

	ETimeControlCrumbType CurrentAction;
	ETimeControlCrumbType LastPlayerAction;

	private float TimelineLength;
	private float LastTimePos;
	private float LastManipulationDeltaValue;
	private float LastPreviousManipulationDeltaValue;
	private float StartTimelineValue;

	private bool bHasStartedTimeManipulating = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{		
		TimeControlComp = UTimeControlActorComponent::Get(Owner);
		TimelineComp = UTimelineComponent::Get(Owner);
		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);		
		AudioTimeComp = UObjectTimeControlAudioComponent::Get(Owner);
		CodyHazeAkComp = UPlayerHazeAkComponent::Get(Game::GetCody());

		AudioTimeComp.HazeAkComp = HazeAkComp;

		CreateTimelineHazeAkComps();

		// Cache duration on timeline of Timeline-sounds
		for(FTimeControlTimelineSound& TimelineSound : AudioTimeComp.TimelineSounds)
		{
			if(TimelineSound.ForwardProgressionSound != nullptr)
				TimelineSound.TimelineDuration = TimelineSound.ForwardProgressionSound.HazeMaximumDuration;

			if(TimelineSound.ReverseProgressionSound != nullptr)
				TimelineSound.TimelineReverseDuration = TimelineSound.ReverseProgressionSound.HazeMaximumDuration;
		}
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TimeControlComp == nullptr || AudioTimeComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!TimeControlComp.GetSyncedNetworkIsBeingTimeControlled())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TimeControlComp.GetSyncedNetworkIsBeingTimeControlled() && TimeControlComp.PointInTime == 1)
			return EHazeNetworkDeactivation::DeactivateLocal;		

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{			
		SkeletalMeshComp = UHazeSkeletalMeshComponentBase::Get(Owner);
		AudioTimeComp.StartLoop();

		const float CurrentTime = GetTimelinePosition();
		LastTimePos = CurrentTime;		

		StartTimelineValue = CurrentTime;
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AudioTimeComp.StopLoop();		
		AudioTimeComp.TimelineFullyProgressed();
		LastPlayerAction = ETimeControlCrumbType::Unknown;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{	
		if(TimeControlComp == nullptr)	
			return;

		TimelineLength = GetCurrentTimeline();
		CurrentAction = TimeControlComp.GetSyncedNetworkTimeControlDirection();	

		const float CurrentTime = GetTimelinePosition();			

		bHasStartedTimeManipulating = HasStartedManipulating(CurrentTime);

		if(CurrentTime != LastTimePos || CurrentAction != LastPlayerAction)
		{		
			QueryActiveManipulation(CurrentTime);
			QueryTimelineSounds(CurrentTime);
			LastPlayerAction = CurrentAction;	

			HazeAkComp.SetRTPCValue("Rtpc_TimeControl_Manipulation_Progress", TimeControlComp.PointInTime);
			CodyHazeAkComp.SetRTPCValue("Rtpc_Gadgets_TimeControl_Manipulation_Value", TimeControlComp.PointInTime);
		}	

		LastTimePos = CurrentTime;		

		if(TimeControlComp.PointInTime == 0 && bHasStartedTimeManipulating)
			AudioTimeComp.TimelineFullyReversed();
		else if(AudioTimeComp.bHasPerformedFullyReversed)
			AudioTimeComp.StopPerformFullyReversed();

		if(TimeControlComp.PointInTime == 1 && bHasStartedTimeManipulating)
			AudioTimeComp.TimelineFullyProgressed();

		else if(AudioTimeComp.bHasPerformedFullyProgressed)
			AudioTimeComp.StopPerformFullyProgressed();		
		
#if EDITOR
		if(AudioTimeComp.bDebug)
		{
			PrintToScreenScaled("Timeline Position: " + CurrentTime + " / " + FMath::Abs(TimelineLength), 0.f, FLinearColor::Red, 5.f);	
			PrintToScreenScaled("Timeline Progression RTPC: " + TimeControlComp.PointInTime, 0.f, FLinearColor::Red, 5.f);			
		}
#endif
	}

	private void QueryActiveManipulation(const float& CurrentTime)
	{
		if(CurrentAction != LastPlayerAction)
		{
			float ManipulationDeltaValue = 0.f;
			float PreviousActiveManipulationValue = 0.f;

			//New action, update Audio
			switch(CurrentAction)
			{
				case(ETimeControlCrumbType::Static):
				{
					AudioTimeComp.StopActiveSound();
					
					if(LastPlayerAction == ETimeControlCrumbType::Increasing)
						PreviousActiveManipulationValue = 1.f;
					else if(LastPlayerAction == ETimeControlCrumbType::Decreasing)
						PreviousActiveManipulationValue = -1.f;

					break;
				}
				case(ETimeControlCrumbType::Increasing):
				{
					ManipulationDeltaValue = 1.f;
					UAkAudioEvent CurrentEvent = AudioTimeComp.ForwardEvent;

					if(TimeControlComp.GetSyncedNetworkIsBeingTimeControlled())
					{ 
						if(AudioTimeComp.ForwardTriggerType != ETimelineSoundTriggerType::TriggerOnRelease)
							AudioTimeComp.UpdateSoundDirection(CurrentEvent, CurrentTime * 1000.f);
					}
					else
					{
					 	if(AudioTimeComp.ForwardTriggerType != ETimelineSoundTriggerType::TriggerInTimeline)
							AudioTimeComp.UpdateSoundDirection(CurrentEvent, CurrentTime * 1000.f);
						else
							AudioTimeComp.StopActiveSound();
					}	

					break;
				}
				case(ETimeControlCrumbType::Decreasing):
				{
					ManipulationDeltaValue = -1.f;
					UAkAudioEvent CurrentEvent = AudioTimeComp.ReverseEvent;
					if(AudioTimeComp.ReverseTriggerType != ETimelineSoundTriggerType::TriggerOnRelease)
						AudioTimeComp.UpdateSoundDirection(CurrentEvent, (TimelineLength - CurrentTime) * 1000.f);

					break;
				}			
				default:
					break;
			}

			// Stop active forward/reverse-events if we are controlling time and they are set to only play on release
			if(TimelineIsInAutoProgress())
			{
				if(LastPlayerAction == ETimeControlCrumbType::Increasing && AudioTimeComp.ForwardTriggerType == ETimelineSoundTriggerType::TriggerOnRelease ||
				LastPlayerAction == ETimeControlCrumbType::Decreasing && AudioTimeComp.ReverseTriggerType == ETimelineSoundTriggerType::TriggerOnRelease)
				{
					AudioTimeComp.StopActiveSound();
				}			
			}

			if(ManipulationDeltaValue != LastManipulationDeltaValue)
			{
				HazeAkComp.SetRTPCValue("Rtpc_TimeControl_ManipulationDelta_Value", ManipulationDeltaValue);
				CodyHazeAkComp.SetRTPCValue("Rtpc_Gadgets_TimeControl_ManipulationDelta_Value", ManipulationDeltaValue);

				for(FTimeControlTimelineSound& TimelineSound : AudioTimeComp.TimelineSounds)
				{
					if(TimelineSound.HazeAkComp != nullptr && TimelineSound.HazeAkComp != HazeAkComp)
						TimelineSound.HazeAkComp.SetRTPCValue("Rtpc_TimeControl_ManipulationDelta_Value", ManipulationDeltaValue);
				}

				LastManipulationDeltaValue = ManipulationDeltaValue;
			}
			if(PreviousActiveManipulationValue != LastPreviousManipulationDeltaValue)
			{
				HazeAkComp.SetRTPCValue("Rtpc_TimeControl_ManipulationDelta_Previous_Value", PreviousActiveManipulationValue);
				CodyHazeAkComp.SetRTPCValue("Rtpc_Gadgets_TimeControl_ManipulationDelta_Previous_Value", PreviousActiveManipulationValue);

				for(FTimeControlTimelineSound& TimelineSound : AudioTimeComp.TimelineSounds)
				{
					if(TimelineSound.HazeAkComp != nullptr && TimelineSound.HazeAkComp != HazeAkComp)
						TimelineSound.HazeAkComp.SetRTPCValue("Rtpc_TimeControl_ManipulationDelta_Previous_Value", PreviousActiveManipulationValue);
				}

				LastPreviousManipulationDeltaValue = PreviousActiveManipulationValue;
			}
		}
	}	

	private bool TimelineIsInAutoProgress()
	{
		return CurrentAction == ETimeControlCrumbType::Increasing && !TimeControlComp.GetSyncedNetworkIsBeingTimeControlled();
	}

	private void QueryTimelineSounds(const float& CurrentTime)
	{
		if(!TimeControlComp.GetSyncedNetworkIsBeingTimeControlled() && TimeControlComp.ConstantIncreaseValue == 0.f)
			return;

		for(FTimeControlTimelineSound& TimelineSound : AudioTimeComp.TimelineSounds)
		{
			// Check if timeline position is currently overlapping with this Timeline-sound
			bool bIsInRange = TimelineInSoundRange(CurrentTime, CurrentAction, TimelineSound);
			if(!bIsInRange)
			{
				bool bIsPlayingTimelineSound = IsPlayingTimelineSound(TimelineSound);
				if(bIsPlayingTimelineSound && TimelineSound.bStopIfIdle || TimelineSound.bPauseIfIdle)
					AudioTimeComp.StopTimelineSound(TimelineSound);	

				continue;
			}

			// Check if TimelineSound has been triggered, if true return event by ref
			UAkAudioEvent InTimelineSoundEvent = nullptr;
			float InStartSeekTime = 0.f;
			CheckTimelineTriggeredSound(CurrentTime, LastTimePos, TimelineSound, InTimelineSoundEvent, InStartSeekTime);

			if(InTimelineSoundEvent != nullptr)
			{
				// Found event triggered by current timeline-progression, post it
				if(CheckCanTriggerTimelineSound(TimelineSound))
				{
					AudioTimeComp.PostTimelineSound(TimelineSound, InTimelineSoundEvent, CurrentAction);

					// Due to checking time position between two frames, we want to seek for the time difference of the overlap to our Timeline-sound
					if(TimelineSound.TriggerType != ETimelineSoundTriggerType::TriggerAsTail)				
						TimelineSound.HazeAkComp.SeekOnPlayingEvent(InTimelineSoundEvent, TimelineSound.TimelineEventInstance.PlayingID, InStartSeekTime, false, false, false);
				}
			}
			else if(CurrentAction != ETimeControlCrumbType::Static && CurrentAction != LastPlayerAction)
			{				
				// We are actively manipulating time within range of this Timeline-sound, seek and play event
				UAkAudioEvent CurrentTimelineEvent = nullptr;
				
				if(CurrentAction == ETimeControlCrumbType::Increasing)
					CurrentTimelineEvent = TimelineSound.ForwardProgressionSound;
				else if(CurrentAction == ETimeControlCrumbType::Decreasing)
					CurrentTimelineEvent = TimelineSound.ReverseProgressionSound;	
				else
					CurrentTimelineEvent = TimelineSound.ForwardProgressionSound;

				const float SeekTime = GetTimelineSoundSeekPos(CurrentTime, TimelineSound);

				if(CheckCanTriggerTimelineSound(TimelineSound) && TimelineSound.TriggerType != ETimelineSoundTriggerType::TriggerAsTail)
				{
					AudioTimeComp.UpdateTimelineSound(TimelineSound, CurrentAction, SeekTime, CurrentTimelineEvent);					
				}
			}
			else if(CurrentAction == ETimeControlCrumbType::Static)
			{
				// Time manipulation is standing still, handle stop or pause
				if(IsPlayingTimelineSound(TimelineSound))
				{
					// We are currently not actively manipulating time, but we are in the process of playing this Timeline-sound. Handle it.
					if(TimelineSound.bStopIfIdle || TimelineSound.bPauseIfIdle || 
					TimelineSound.TriggerType == ETimelineSoundTriggerType::TriggerOnRelease) 
					{
						AudioTimeComp.StopTimelineSound(TimelineSound);
					}				
				}
			}

			if(!TimelineIsInAutoProgress() && TimelineSound.TriggerType == ETimelineSoundTriggerType::TriggerOnRelease)
			{
				AudioTimeComp.StopTimelineSound(TimelineSound);
			}	
		}
	}
	
	private void CheckTimelineTriggeredSound(const float& CurrentTime, const float& LastTime, const FTimeControlTimelineSound& TimelineSound, UAkAudioEvent& OutTimelineSoundEvent, float& OutSeekTime)
	{
		if(CurrentTime >= TimelineSound.TimelinePos && LastTime < TimelineSound.TimelinePos)
		{
			// Timeline-sound has been triggered from forward progression
			if(TimelineSound.ForwardProgressionSound != nullptr && TimelineSound.HazeAkComp != nullptr)
			{
				OutTimelineSoundEvent = TimelineSound.ForwardProgressionSound;
				OutSeekTime = (CurrentTime - TimelineSound.TimelinePos) * 1000.f;
			}
		}
		else if(CurrentTime <= TimelineSound.TimelineReversePos && LastTime >= TimelineSound.TimelineReversePos)
		{
			// Timeline-sound has been triggered from reverse progression
			if(TimelineSound.ReverseProgressionSound != nullptr && TimelineSound.HazeAkComp != nullptr)	
			{
				OutTimelineSoundEvent = TimelineSound.ReverseProgressionSound;
				OutSeekTime = (TimelineSound.TimelineReversePos - CurrentTime) * 1000.f;
			}
		}
	}

	private bool TimelineInSoundRange(const float& CurrentTime, const ETimeControlCrumbType& CurrentAction, FTimeControlTimelineSound& TimelineSound)
	{
		if(CurrentAction == ETimeControlCrumbType::Increasing || TimelineIsInAutoProgress())
		{
			if(TimelineSound.ForwardProgressionSound != nullptr)
				return CurrentTime >= TimelineSound.TimelinePos && CurrentTime <= (TimelineSound.TimelinePos + TimelineSound.TimelineDuration);			
		}
		else if(CurrentAction == ETimeControlCrumbType::Decreasing && TimelineSound.ReverseProgressionSound != nullptr)
		{
			return CurrentTime <= TimelineSound.TimelineReversePos && CurrentTime >= (TimelineSound.TimelineReversePos - TimelineSound.TimelineReverseDuration);
		}
		
		return false;
	}

	private bool CheckCanTriggerTimelineSound(const FTimeControlTimelineSound& TimelineSound)
	{
		if(!TimelineIsInAutoProgress() && TimelineSound.TriggerType == ETimelineSoundTriggerType::TriggerOnRelease)
			return false;
		
		if(TimelineIsInAutoProgress() && TimelineSound.TriggerType == ETimelineSoundTriggerType::TriggerInTimeline)
			return false;

		return true;
	}

	private bool IsPlayingTimelineSound(const FTimeControlTimelineSound& TimelineSound)
	{
		bool bPlayingForward = false;
		bool bPlayingReverse = false;

		if(TimelineSound.ForwardProgressionSound != nullptr)
		{
			const int EventID = UHazeAkComponent::GetEventIdFromName(TimelineSound.ForwardProgressionSound.GetName());
			bPlayingForward = TimelineSound.HazeAkComp.HazeIsEventActive(EventID);
		}
		if(TimelineSound.ReverseProgressionSound != nullptr)
		{
			const int EventID = UHazeAkComponent::GetEventIdFromName(TimelineSound.ReverseProgressionSound.GetName());
			bPlayingReverse = TimelineSound.HazeAkComp.HazeIsEventActive(EventID);
		}

		return bPlayingForward == true || bPlayingReverse == true;
	}
	
	private void CreateTimelineHazeAkComps()
	{
		// Create a HazeAkComp for every unique play-location based on BoneNames or AttachCompNames
		TArray<FName> UniqueNames;
		for(FTimeControlTimelineSound& TimelineSound : AudioTimeComp.TimelineSounds)
		{
			if(TimelineSound.AttachToMeshBoneOrComponent != n"")
				UniqueNames.AddUnique(TimelineSound.AttachToMeshBoneOrComponent);	
		}

		TMap<FName, UHazeAkComponent> UniqueHazeAkComps;

		for(int i = 0; i < UniqueNames.Num(); i++)
		{							
			UHazeAkComponent TimelineHazeAkComp = UHazeAkComponent::Create(Owner, FName(Owner.GetName()+"_TimelineHazeAkComp_" + i));
			UniqueHazeAkComps.Add(UniqueNames[i], TimelineHazeAkComp);
		}
		
		for(FTimeControlTimelineSound& TimelineSound : AudioTimeComp.TimelineSounds)
		{
			if(TimelineSound.AttachToMeshBoneOrComponent != n"")	
				UniqueHazeAkComps.Find(TimelineSound.AttachToMeshBoneOrComponent, TimelineSound.HazeAkComp);
			else
				TimelineSound.HazeAkComp = HazeAkComp;			
				
			if(TimelineSound.HazeAkComp == nullptr)
				continue;

			if(TimelineSound.AttachToMeshBoneOrComponent != n"")
			{
				USceneComponent AttachComponent;
				GetAttachComponentByName(AttachComponent, TimelineSound.AttachToMeshBoneOrComponent);

				if(AttachComponent != nullptr && TimelineSound.HazeAkComp != HazeAkComp)
					TimelineSound.HazeAkComp.AttachTo(AttachComponent);
			}
			else if(SkeletalMeshComp != nullptr && TimelineSound.HazeAkComp != HazeAkComp)
				TimelineSound.HazeAkComp.AttachTo(SkeletalMeshComp, TimelineSound.AttachToMeshBoneOrComponent);
#if EDITOR				
			if(AudioTimeComp.bDebug)
				TimelineSound.HazeAkComp.SetDebugAudio(true);				
#endif
		}			
	}

	private float GetCurrentTimeline()
	{
		if(TimeControlComp.GetSyncedNetworkIsBeingTimeControlled())
			return 1.f / TimeControlComp.TimeStepMultiplier;
		else
		{
			if(TimeControlComp.ConstantIncreaseValue == 0.f)
				return 0.f;

			return 1.f / TimeControlComp.ConstantIncreaseValue;
		}
	}

	private float GetTimelinePosition()
	{
		return FMath::Abs(FMath::Lerp(0.f, TimelineLength, TimeControlComp.PointInTime));
	}

	private float GetTimelineSoundSeekPos(const float& CurrentTime, const FTimeControlTimelineSound& TimelineSound)
	{
		if(CurrentAction == ETimeControlCrumbType::Increasing || TimelineIsInAutoProgress())
		{
			return (CurrentTime - TimelineSound.TimelinePos) * 1000.f;
		}
		else if(CurrentAction == ETimeControlCrumbType::Decreasing && TimelineSound.ReverseProgressionSound != nullptr)
		{
			return (TimelineSound.TimelineReversePos - CurrentTime) * 1000.f;	
		}

		return 0.f;
	}

	void GetAttachComponentByName(USceneComponent& OutComponent, FName& InName)
	{
		TArray<USceneComponent> AttachComponents;
		Owner.GetComponentsByClass(AttachComponents);

		for(USceneComponent& Comp : AttachComponents)
		{
			if(Comp.GetName() != InName)
				continue;

			OutComponent = Comp;
			break;
		}
	}

	bool HasStartedManipulating(const float& CurrentTime)
	{
		if(!bHasStartedTimeManipulating)
			return CurrentTime != StartTimelineValue;

		return true;
	}
}
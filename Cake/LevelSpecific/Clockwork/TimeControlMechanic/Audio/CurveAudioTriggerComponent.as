enum ECurveSoundTriggerType
{
	BothDirections,
	Forward,
	Reverse
}

struct FCurveTriggeredSound
{
	UPROPERTY()
	UAkAudioEvent Event = nullptr;

	UPROPERTY()
	float TriggerPosition = 0.f;

	UPROPERTY()
	ECurveSoundTriggerType TriggerType = ECurveSoundTriggerType::BothDirections;
}

// This component is updated from the moving weight container
class UCurveAudioTriggerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	UAkAudioEvent StartLoopEvent;

	UPROPERTY()
	UAkAudioEvent StopLoopEvent;

	UPROPERTY()
	TArray<FCurveTriggeredSound> CurveSounds;
	
	private float LastTimelinePos;
	
	void UpdateAudio(UHazeAkComponent HazeAkComp, float TimelinePos)
	{
		for(FCurveTriggeredSound& CurveSound : CurveSounds)
		{
			CheckTimelineSoundTriggered(HazeAkComp, CurveSound, TimelinePos);
		}

		if(TimelinePos != LastTimelinePos)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Clockwork_TimelineMovingObjects_PositionValue", TimelinePos);
		}

		LastTimelinePos = TimelinePos;

	#if EDITOR		
			if(bHazeEditorOnlyDebugBool)
			{
				PrintToScreenScaled("Curve Position: " + TimelinePos + " /  1", 0.f, FLinearColor::Red, 5.f);	
			}		
	#endif
	}

	void CheckTimelineSoundTriggered(UHazeAkComponent HazeAkComp, const FCurveTriggeredSound& CurveSound, const float& CurrentPos)
	{
		if(CurrentPos >= CurveSound.TriggerPosition && LastTimelinePos < CurveSound.TriggerPosition)
		{
			if(CurveSound.TriggerType != ECurveSoundTriggerType::Reverse)
			{				
				HazeAkComp.HazePostEvent(CurveSound.Event);			
			}
		}

		if(CurrentPos <= CurveSound.TriggerPosition && LastTimelinePos > CurveSound.TriggerPosition)
		{
			if(CurveSound.TriggerType != ECurveSoundTriggerType::Forward)
			{
				HazeAkComp.HazePostEvent(CurveSound.Event);				
			}
		}
	}
}
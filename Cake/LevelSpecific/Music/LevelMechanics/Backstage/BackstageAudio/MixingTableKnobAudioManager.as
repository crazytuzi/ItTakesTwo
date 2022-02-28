import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MixingTableKnob;
import Peanuts.Audio.AudioSpline.AudioSpline;
import Peanuts.Audio.AudioStatics;

class AMixingTableKnobAudioManager : AHazeActor
{
	UPROPERTY()
	AAudioSpline MixingTableSpline;

	UPROPERTY()
	UAkAudioEvent KnobStartEvent;

	UPROPERTY()
	UAkAudioEvent KnobStopEvent;

	UPROPERTY()
	TArray<AMixingTableKnob> MixingKnobs;
	private TArray<FVector> LastKnobLocations;

	int32 MovingKnobCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto& Knob : MixingKnobs)
		{
			LastKnobLocations.Add(Knob.MeshRoot.GetWorldLocation());
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bShouldUpdateCountRtpc = false;
		float FaderMovementValues = 0;

		for(int i = 0; i < MixingKnobs.Num(); i++)
		{
			auto Knob = MixingKnobs[i];

			FVector CurrentKnobLocation = Knob.MeshRoot.GetWorldLocation();
			FVector LastKnobLocation = LastKnobLocations[i];		

			const float MovementDelta = (CurrentKnobLocation - LastKnobLocation).Size();
			FaderMovementValues += MovementDelta;

			if(DidKnobMovementChange(Knob, LastKnobLocation))
			{
				if(Knob.bWasMoving)
				{
					MovingKnobCount --;
					UHazeAkComponent::HazePostEventFireForget(KnobStopEvent, FTransform(CurrentKnobLocation));
					bShouldUpdateCountRtpc = true;
					Knob.bWasMoving = false;
				}
				else
				{
					MovingKnobCount ++;
					UHazeAkComponent::HazePostEventFireForget(KnobStartEvent, FTransform(CurrentKnobLocation));
					bShouldUpdateCountRtpc = true;
					Knob.bWasMoving = true;
				}
			}
			
			LastKnobLocations[i] = CurrentKnobLocation;
		}

		if(bShouldUpdateCountRtpc)
		{
			float ActiveCountRtpcValue = MovingKnobCount / MixingKnobs.Num();
			MixingTableSpline.SplineAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Interactable_MixingTableKnobs_ActiveKnobs", ActiveCountRtpcValue);
		}

		if(MovingKnobCount > 0)
		{
			const float AverageFaderMovement = FaderMovementValues / MovingKnobCount;
			const float NormalizedFaderMovement = HazeAudio::NormalizeRTPC01(AverageFaderMovement, 0.f, 7.f);
			MixingTableSpline.SplineAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Interactable_MixingTableKnobs_AvgSpeed", NormalizedFaderMovement);
		}

		if(MovingKnobCount > 0 && !MixingTableSpline.SplineAkComp.bIsPlaying)
			MixingTableSpline.StartAudioSplineEvent(InTag = n"Loops");
		else if(MovingKnobCount == 0 && MixingTableSpline.SplineAkComp.bIsPlaying)
			MixingTableSpline.SplineAkComp.HazeStopEvent();
	}

	bool DidKnobMovementChange(AMixingTableKnob& Knob, FVector& LastKnobLocation)
	{
		if(Knob.bWasMoving)
			return Knob.MeshRoot.GetWorldLocation().IsNear(LastKnobLocation, 1.f);
		else
			return !Knob.MeshRoot.GetWorldLocation().IsNear(LastKnobLocation, 1.f);
	}

}
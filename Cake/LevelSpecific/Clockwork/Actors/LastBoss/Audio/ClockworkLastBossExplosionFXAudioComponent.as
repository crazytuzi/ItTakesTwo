import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionAudioObjectBase;
import Cake.LevelSpecific.Clockwork.Actors.ReversableBreakable;
import Peanuts.Audio.AudioStatics;

class UClockworkLastBossExplosionFXAudioComponent : UClockworkLastBossExplosionAudioObjectBase
{		
	AReversableBreakableActor ReversableActor;
	float LastPos;
	float LastRtpcVeloValue;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		ReversableActor = Cast<AReversableBreakableActor>(Owner);
		if(ReversableActor != nullptr)
		{
			if(ReversableActor.AttachedEffects.Num() > 0)
			{
				for(auto TriggerableFX : ReversableActor.AttachedEffects)
				{
					HazeAkComp = UHazeAkComponent::GetOrCreate(TriggerableFX.Effect);
					TriggerableFX.Effect.OnSetTime.AddUFunction(this, n"OnTriggerableFXSetTime");
				}
			}
			else
			{
				HazeAkComp = UHazeAkComponent::GetOrCreate(ReversableActor);				
			}
		}
	}

	UFUNCTION()
	void BeginExplosionStarted()
	{
		if(bPlayOnStart)
			EventInstance = HazeAkComp.HazePostEvent(BaseEvent);

		if(bUseMultiPositioning || bTrackVelocity)
			SetComponentTickEnabled(true);

		Super::BeginExplosionStarted();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		if(!bTrackVelocity)
			return;

		const float AnimationPos = ReversableActor.SkeletalMeshComponent.AnimationData.SavedPosition;
		const float Speed = FMath::Abs(AnimationPos - LastPos) * 100.f;
		LastPos = AnimationPos;

		const float NormalizedSpeed = HazeAudio::NormalizeRTPC01(Speed, 0.f, 0.2f);	

		if(NormalizedSpeed != LastRtpcVeloValue)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Object_Velocity", NormalizedSpeed);
			LastRtpcVeloValue = NormalizedSpeed;
		}
	}

	UFUNCTION()
	void OnTriggerableFXSetTime(ATriggerableFX TriggerableFX, const float& NewTime)
	{
		
	}
}

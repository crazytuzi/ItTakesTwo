import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Audio.ClockworkLastBossExplosionAudioObjectBase;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionDebris;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

class UClockworkLastBossExplosionDebrisAudioComponent : UClockworkLastBossExplosionAudioObjectBase
{	 
	FVector LastPos;

	UPROPERTY()
	TArray<FClockworkExplosionTimelineSound> TimelineSounds;

	UPROPERTY()
    bool bUseDopplerRTPC = false;

    UPROPERTY(meta = (EditCondition = "bUseDopplerRTPC"))
    float DopplerScale = 1.f;

    UPROPERTY(meta = (EditCondition = "bUseDopplerRTPC"))
    float DopplerSmoothing = 0.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		AClockworkLastBossExplosionDebris DebrisActor = Cast<AClockworkLastBossExplosionDebris>(Owner);
		if(DebrisActor != nullptr)
		{
			HazeAkComp = UHazeAkComponent::GetOrCreate(DebrisActor);	
			HazeAkComp.SetTrackVelocity(bTrackVelocity, MaxSpeed);
		}
	}

	UFUNCTION()
	void BeginExplosionStarted()
	{			
		if(bPlayOnStart)
			HazeAkComp.HazePostEvent(BaseEvent);

		if(bUseDopplerRTPC)
		{
			UDopplerEffect Doppler = Cast<UDopplerEffect>(HazeAkComp.AddEffect(UDopplerEffect::StaticClass()));
			Doppler.SetObjectDopplerValues(true, MaxSpeed, 1000.f, 0.f, DopplerScale, DopplerSmoothing);			
		}

		for(FClockworkExplosionTimelineSound& TimelineSound : TimelineSounds)
		{
			TimelineSound.HazeAkComp = HazeAkComp;
		}

		if(bUseDopplerRTPC || TimelineSounds.Num() > 0 || bUseMultiPositioning)
			SetComponentTickEnabled(true);

		Super::BeginExplosionStarted();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);

		if(bTrackVelocity)
		{
			FVector Pos = GetWorldLocation();
			const float Speed = (Pos - LastPos).Size() / DeltaSeconds;

			LastPos = Pos;

		#if EDITOR
			if(bDebug)
				Print(GetName() + " speed: " + Speed, 0.f);
		#endif
		}		
	}
}
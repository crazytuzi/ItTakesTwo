import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionActorBase;
class AClockworkLastBossFirstExplosionActor : AClockworkLastBossExplosionActorBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTimeControlActorComponent TimeComp;

	UPROPERTY()
	AHazeLevelSequenceActor ExplosionSeq;

	bool bScrubEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeComp.TimeIsChangingEvent.AddUFunction(this, n"TimeChange");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bScrubEnabled)
			SetExplosionSeq();
	}

	UFUNCTION()
	void SetScrubEnabled(bool bEnable)
	{
		bScrubEnabled = bEnable;
		ExplosionSeq.SequencePlayer.Pause();
	}
	
	UFUNCTION()
	void TimeChange(float CurrentPointInTime)
	{
		CurrentTime = CurrentPointInTime;
	}

	UFUNCTION()
	void SetExplosionSeq()
	{
		FMovieSceneSequencePlaybackParams Params;
		Params.Time = FMath::Lerp(0.f, 7.0f, CurrentTime);
		Params.PositionType = EMovieScenePositionType::Time;
		Params.UpdateMethod = EUpdatePositionMethod::Scrub;
		ExplosionSeq.SequencePlayer.SetPlaybackPosition(Params);
	}
}
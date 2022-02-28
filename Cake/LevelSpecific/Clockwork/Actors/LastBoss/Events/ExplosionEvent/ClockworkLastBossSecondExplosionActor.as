import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossExplosionActorBase;
import Cake.LevelSpecific.Clockwork.VOBanks.ClockworkClockTowerUpperVOBank;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossCodyExplosionComponent;
class AClockworkLastBossSecondExplosionActor : AClockworkLastBossExplosionActorBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTimeControlActorComponent TimeComp;

	UPROPERTY()
	AHazeLevelSequenceActor ExplosionSeq;

	UPROPERTY()
	UClockworkClockTowerUpperVOBank VoBank;
		
	float CurrentTimeScrubTime = 0.f;
	bool bScrubEnabled = false;
	bool bHasPlayedVo = false;

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
	void StartScrubbingCutscene()
	{
		bScrubEnabled = true;
		SetTimeControlForcedActive(Game::GetCody(), this);
		ClockworkLastBoss::ForceCodyTimeWidgetHidden(false);

		Game::GetCody().SetCapabilityActionState(n"AudioStartFinalExplosion", EHazeActionState::ActiveForOneFrame);
	}
	
	UFUNCTION()
	void SetScrubEnabled(bool bEnable)
	{
		bScrubEnabled = bEnable;
	}
	
	UFUNCTION()
	void TimeChange(float CurrentPointInTime)
	{
		CurrentTimeScrubTime = CurrentPointInTime;
		if (CurrentTimeScrubTime >= 1.f)
		{
			bScrubEnabled = false;
			ExplosionSeq.SequencePlayer.Stop();
		}
	}

	UFUNCTION()
	void SetExplosionSeq()
	{
		FMovieSceneSequencePlaybackParams Params;
		Params.PositionType = EMovieScenePositionType::Time;
		Params.UpdateMethod = EUpdatePositionMethod::Scrub;
		Params.Time = FMath::Lerp(8.6667f, 13.5f, CurrentTimeScrubTime);
		ExplosionSeq.SequencePlayer.SetPlaybackPosition(Params);

		if (CurrentTimeScrubTime >= 0.5f && !bHasPlayedVo)
		{
			bHasPlayedVo = true;
			PlayFoghornVOBankEvent(VoBank, n"FoghornDBClockworkUpperTowerClockBossFinalExplosionEnd");
		}
	}
}
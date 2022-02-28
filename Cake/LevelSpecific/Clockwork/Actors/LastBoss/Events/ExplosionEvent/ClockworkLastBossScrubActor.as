import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;

enum EExplosionToScrub
{
	FirstExplosion,
	FinalExplosion,
	Test
}

class AClockworkLastBossScrubActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UTimeControlActorComponent TimeComp;

	// UPROPERTY(DefaultComponent)
	// UTimeControlComponent TimeControlComp;

	float TimeTest = 0.f;

	UPROPERTY()
	FString DebugText;

	UPROPERTY()
	AHazeLevelSequenceActor ExplosionSeq;

	UPROPERTY()
	AHazeLevelSequenceActor FinalExplosionSeq;

	UPROPERTY()
	AHazeLevelSequenceActor TestSeq;

	AHazeLevelSequenceActor ExplosionSeqToScrub;

	EExplosionToScrub CurrentExplosion;

	float LerpMin;
	float LerpMax;

	float CurrentTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeComp.TimeIsChangingEvent.AddUFunction(this, n"TimeChange");
		SetScrubActorEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetExplosionSeq();
	}

	UFUNCTION()
	void SetExplosionToScrub(EExplosionToScrub ExplosionToScrub)
	{
		CurrentExplosion = ExplosionToScrub;

		if (ExplosionToScrub == EExplosionToScrub::FirstExplosion)
		{
			ExplosionSeqToScrub = ExplosionSeq;
			LerpMin = 0.f;
			LerpMax = 7.f;
		}
		else if(ExplosionToScrub == EExplosionToScrub::Test)
		{
			ExplosionSeqToScrub = TestSeq;
			LerpMin = 0.f;
			LerpMax = 1.f;
		}
		else
		{
			ExplosionSeqToScrub = FinalExplosionSeq;
			LerpMin = 9.f;
			LerpMax = 10.f;
		}

		FMovieSceneSequencePlaybackParams Params;
		Params.PositionType = EMovieScenePositionType::Time;
		Params.UpdateMethod = EUpdatePositionMethod::Scrub;
		Params.Time = 0.f;
		ExplosionSeqToScrub.SequencePlayer.SetPlaybackPosition(Params);
	}

	UFUNCTION()
	void SetScrubActorEnabled(bool bEnable)
	{
		if (bEnable)
			TimeComp.EnableTimeControl(this);
		else
			TimeComp.DisableTimeControl(this);
	}

	UFUNCTION()
	void TimeChange(float CurrentPointInTime)
	{
		CurrentTime = CurrentPointInTime;
	}

	UFUNCTION()
	void SetExplosionSeq()
	{
		if (ExplosionSeqToScrub != nullptr)
		{
			FMovieSceneSequencePlaybackParams Params;
			Params.PositionType = EMovieScenePositionType::Time;
			Params.UpdateMethod = EUpdatePositionMethod::Scrub;
			Params.Time = FMath::Lerp(LerpMin, LerpMax, CurrentTime);
			ExplosionSeqToScrub.SequencePlayer.SetPlaybackPosition(Params);
		}
	}
}
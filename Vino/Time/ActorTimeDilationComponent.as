import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

struct FActorTimeDilation
{
	float TimeDilation = 0.f;
	bool bHasDuration = false;
	float Duration = 0.f;
	UCurveFloat Curve;
	UObject Instigator;

	float RemainingTime = 0.f;
};

UCLASS(NotBlueprintable)
class UActorTimeDilationComponent : UActorComponent
{
	TArray<FActorTimeDilation> TimeDilations;

	void AddTimeDilation(float Duration, float TimeDilation, UCurveFloat Curve)
	{
		FActorTimeDilation Dilation;
		Dilation.TimeDilation = TimeDilation;
		Dilation.Duration = Duration;
		Dilation.RemainingTime = Duration;
		Dilation.Curve = Curve;
		Dilation.bHasDuration = true;
		TimeDilations.Add(Dilation);

		SetComponentTickEnabled(true);
	}

	void ClearTimeDilation(UObject Instigator)
	{
		ModifyTimeDilation(1.f, Instigator);
	}

	void ModifyTimeDilation(float TimeDilation, UObject Instigator)
	{
		for (int i = TimeDilations.Num() - 1; i >= 0; --i)
		{
			if(TimeDilations[i].Instigator == Instigator)
			{
				if (TimeDilation == 1.f)
					TimeDilations.RemoveAt(i);
				else
					TimeDilations[i].TimeDilation = TimeDilation;
				return;
			}
		}

		FActorTimeDilation Dilation;
		Dilation.TimeDilation = TimeDilation;
		Dilation.Instigator = Instigator;
		Dilation.bHasDuration = false;
		TimeDilations.Add(Dilation);

		SetComponentTickEnabled(true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float WorldDelta = Time::GetUndilatedWorldDeltaSeconds();
		float WantedDilation = MAX_flt;

		if (TimeDilations.Num() == 0)
			WantedDilation = 1.f;

		for (int i = 0, Count = TimeDilations.Num(); i < Count; ++i)
		{
			auto& Dilation = TimeDilations[i];
			float Dilate = Dilation.TimeDilation;

			if (Dilation.bHasDuration)
			{
				Dilation.RemainingTime -= WorldDelta;
				float DilatePct = 1.f - (Dilation.RemainingTime / Dilation.Duration);

				// The curve can modify the base time dilation amount
				if (TimeDilations[i].Curve != nullptr)
					Dilate = 1.f - ((1.f - Dilate) * TimeDilations[i].Curve.GetFloatValue(DilatePct));

				// Remove the dilation effect if it runs out
				if (TimeDilations[i].RemainingTime <= 0.f)
				{
					TimeDilations.RemoveAt(i);
					--i; --Count;
				}
			}
			else
			{
				Dilate = Dilation.TimeDilation;
			}

			if (Dilate < WantedDilation)
				WantedDilation = Dilate;
		}

		Owner.CustomTimeDilation = WantedDilation;
		if (TimeDilations.Num() == 0 && WantedDilation == 1.f)
		{
			AHazeActor Actor = Cast<AHazeActor>(GetOwner());
			UHazeAkComponent HazeAkComp = UHazeAkComponent::Get(Actor);
			if(HazeAkComp != nullptr)
				HazeAkComp.SetRTPCValue(HazeAudio::RTPC::ModifiedTimeDilationOverride, 1.f);	

			auto AudioManager = Cast<UHazeAudioManager>(Audio::GetAudioManager());
			if(AudioManager != nullptr)
				AudioManager.RequestExitSlowMo(Actor);	

			SetComponentTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		TimeDilations.Empty();
		Owner.CustomTimeDilation = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Owner.CustomTimeDilation = 1.f;
	}
};
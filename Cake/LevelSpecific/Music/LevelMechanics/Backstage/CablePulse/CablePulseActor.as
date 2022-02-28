import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongNotifierComponent;
import Peanuts.Audio.AudioStatics;

event void FOnPulseReachedEnd();
class ACablePulseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	AActor SplineActor;

	UPROPERTY(DefaultComponent, Attach = Niagara)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartPulseAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PulseReachEndAudioEvent;

	UPROPERTY()
	bool bReversePulse;

	USplineComponent Spline;

	UPROPERTY()
	FOnPulseReachedEnd OnReachedEnd;

	float DistanceAlongSpline;

	UPROPERTY()
	bool bIsRunningPulse;

	UPROPERTY()
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		if (SplineActor != nullptr)
		{
			Spline = USplineComponent::Get(SplineActor);
			SetActorLocation(Spline.GetLocationAtDistanceAlongSpline(0, ESplineCoordinateSpace::World));
		}
	}	

	UFUNCTION()
	void StartPulse(UPowerfulSongNotifierComponent Component)
	{
		BP_ActivateEffect();
		bIsRunningPulse = true;
		HazeAkComp.HazePostEvent(StartPulseAudioEvent);

		if (bReversePulse)
		{
			DistanceAlongSpline = Spline.SplineLength;
		}

		else
		{
			DistanceAlongSpline = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsRunningPulse)
		{
			if (bReversePulse)
			{
				DistanceAlongSpline -= DeltaTime * Speed;

				if(DistanceAlongSpline < 0)
				{
					OnPulseReachedEnd();
				}
			}

			else
			{
				DistanceAlongSpline += DeltaTime * Speed;

				if(DistanceAlongSpline > Spline.SplineLength)
				{
					OnPulseReachedEnd();
				}
			}

			const float StartPos = bReversePulse ? Spline.SplineLength : 0.f;
			const float EndPos = StartPos == 0.f ? Spline.SplineLength : 0.f;		
			const float NormalizedDistance = HazeAudio::NormalizeRTPC01(DistanceAlongSpline, StartPos, EndPos);
			HazeAkComp.SetRTPCValue("Rtpc_Gameplay_Gadgets_Microphone_Cable_Pulse_Progress", NormalizedDistance);

			SetActorLocation(Spline.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World));
		}
	}

	UFUNCTION()
	void OnPulseReachedEnd()
	{
		bIsRunningPulse = false;
		BP_DeactivateEffect();
		HazeAkComp.HazePostEvent(PulseReachEndAudioEvent);
		OnReachedEnd.Broadcast();
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateEffect() {}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivateEffect() {}
}
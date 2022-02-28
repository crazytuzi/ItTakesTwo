import Cake.LevelSpecific.Clockwork.Actors.Misc.ClockworkGenericRootComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.Audio.CurveAudioTriggerComponent;

struct FMovingObjectConvertData
{
	UPROPERTY()
	UStaticMesh MeshToUse;

	UPROPERTY()
	FTransform WorldTransform;

	UPROPERTY()
	FTransform MeshRootTransform;

	UPROPERTY()
	FTransform MeshTransform;

	UPROPERTY()
	bool bUseCollision = false;

	UPROPERTY()
	FVector FinalPositionOffset;

	UPROPERTY()
	float DelayUntilStart = 0.f;

	UPROPERTY()
	float LoopDuration = 12.f;

	UPROPERTY()
	bool bStartAtEnd = false;

	UPROPERTY()
	FRuntimeFloatCurve Curve;

	UPROPERTY()
	UAkAudioEvent BeginPlayAudio;

	UPROPERTY()
	UAkAudioEvent CurveStartLoopEvent;

	UPROPERTY()
	UAkAudioEvent CurveStopLoopEvent;

	UPROPERTY()
	TArray<FCurveTriggeredSound> CurveSounds;
}

class AClockworkTimelineMovingObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
    UClockworkTimelineMovingObjectRootComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 24000.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(EditConst)
	UCurveAudioTriggerComponent CurveAudioComp;

	UPROPERTY()
	FVector FinalPositionOffset;

	UPROPERTY()
	float DelayUntilStart = 0.f;

	UPROPERTY()
	float LoopDuration = 12.f;

	UPROPERTY()
	bool bStartAtEnd = false;

	UPROPERTY()
	FRuntimeFloatCurve Curve;

	private float StartGameTime = 0.f;
	private FVector StartLocation;
	private FVector EndLocation;

	private float PositionValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		EndLocation = ActorLocation + ActorRotation.RotateVector(FinalPositionOffset);
		StartGameTime = Time::GetGameTimeSeconds();

		CurveAudioComp = UCurveAudioTriggerComponent::Get(this);
		if(CurveAudioComp != nullptr)
			HazeAkComp.HazePostEvent(CurveAudioComp.StartLoopEvent);

		float ActiveTime = FMath::Max( Time::GetGameTimeSince(StartGameTime) - DelayUntilStart, 0.f);
		SetPosition((ActiveTime % LoopDuration) / LoopDuration);  
	}

	UFUNCTION(BlueprintEvent)
	FMovingObjectConvertData GetConvertData() const
	{
		return FMovingObjectConvertData();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdatePosition();
	}
	 
	void UpdatePosition()
	{
		float ActiveTime = Time::GetGameTimeSince(StartGameTime) - DelayUntilStart;
		if (ActiveTime <= 0.f)
		{
			SetPosition(0.f);
			return;
		}

		SetPosition((ActiveTime % LoopDuration) / LoopDuration);     
		if(CurveAudioComp != nullptr)
			CurveAudioComp.UpdateAudio(HazeAkComp, PositionValue);
	}

	private void SetPosition(float RawValue)
	{
		PositionValue = Curve.GetFloatValue(RawValue);
		if (bStartAtEnd)
			PositionValue = 1.f - PositionValue;
		ActorLocation = FMath::Lerp(StartLocation, EndLocation, PositionValue);
	}
}
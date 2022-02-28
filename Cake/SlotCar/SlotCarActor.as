import Peanuts.Audio.AudioStatics;
import Peanuts.Spline.SplineComponent;
import Cake.SlotCar.SlotCarSettings;

event void FOnLapComplete(ASlotCarActor SlotCar);

class ASlotCarActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    UArrowComponent ArrowComponent;
    default ArrowComponent.SetHiddenInGame(true);

    UPROPERTY(DefaultComponent, Attach = ArrowComponent)
    USceneComponent CarBodyPivot;
    
    UPROPERTY(DefaultComponent, Attach = CarBodyPivot)
    UStaticMeshComponent CarBody;

	UPROPERTY(DefaultComponent)
    UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent)
    UHazeSplineFollowComponent SplineFollowComp;

	UPROPERTY(DefaultComponent, Attach = CarBody)
	UNiagaraComponent TrailNiagaraComp;

	UPROPERTY(DefaultComponent, Attach = CarBodyPivot)
	UNiagaraComponent RespawnNiagaraComp;
	default RespawnNiagaraComp.SetRelativeLocation(FVector(-42.5, 0.f, 0.f));
	default RespawnNiagaraComp.SetAutoActivate(false);


	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

    // Movement tracker
    float PlayerInput;

    UPROPERTY()
    UHazeSplineComponent TrackSpline;

	UObject TrackActor;
	AHazePlayerCharacter OwningPlayer;

    UPROPERTY()
    FVector TrackSplineOffset;

	TArray<FSlotCarHistoryData> SlotCarHistory;
	float HistoryDurationToKeep = 0.5f;
	float HistoryKept = 0.f;

	FHazeAcceleratedFloat AcceleratedYaw;
    
    UPROPERTY()
    FOnLapComplete OnLapComplete;

    int CarIndex;
	UPROPERTY()
	TArray<UMaterialInstance> IndexColours;
	UPROPERTY()
	TArray<FLinearColor> EffectsColor;

	UPROPERTY()
	TPerPlayer<UNiagaraSystem> RespawnEffects;

	UPROPERTY()
	UForceFeedbackEffect DeslotForceFeedbackEffect;

    UPROPERTY(Category = "Car Attributes")
    float CurrentSpeed = 0.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartMovingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMovingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OffTrackEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RespawnEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeslotHitEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ThrottleEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BrakeEvent;

	float Distance = 0.f;
	bool bAllowDeslotHitAudio = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetActorTickEnabled(false);

		if (IndexColours[CarIndex] != nullptr)
			CarBody.SetMaterial(0, IndexColours[CarIndex]);

		TrailNiagaraComp.SetColorParameter(n"TrailColor", EffectsColor[CarIndex]);

		RespawnNiagaraComp.SetAsset(RespawnEffects[OwningPlayer]);

		if (DeslotHitEvent != nullptr)
			CarBody.OnComponentHit.AddUFunction(this, n"OnComponentHit");

		// Panning for Audio
		AddCapability(n"FullScreenPanningCapability");
    }

	UFUNCTION()
    void OnComponentHit(UPrimitiveComponent HitComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, FVector NormalImpulse, FHitResult& Hit)
    {
		if (NormalImpulse.Size() < 95000.f)
			return;

		if (!bAllowDeslotHitAudio)
			return;

		bAllowDeslotHitAudio = false;
		System::SetTimer(this, n"AllowDeslotHitAudio", 0.15f, false);
		HazeAkComp.HazePostEvent(DeslotHitEvent);
    }

	UFUNCTION()
	void AllowDeslotHitAudio()
	{
		bAllowDeslotHitAudio = true;
	}
    
    void LapCompleted()
    {
        OnLapComplete.Broadcast(this);        
    }

	void AddSlotCarHistoryData(FSlotCarHistoryData SlotCarHistoryData)
	{
		SlotCarHistory.Insert(SlotCarHistoryData, 0);
		HistoryKept += SlotCarHistoryData.DeltaTime;

		if (HistoryKept <= HistoryDurationToKeep)
			return;

		// Remove any history that is too far in the past
		for (int Index = SlotCarHistory.Num() - 1; Index > 0; Index--)
		{
			float OldestDelta = SlotCarHistory[Index].DeltaTime;

			if (HistoryKept - OldestDelta > HistoryDurationToKeep)
			{
				HistoryKept -= OldestDelta;
				SlotCarHistory.RemoveAt(Index);
			}
			else
				break;
		}
	}

	float GetRotationLastFrame() const property
	{
		if (SlotCarHistory.Num() < 2)
			return 0.f;

		FVector LastForward = SlotCarHistory[1].SystemPosition.WorldTangent.GetSafeNormal();
		FVector LastUp = SlotCarHistory[1].SystemPosition.WorldUpVector;
		FVector CurrentForward = Math::ConstrainVectorToSlope(SlotCarHistory[0].SystemPosition.WorldTangent, LastUp, LastUp).GetSafeNormal();

		float Dot = CurrentForward.DotProduct(LastForward);
		float Angle = FMath::Acos(Dot) * RAD_TO_DEG;
		if (FMath::IsNearlyEqual(Dot, 1.f, 0.00001f))
			Angle = 0.f;

		FVector LastFrameRight = LastUp.CrossProduct(LastForward);
		Angle *= FMath::Sign(LastFrameRight.DotProduct(CurrentForward));

		return Angle;
	}

	void TeleportSlotCarToStartOfSpline(ASlotCarActor SlotCar)
	{
		FVector Tangent = TrackSpline.GetTangentAtDistanceAlongSpline(0.f, ESplineCoordinateSpace::World);
        FRotator TangentRot = Tangent.ToOrientationRotator();
        FVector RotatedOffset = TangentRot.RotateVector(TrackSplineOffset);

		FHazeSplineSystemPosition SystemPos = SlotCar.TrackSpline.GetPositionAtStart(true);
		SlotCar.SplineFollowComp.UpdateSplineMovementFromPosition(SystemPos);

		SlotCar.TeleportActor(SystemPos.WorldLocation + RotatedOffset, SystemPos.WorldRotation);
		Distance = 0.f;
	}

	float GetMaxSpeed() property
	{
		return (SlotCarSettings::Speed.Acceleration - SlotCarSettings::Speed.Deceleration) / SlotCarSettings::Speed.Drag;
	}

	float GetSpeedPercentage() property
	{
		return FMath::Clamp(CurrentSpeed / MaxSpeed, 0.f, 1.f);
	}
}

struct FSlotCarHistoryData
{
	float Speed;
	FHazeSplineSystemPosition SystemPosition;
	float DeltaTime;

	FSlotCarHistoryData(float InSpeed, FHazeSplineSystemPosition InSystemPosition, float InDeltaTime)
	{
		Speed = InSpeed;
		SystemPosition = InSystemPosition;
		DeltaTime = InDeltaTime;
	}
}

struct FSlotCarSlideAngleHistory
{
	float Angle;
	float AngularVelocity;
	float DeltaTime;

	FSlotCarSlideAngleHistory(float InAngle, float InAnglularVelocity, float InDeltaTime)
	{
		Angle = InAngle;
		AngularVelocity = InAnglularVelocity;
		DeltaTime = InDeltaTime;
	}
}
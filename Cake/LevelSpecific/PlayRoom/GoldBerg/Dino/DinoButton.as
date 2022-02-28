import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;
class ADinoButton : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Button;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Base;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Springs;

	UPROPERTY(DefaultComponent)
	UBoxComponent DinoTrigger;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent EnterSwayAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeaveSwayAudioEvent;

    UPROPERTY(Meta = (MakeEditWidget))
    FTransform Transform;

	FHazeAcceleratedFloat Float;

	bool bIsOverlapped;
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DinoTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		DinoTrigger.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
		StartLocation = Button.RelativeLocation;
	}

	UFUNCTION()
	void TriggerSlam(float Impact)
	{
		Float.AccelerateTo(Impact, 0.001f, ActorDeltaSeconds);
	}

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
		AHeadButtingDino Dino = Cast<AHeadButtingDino>(OtherActor);

        if (Dino != nullptr)
		{
			bIsOverlapped = true;
			Dino.HazeAkComp.HazePostEvent(EnterSwayAudioEvent);
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHeadButtingDino Dino = Cast<AHeadButtingDino>(OtherActor);
		if(Dino == nullptr)
			return;

	    bIsOverlapped = false;
		Dino.HazeAkComp.HazePostEvent(LeaveSwayAudioEvent);
    }



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bIsOverlapped)
		{
			Float.SpringTo(1, 255.5f, 0.1f, DeltaSeconds);
		}
		else
		{
			Float.SpringTo(0, 110.5f, 1.f, DeltaSeconds);
		}
		
		UpdateSwey(Float.Value);
	}

	void UpdateSwey(float Alpha)
	{
		FVector Location = FMath::Lerp(StartLocation, Transform.Location, Alpha);
		Button.RelativeLocation = Location;

		FVector Scale = FVector::OneVector;

		Scale.Z = FMath::Lerp(1.f, 0.75f, Alpha);
		Springs.SetWorldScale3D(Scale);
	}
}
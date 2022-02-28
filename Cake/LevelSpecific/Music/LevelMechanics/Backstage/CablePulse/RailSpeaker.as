import Vino.PlayerHealth.PlayerHealthStatics;

class ABouncingSpeaker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USplineComponent RailSpline;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent DeathTrigger;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UNiagaraComponent ScreamFXUpper;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpeakerBlastEvent;

	UPROPERTY()
	UCurveFloat RetractionCurve;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	const float SingStrength = 100;
	float DesiredDistance;
	float CurrentDistance;
	float SingTimer;
	float RetractionTimer;

	bool bIsSinging = false;
	bool bIsRetracting = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        DeathTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");

    }

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
        if (bIsRetracting)
		{
			AHazePlayerCharacter OverlappingPlayer = Cast<AHazePlayerCharacter>(OtherActor);

			if (OverlappingPlayer != nullptr)
			{
				KillPlayer(OverlappingPlayer, DeathEffect);
			}
		}
    }

	UFUNCTION()
	void ScreamedAt()
	{
		DesiredDistance = RailSpline.SplineLength;
		RetractionTimer = 1.f;
		ScreamFXUpper.Activate(true);
		UHazeAkComponent::HazePostEventFireForget(SpeakerBlastEvent, Root.GetWorldTransform());
	}

	UFUNCTION()
	void StartSinging()
	{
		bIsSinging = true;
		SingTimer = 0;
	}

	UFUNCTION()
	void StopSinging()
	{
		bIsSinging = false;
		RetractionTimer = 0.5f;
		SingTimer = 0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsSinging)
		{
			DesiredDistance += SingStrength * DeltaTime;
			DesiredDistance = FMath::Clamp(DesiredDistance, 0, RailSpline.SplineLength * 0.75f);
			SingTimer += DeltaTime;
		}

		else if (RetractionTimer > 0)
		{
			RetractionTimer -= DeltaTime;
			DesiredDistance = RetractionCurve.GetFloatValue(RetractionTimer) * RailSpline.SplineLength;
			bIsRetracting = true;
		}

		else
		{
			bIsRetracting = true;
		}

		RetractionTimer = FMath::Clamp(RetractionTimer, 0, 1.f);
		DesiredDistance = FMath::Clamp(DesiredDistance, 0, RailSpline.SplineLength);
		CurrentDistance = FMath::Lerp(CurrentDistance, DesiredDistance, DeltaTime * 12);

		Mesh.WorldLocation = RailSpline.GetLocationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World);
	}
}
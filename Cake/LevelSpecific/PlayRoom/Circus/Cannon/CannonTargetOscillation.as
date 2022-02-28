class UCannonTargetOscillation : USceneComponent
{
	UPROPERTY(Meta = (MakeEditWidget))
	FTransform TargetPosition;

	FVector Endlocation; 

	UPROPERTY()
	FHazeTimeLike TimeLike;

	default TimeLike.bLoop = true;
	default TimeLike.bSyncOverNetwork = true;
	default TimeLike.Duration = 1;
	default TimeLike.SyncTag = n"Oscillation";

	UPROPERTY()
	float RandomMaxTimeUntilStart = 0.01f;

	bool bStarted = false;

	UPROPERTY()
	bool bAllowOscillation = true;
	
	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = FVector::ZeroVector;
		Endlocation = TargetPosition.Location;
	}

	UFUNCTION()
	void StartOscillation()
	{
		TimeLike.BindUpdate(this, n"UpdateTimeLike");
		TimeLike.PlayFromStart();
	}

	UFUNCTION()
	void UpdateTimeLike(float Duration)
	{
		if (!bAllowOscillation)
			return;

		FVector Location = FMath::Lerp(StartLocation, Endlocation, Duration);
		SetRelativeLocation(Location);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
   		if (!bStarted)
   		{
			System::SetTimer(this, n"StartOscillation", FMath::RandRange(0.f, RandomMaxTimeUntilStart), false);
      		bStarted = true;
   		}

		SetComponentTickEnabled(false);
	}
}
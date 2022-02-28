import Vino.Interactions.InteractionComponent;

event void FWaterRailRainEvent();

UCLASS(Abstract)
class ClockTownWaterRail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightRoot;

	UPROPERTY(DefaultComponent, Attach = LeftRoot)
	UInteractionComponent LeftInteractionComp;

	UPROPERTY(DefaultComponent, Attach = RightRoot)
	UInteractionComponent RightInteractionComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WaterRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent RailMesh;

	UPROPERTY()
	FWaterRailRainEvent OnRainActivated;

	UPROPERTY()
	float RightOffset = 2000.f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RainTimeLike;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ImpactTimeLike;
	default ImpactTimeLike.Duration = 1.f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ResetImpactTimeLike;
	default ResetImpactTimeLike.Duration = 0.35f;

	float MinLocation;
	float MaxLocation;

	float TargetLoc;

	bool bWaterActive = false;
	bool bGoingRight = true;
	bool bRainActivated = false;
	bool bImpactTriggered = false;
	bool bRained = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RightRoot.SetRelativeLocation(FVector(0.f, RightOffset, 0.f));
		RailMesh.SetRelativeLocation(FVector(0.f, RightOffset/2, 150.f));
	}

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MinLocation = WaterRoot.RelativeLocation.Y;
		MaxLocation = RightOffset - MinLocation;
		TargetLoc = MinLocation;

		LeftInteractionComp.OnActivated.AddUFunction(this, n"LeftInteractionActivated");
		RightInteractionComp.OnActivated.AddUFunction(this, n"RightInteractionActivated");

		RainTimeLike.SetPlayRate(0.75f);
		RainTimeLike.BindUpdate(this, n"UpdateRain");
		RainTimeLike.BindFinished(this, n"FinishRain");

		RightInteractionComp.Disable(n"Right");

		ImpactTimeLike.SetPlayRate(1.25f);
		ImpactTimeLike.BindUpdate(this, n"UpdateImpact");
		ImpactTimeLike.BindFinished(this, n"FinishImpact");

		ResetImpactTimeLike.BindUpdate(this, n"UpdateResetImpact");
		ResetImpactTimeLike.BindFinished(this, n"FinishResetImpact");
    }

    UFUNCTION()
    void LeftInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		LeftInteractionComp.Disable(n"Left");
		bRainActivated = false;
		bGoingRight = true;
		TargetLoc = RightOffset/2.f;
		bWaterActive = true;
    }

	UFUNCTION()
    void RightInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		RightInteractionComp.Disable(n"Right");
		bRainActivated = false;
		bGoingRight = false;
		TargetLoc = RightOffset/2.f;
		bWaterActive = true;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bWaterActive)
		{
			float InterSpeed = bImpactTriggered ? 300.f : 900.f;
			float CurLoc = FMath::FInterpConstantTo(WaterRoot.RelativeLocation.Y, TargetLoc, DeltaTime, InterSpeed);
			WaterRoot.SetRelativeLocation(FVector(0.f, CurLoc, 150.f));

			FVector TraceStartLoc = WaterRoot.WorldLocation - FVector(0.f, 0.f, 170.f);
			TArray<AActor> ActorsToIgnore;
			FHitResult Hit;
			if (!bImpactTriggered)
				System::SphereTraceSingle(TraceStartLoc, TraceStartLoc + FVector(0.f, 0.f, 1.f), 80.f, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true);

			if (Hit.bBlockingHit)
			{
				bImpactTriggered = true;
				bWaterActive = false;
				ImpactTimeLike.PlayFromStart();
			}

			if (CurLoc == TargetLoc)
			{
				bWaterActive = false;
				if (!bRainActivated)
				{
					bRainActivated = true;
					bRained = false;
					RainTimeLike.PlayFromStart();
				}
				else
				{
					if (bGoingRight)
						RightInteractionComp.Enable(n"Right");
					else
						LeftInteractionComp.Enable(n"Left");

					if (bImpactTriggered)
						ResetImpactTimeLike.PlayFromStart();
				}
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRain(float CurValue)
	{
		float CurHeight = FMath::Lerp(150.f, -950.f, CurValue);
		FVector CurLoc = WaterRoot.RelativeLocation;
		CurLoc.Z = CurHeight;
		WaterRoot.SetRelativeLocation(CurLoc);

		if (CurValue >= 0.9f && !bRained)
		{
			bRained = true;
			OnRainActivated.Broadcast();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRain()
	{
		if (bGoingRight)
			TargetLoc = MaxLocation;
		else
			TargetLoc = MinLocation;

		bWaterActive = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateImpact(float CurValue)
	{
		float CurRot = FMath::Lerp(0.f, 540.f, CurValue);
		WaterRoot.SetRelativeRotation(FRotator(CurRot, 0.f, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishImpact()
	{
		bRainActivated = true;

		if (bGoingRight)
		{
			TargetLoc = MinLocation;
			bGoingRight = false;
		}
		else
		{
			TargetLoc = MaxLocation;
			bGoingRight = true;
		}

		bWaterActive = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateResetImpact(float CurValue)
	{
		float CurRot = FMath::Lerp(180.f, 0.f, CurValue);
		WaterRoot.SetRelativeRotation(FRotator(CurRot, 0.f, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishResetImpact()
	{
		bImpactTriggered = false;
	}
}
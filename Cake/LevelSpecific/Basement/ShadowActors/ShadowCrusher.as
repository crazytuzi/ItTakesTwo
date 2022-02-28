UCLASS(Abstract)
class AShadowCrusher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CrusherRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike CrushTimeLike;

	UPROPERTY()
	bool bActiveFromStart = true;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation = FVector(0.f, 0.f, -1000.f);

	UPROPERTY()
	float TimeBetweenCrushes = 2.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CrushTimeLike.BindUpdate(this, n"UpdateCrush");
		CrushTimeLike.BindFinished(this, n"FinishCrush");

		if (bActiveFromStart)
			TriggerCrush();
	}

	UFUNCTION()
	void TriggerCrush()
	{
		CrushTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateCrush(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(FVector::ZeroVector, EndLocation, CurValue);
		CrusherRoot.SetRelativeLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishCrush()
	{
		System::SetTimer(this, n"TriggerCrush", TimeBetweenCrushes, false);
	}
}
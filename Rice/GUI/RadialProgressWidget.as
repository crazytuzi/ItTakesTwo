
class URadialProgressWidget : UHazeUserWidget
{
	UPROPERTY(Meta = (BlueprintSetter = "UpdateProgressValue"), Category = "Progress")
	float Progress = 0.7f;

	UPROPERTY(BlueprintReadOnly, Category = "Progress")
	float StartAngle = 0.f;

	UPROPERTY(BlueprintReadOnly, Category = "Progress")
	float EndAngle = 1.f;

	UFUNCTION(Meta = (BlueprintInternalUseOnly))
	void UpdateProgressValue(float NewProgress)
	{
		if (Progress != NewProgress)
		{
			Progress = NewProgress;
			OnProgressUpdated();
		}
	}

	UFUNCTION(BlueprintEvent)
	protected void OnProgressUpdated() {}

	UFUNCTION()
	void ChangeAngles(float NewStartAngle, float NewEndAngle)
	{
		if (StartAngle != NewStartAngle || EndAngle != NewEndAngle)
		{
			StartAngle = NewStartAngle;
			EndAngle = NewEndAngle;
			OnRefreshParameters();
		}
	}

	UFUNCTION(BlueprintEvent)
	protected void OnRefreshParameters() {}

	UFUNCTION()
	float InterpProgressTo(float Target, float DeltaTime, float InterpSpeed)
	{
		if (Progress != Target)
		{
			UpdateProgressValue(FMath::FInterpTo(
				Progress, Target, DeltaTime, InterpSpeed));
		}
		return Progress;
	}
};
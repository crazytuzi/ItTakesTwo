UCLASS(Abstract)
class UEnemyIndicatorWidget : UHazeUserWidget
{
	UPROPERTY()
	float MinOpacity = 0.f;

	float HighlightEndTime = 0.f;

	UFUNCTION()
	void Highlight(float Duration)
	{
		HighlightEndTime = Time::GetGameTimeSeconds() + Duration;
	}

	UFUNCTION(BlueprintPure)
	bool IsHighlighted()
	{
		return Time::GetGameTimeSeconds() < HighlightEndTime;
	}

	UFUNCTION(BlueprintEvent)
	void SetScreenspaceOffset(FVector2D Offset) {}
}
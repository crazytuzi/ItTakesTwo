UCLASS(Abstract)
class UOtherPlayerIndicatorWidget : UHazeUserWidget
{
	UPROPERTY()
	bool bOtherPlayerOnScreen;

	UPROPERTY()
	FVector2D AnchorPos;
	
	UPROPERTY()
	bool bTargetIsMay;

	UPROPERTY()
	float IndicatorRotationAngle;

	UPROPERTY()
	float IndicatorOpacity = 1.f;
}
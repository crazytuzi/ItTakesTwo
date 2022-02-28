UCLASS(Abstract)
class UVineAimWidget : UHazeUserWidget
{
	UPROPERTY()
	EVineAimWidgetMode CurrentMode;

	UPROPERTY()
	FVector AutoAimTargetWorldLocation;

	UFUNCTION(BlueprintEvent)
	void OnAimStarted()
	{

	}

	void MakeValid()
	{
		CurrentMode = EVineAimWidgetMode::Valid;
	}

	void MakeInvalid()
	{
		CurrentMode = EVineAimWidgetMode::Invalid;
	}

	void MakeAutoAim(FVector WorldLocation)
	{
		CurrentMode = EVineAimWidgetMode::AutoAim;
		AutoAimTargetWorldLocation = WorldLocation;
	}
}

enum EVineAimWidgetMode
{
	Invalid,
	Valid,
	AutoAim
}
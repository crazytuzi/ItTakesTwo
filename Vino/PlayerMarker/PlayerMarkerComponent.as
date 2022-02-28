import Vino.PlayerMarker.PlayerMarkerWidget;

UCLASS(Abstract)
class UPlayerMarkerComponent : USceneComponent
{
	UPROPERTY()
	TSubclassOf<UPlayerMarkerWidget> WidgetClass;

	// Marker is by default enabled in normal mode (hidden when on screen and close).
	// You can disable this by calling SetDisabled and clear previous disabling with ClearDisabled.
	// Force enablers will override any disablers and make marker always show.
	// Force disablers will override all to always hide marker.
	private TArray<UObject> Disablers;
	private TArray<UObject> ForceEnablers;
	private TArray<UObject> ForceDisablers;

	bool IsEnabled()
	{
		if (ForceDisablers.Num() > 0)
			return false;

		if (ForceEnablers.Num() > 0)
			return true;

		return (Disablers.Num() == 0);	
	}

	bool IsForceEnabled()
	{
		return (ForceEnablers.Num() > 0) && (ForceDisablers.Num() == 0);
	}

	void SetDisabled(UObject Instigator)
	{
		Disablers.AddUnique(Instigator);	
	}

	void ClearDisabled(UObject Instigator)
	{
		Disablers.RemoveSwap(Instigator);	
	}

	void SetForceEnabled(UObject Instigator)
	{
		ForceEnablers.AddUnique(Instigator);	
	}

	void ClearForceEnabled(UObject Instigator)
	{
		ForceEnablers.RemoveSwap(Instigator);	
	}

	void SetForceDisabled(UObject Instigator)
	{
		ForceDisablers.AddUnique(Instigator);	
	}

	void ClearForceDisabled(UObject Instigator)
	{
		ForceDisablers.RemoveSwap(Instigator);	
	}
}

UCLASS(NotBlueprintable, meta = ("JoyPotGrowingPlantsFallDownFinished (time marker)"))
class UAnimNotify_JoyPotGrowingPlants : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "JoyPotGrowingPlantsFallDownFinished (time marker)";
	}
};
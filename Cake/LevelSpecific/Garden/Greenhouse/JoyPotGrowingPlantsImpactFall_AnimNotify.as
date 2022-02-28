UCLASS(NotBlueprintable, meta = ("JoyPotGrowingPlantsImpactFall (time marker)"))
class UAnimNotify_JoyPotGrowingPlantsImpactFall : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "JoyPotGrowingPlantsImpactFall (time marker)";
	}
};
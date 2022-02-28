UCLASS(NotBlueprintable, meta = ("PlantHammerSmash (time marker)"))
class UAnimNotify_BossControllablePlantHammer : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "PlantHammerSmash (time marker)";
	}
};
UCLASS(NotBlueprintable, meta = ("BirdMomHappyFinished (time marker)"))
class UAnimNotify_BirdMomHappyFinished : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "BirdMomHappyFinished (time marker)";
	}
};
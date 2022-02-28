UCLASS()
class UAnimNotify_SnowyOwlNeutralPose : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SnowyOwlNeutralPose";
	}
};
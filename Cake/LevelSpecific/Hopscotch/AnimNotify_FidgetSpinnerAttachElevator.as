UCLASS()
class UAnimNotify_FidgetSpinnerAttachElevator : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "FidgetspinnerAttach";
	}
};
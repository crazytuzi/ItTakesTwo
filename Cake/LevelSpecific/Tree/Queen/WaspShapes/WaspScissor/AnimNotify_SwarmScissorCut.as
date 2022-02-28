
UCLASS(NotBlueprintable, meta = ("ScissorCut (time marker)"))
class UAnimNotify_SwarmScissorCut : UAnimNotify 
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "ScissorCut (time marker)";
	}
};
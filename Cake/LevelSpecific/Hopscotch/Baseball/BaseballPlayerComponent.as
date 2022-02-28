class UBaseballPlayerComponent : UActorComponent
{
	UPROPERTY()
	float BlendSpaceValue = 0;

	UFUNCTION(BlueprintOverride)
    void BeginPlay() {}
}
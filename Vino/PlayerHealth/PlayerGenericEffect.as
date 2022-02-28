import Peanuts.Foghorn.FoghornStatics;

UCLASS(Abstract)
class UPlayerGenericEffect : UObjectInWorld
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFinished = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bActive = false;

	void Activate()
	{
		ensure(!bActive);
		bActive = true;
		BP_Activate();		
	}

	void Deactivate()
	{
		ensure(bActive);
		bActive = false;
		BP_Deactivate();
	}

	void Tick(float DeltaTime)
	{
		BP_Tick(DeltaTime);
	}

	UFUNCTION()
	void FinishEffect()
	{
		bFinished = true;
		BP_EffectFinished();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Activate() {}
	UFUNCTION(BlueprintEvent)
	void BP_Deactivate() {}
	UFUNCTION(BlueprintEvent)
	void BP_Tick(float DeltaTime) {}
	UFUNCTION(BlueprintEvent)
	void BP_EffectFinished() {}
};
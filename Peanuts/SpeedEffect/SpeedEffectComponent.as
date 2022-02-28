class USpeedEffectComponent : UActorComponent
{
	float Value = 0.f;
	TArray<FSpeedEffectRequest> ValueRequests;

	UPROPERTY()
	UNiagaraSystem SpeedEffect = Asset("/Game/Effects/Niagara/Screenspace_Speed_01.Screenspace_Speed_01");

	UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        ValueRequests.Empty();
    }

	void RequestValue(FSpeedEffectRequest Request)
	{
		int Index = ValueRequests.FindIndex(Request);

		if (Index >= 0)
		{
			ValueRequests[Index] = Request;
		}
		else
			ValueRequests.Add(Request);
	}
}

struct FSpeedEffectRequest
{
    UPROPERTY()
    float Value = 0.f;

    UPROPERTY()
    bool bSnap = false;

	UPROPERTY()
	UObject Instigator;

    FSpeedEffectRequest(float RequestedValue, UObject _Instigator, bool bShouldSnap = false)
    {
        Value = RequestedValue;
        bSnap = bShouldSnap;
		Instigator = _Instigator;
    }

	bool opEquals(UObject OtherInstigator)	
	{
		return Instigator == OtherInstigator;
	}
}
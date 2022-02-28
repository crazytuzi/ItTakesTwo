class UNightclubBeatFXComponent : UActorComponent
{
	UPROPERTY()
	UNiagaraComponent PreviousFX;

	void BeatWasMade()
	{
		ClearPreviousFX();
		BP_BeatWasMade();
	}

	UFUNCTION(BlueprintEvent)
	void BP_BeatWasMade() {}

	void ClearPreviousFX()
	{
		if (PreviousFX != nullptr)
			PreviousFX.Deactivate();
	}
}
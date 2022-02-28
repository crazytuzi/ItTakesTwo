class AFlipperpad : AActor
{
	bool IsFlipped;

	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Flipper;

	UFUNCTION()
	void StartFlip()
	{
		IsFlipped = true;
		StartedFlip();
	}

	UFUNCTION(BlueprintEvent)
	void StartedFlip()
	{

	}

	UFUNCTION(BlueprintEvent)
	void StoppedFlip()
	{

	}

	UFUNCTION()
	void StopFlip()
	{
		IsFlipped = false;
		StoppedFlip();
	}
}
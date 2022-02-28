class UAimWidgetHarpoon : UHazeUserWidget
{
	UPROPERTY()
	FVector AimWorldLocation;

	UPROPERTY()
	AHazePlayerCharacter CurrentPlayer;

	UPROPERTY()
	FVector CurrentAimLocation;

	UPROPERTY()
	float InterpSpeed = 25.f;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		CurrentAimLocation = AimWorldLocation;
	}

	UFUNCTION(BlueprintEvent)
	void BP_FiredHarpoon() {}
}
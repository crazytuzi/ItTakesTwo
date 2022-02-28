class APirateOctopusThirdArmSlamLocation : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// PrintToScreen("bIsActive: " + bIsActive);
	}
}
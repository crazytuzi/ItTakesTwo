class CannonScoreBoardActor : AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Spring;

	UPROPERTY()
	int TimesScored;

	UFUNCTION()
	void Score()
	{
		TimesScored++;
	}

	UFUNCTION(BlueprintEvent)
	void PlaySpringAnimation()
	{
		
	}
}
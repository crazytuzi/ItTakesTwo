class ABoatsledStartLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftSemaphore;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightSemaphore;

	UPROPERTY()
	TArray<UMaterialInstance> EmmissiveLights;

	UFUNCTION()
	void Mark(int Count)
	{
		switch(Count)
		{
			case 1:
				LeftSemaphore.SetMaterial(1, EmmissiveLights[0]);
				RightSemaphore.SetMaterial(1, EmmissiveLights[0]);
				break;

			case 2:
				LeftSemaphore.SetMaterial(4, EmmissiveLights[1]);
				RightSemaphore.SetMaterial(4, EmmissiveLights[1]);
				break;
			
			case 3:
				LeftSemaphore.SetMaterial(3, EmmissiveLights[2]);
				RightSemaphore.SetMaterial(3, EmmissiveLights[2]);
				break;

			case 4:
				LeftSemaphore.SetMaterial(2, EmmissiveLights[3]);
				RightSemaphore.SetMaterial(2, EmmissiveLights[3]);
				break;
		}
	}
}
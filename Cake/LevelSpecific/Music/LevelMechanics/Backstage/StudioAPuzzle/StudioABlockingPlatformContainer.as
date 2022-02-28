import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioABlockingPlatform;
class AStudioABlockingPlatformContainer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TArray<AStudioABlockingPlatform> BlockingPlatformArray;

	UPROPERTY()
	TArray<AStudioABlockingPlatform> BlockingPlatformMoveTwiceArray;

	UFUNCTION(CallInEditor)
	void GetPlatformReferences()
	{
		TArray<AStudioABlockingPlatform> Platforms;
		GetAllActorsOfClass(Platforms);
		for (auto Platform : Platforms)
		{
			float Dist = FMath::Abs(FVector(Platform.ActorLocation - ActorLocation).Size());

			if (Dist > 15000.f)
				continue;

			BlockingPlatformArray.Add(Platform);
			if (Platform.bCanBeMovedTwice)
				BlockingPlatformMoveTwiceArray.Add(Platform);
		}
	}
}
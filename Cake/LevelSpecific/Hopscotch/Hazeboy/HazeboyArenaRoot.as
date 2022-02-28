import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class AHazeboyArenaRoot : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> Children;
		GetAttachedActors(Children);

		for(auto Child : Children)
		{
			HazeboyRegisterVisibleActor(Child);
		}
	}
}
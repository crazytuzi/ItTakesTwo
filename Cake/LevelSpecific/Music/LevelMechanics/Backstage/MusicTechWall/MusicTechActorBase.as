import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechKnobs;

class AMusicTechActorBase : AHazeActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AMusicTechKnobs> TempArray;
		GetAllActorsOfClass(TempArray);
		AMusicTechKnobs MusicTechKnobs = TempArray[0];
		MusicTechKnobs.RotationRateUpdate.AddUFunction(this, n"RotationRateUpdate");		
	}

	UFUNCTION()
	void RotationRateUpdate(float LeftRotationRate, float RightRotationRate)
	{
	
	}
}
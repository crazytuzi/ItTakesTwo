import Cake.LevelSpecific.Music.LevelMechanics.Backstage.WindupCassetteRoom.WindupCassette;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.WindupCassetteRoom.WindupCassetteRotatingActor;
import Cake.Interactions.Windup.WindupActor;

class AWindupCassetteManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	AWindupCassette WindupCassette;

	UPROPERTY()
	AWindupActor WindupKeyActor;

	TArray<AWindupCassetteRotatingActor> RotatingActorArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(RotatingActorArray);

		WindupKeyActor.OnWindupFinishedEvent.AddUFunction(this, n"WindupFinished");
	}

	UFUNCTION()
	void WindupFinished(AWindupActor WindupActor)
	{
		StartRotatingActors();
	}

	UFUNCTION()
	void StartRotatingActors()
	{
		for (AWindupCassetteRotatingActor RotActor : RotatingActorArray)
		{
			RotActor.StartRotatingActor(true);
		}
	}
}
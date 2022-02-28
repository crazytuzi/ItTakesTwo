
import Vino.Checkpoints.Volumes.DeathVolume;

class AJoyDeathVolumeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY()
	TArray<ADeathVolume> DeathVolumes;

	UPROPERTY()
	TArray<AActor> CollisionWalls;

	UPROPERTY()
	bool DisabledFromStart = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(DisabledFromStart)
			DisableArrays(true, true);
	}

	UFUNCTION()
	void EnableArrays(bool Volumes, bool Walls)
	{	
		if(Volumes == true)
		{
			for(ADeathVolume Volume : DeathVolumes)
			{
				Volume.EnableDeathVolume();
			}
		}

		if(Walls == true)
		{
			for(AActor Wall : CollisionWalls)
			{
				Wall.SetActorEnableCollision(true);
			}
		}
	}

	UFUNCTION()
	void DisableArrays(bool Volumes, bool Walls)
	{	
		if(Volumes == true)
		{
			for(ADeathVolume Volume : DeathVolumes)
			{
				Volume.DisableDeathVolume();
			}
		}

		if(Walls == true)
		{
			for(AActor Wall : CollisionWalls)
			{
				Wall.SetActorEnableCollision(false);
			}
		}
	}
}


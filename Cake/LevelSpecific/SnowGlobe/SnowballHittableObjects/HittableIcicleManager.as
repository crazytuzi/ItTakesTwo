import Cake.LevelSpecific.SnowGlobe.SnowballHittableObjects.HittableIcicle;

class AHittableIcicleManager : AHazeActor
{
	// UPROPERTY(DefaultComponent, RootComponent)
	// USphereComponent IcicleVolume;
	// default IcicleVolume.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(Category = "Setup")
	TArray<AHittableIcicle> Icicles;

	// UFUNCTION(BlueprintOverride)
	// void ConstructionScript()
	// {
	// 	IcicleVolume.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	// }

	UFUNCTION()
	void DeactivateAllIciles()
	{
		for (AHittableIcicle Icicle : Icicles)
		{
			if (!Icicle.IsActorDisabled())
				Icicle.DisableActor(this);
		}
	}
}
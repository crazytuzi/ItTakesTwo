import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;

UCLASS(HideCategories = "Cooking Replication Collision Debug Actor Tags HLOD Mobile AssetUserData Input LOD Rendering")
class ADandelionKillVolume : AVolume
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		BrushComponent.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
	}
		
	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		ADandelion Dandelion = Cast<ADandelion>(OtherActor);

		if(Dandelion == nullptr)
		{
			return;
		}
		
		Dandelion.KillDandelion();
	}
}

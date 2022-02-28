import Cake.LevelSpecific.Garden.Greenhouse.GreenhouseHealthManager;

UCLASS(HideCategories = "Physics Collision Rendering Cooking Tags LOD Activation AssetUserData")
class UGreenhouseDamageGiverComponent : UActorComponent
{
	UPROPERTY()
	AGreenhouseHealthManager GreenhouseHealthManager;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(GreenhouseHealthManager == nullptr)
		{
			TArray<AActor> HPManagerList;
			Gameplay::GetAllActorsOfClass(AGreenhouseHealthManager::StaticClass(), HPManagerList);
			
			for (AActor Actor : HPManagerList)
			{
				AGreenhouseHealthManager HPManagerActor = Cast<AGreenhouseHealthManager>(Actor);
				
				GreenhouseHealthManager = HPManagerActor;
				return;
			}

			if(GreenhouseHealthManager == nullptr)
				Print("" + Name + " didn't find GreenhouseHealthManager", 3.0f);
		}
	}


	UFUNCTION()
	void DealDamage(float DamageAmount)
	{
		if(GreenhouseHealthManager != nullptr)
			GreenhouseHealthManager.OnDamageTaken.Broadcast(DamageAmount);
	}
}
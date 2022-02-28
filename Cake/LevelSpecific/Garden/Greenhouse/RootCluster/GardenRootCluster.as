
import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.GardenEnemySpawnerActor;
import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.GardenUnwitherSphereManager;
import Cake.LevelSpecific.Garden.Greenhouse.GreenhouseDamageGiverComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;

event void FOnGardenRootClusterDestroyed();

UCLASS(Abstract)
class AGardenRootCluster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = "Billboard")
	UTextRenderComponent ManagerText;
	default ManagerText.SetRelativeLocation(FVector(0, 0, 50.f));
	default ManagerText.SetText(FText::FromString("Root Cluster"));
	default ManagerText.SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
	default ManagerText.SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
	default ManagerText.SetHiddenInGame(true);
	default ManagerText.XScale = 5;
	default ManagerText.YScale = 5;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UGreenhouseDamageGiverComponent GreenhouseDamageComp;
	float DamageAmount = 5;

	UPROPERTY()
	TArray<AActor> ActorsPartOfCluster;

	UPROPERTY()
	TArray<AActor> ActorsToDestroyWithCluster;

	UPROPERTY()
	FOnGardenRootClusterDestroyed OnClusterDestroyed;

	UPROPERTY()
	bool bConnectToUnwitherSphere = false;
	UPROPERTY(NotEditable)
	AGardenUnwitherSphereManager UnwitherSphereManager;
	UPROPERTY()
	int UnwitherSphereIndex;

	UPROPERTY()
	TArray<ASubmersibleSoilPlantSprayer> PlantSprayers;

	UPROPERTY()
	TArray<AGardenEnemySpawnerActor> EnemySpawners;

	FTimerHandle DestroyTimerHandle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AActor ClusterActor : ActorsPartOfCluster)
		{
			ClusterActor.OnDestroyed.AddUFunction(this, n"OnClusterActorDestroyed");
		}

		for (ASubmersibleSoilPlantSprayer PlantSprayer : PlantSprayers)
		{
			if(PlantSprayer != nullptr)
			{
				PlantSprayer.SetWaterable(false);
				PlantSprayer.SetSoilEnabled(false);
			}
		}

		if(bConnectToUnwitherSphere)
			System::SetTimer(this, n"FindUnwitherManager", 0.2f, false);
	}

	UFUNCTION()
	void FindUnwitherManager()
	{
		TArray<AActor> UnwitherManagers;
		Gameplay::GetAllActorsOfClass(AGardenUnwitherSphereManager::StaticClass(), UnwitherManagers);

		if(UnwitherManagers.Num() > 0)
			UnwitherSphereManager = Cast<AGardenUnwitherSphereManager>(UnwitherManagers[0]);
	}

	UFUNCTION()
	void SetUnwitherManager(AGardenUnwitherSphereManager UnwitherManager)
	{
		UnwitherSphereManager = UnwitherManager;
	}

	UFUNCTION()
	void OnClusterActorDestroyed(AActor DestoyedActor)
	{
		ActorsPartOfCluster.Remove(DestoyedActor);

		if(ActorsPartOfCluster.Num() <= 0)
		{
			DestroyTimerHandle = System::SetTimer(this, n"DestroyCluster", 0.75f, false);
		}
	}

	UFUNCTION()
	void DestroyCluster()
	{
		System::ClearAndInvalidateTimerHandle(DestroyTimerHandle);
		Print("CLUSTER DESTROYED", 3.0f, FLinearColor::Red);
		
		for (AActor ActorToDestroy : ActorsToDestroyWithCluster)
		{
			ActorToDestroy.DestroyActor();
		}

		for (AActor EnemySpawner : EnemySpawners)
		{
			EnemySpawner.DestroyActor();
		}

		// if(UnwitherSphere != nullptr)
		// 	UnwitherSphere.UnWither();

		for (ASubmersibleSoilPlantSprayer PlantSprayer : PlantSprayers)
		{
			if(PlantSprayer != nullptr)
			{
				PlantSprayer.SetWaterable(true);
				PlantSprayer.SetSoilEnabled(true);
			}
		}

		if(bConnectToUnwitherSphere)
			UnwitherSphereManager.UnwitherSpheres[UnwitherSphereIndex].UnWither();
		// 	UnwitherSphere.UnWither();

		OnClusterDestroyed.Broadcast();

		GreenhouseDamageComp.DealDamage(DamageAmount);
		DestroyActor();
	}
}
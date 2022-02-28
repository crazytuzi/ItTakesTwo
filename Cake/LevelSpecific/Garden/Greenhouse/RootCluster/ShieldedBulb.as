import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;
import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.GardenUnwitherSphereManager;
import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.GardenEnemySpawnerActor;
import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.GardenUnwitherComponent;

event void FOnShieldedBulbExploded(AShieldedBulb Bulb);
event void FOnShieldedBulbStartedExploding(AShieldedBulb Bulb);
event void FOnShieldedBulbOpened();

class AShieldedBulb : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkeletalMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USphereComponent SphereCollision;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShieldRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ShieldMesh;

	UPROPERTY(DefaultComponent, Attach = ShieldMesh)
	UGardenUnwitherComponent UnwitherComp;

	UPROPERTY(DefaultComponent, Attach = SphereCollision)
	USickleCuttableHealthComponent SickleCuttableComp;
	default SickleCuttableComp.PlayerAttackDistance = FHazeMinMax(0.f, 0.f);
	default SickleCuttableComp.bPlayerAttackDistanceIncludeCollisonRadiuses = true;
	default SickleCuttableComp.MaxHealth = 30.0f;

	UPROPERTY(DefaultComponent, Attach = SphereCollision)
	UVineImpactComponent VineImpact;
	default VineImpact.AttachmentMode = EVineAttachmentType::Whip;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BulbDamageSickleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BulbOpenAudioEvent;

	UPROPERTY()
	FOnShieldedBulbExploded OnBulbExploded;
	UPROPERTY()
	FOnShieldedBulbStartedExploding OnBulbStartedExploding;
	UPROPERTY()
	FOnShieldedBulbOpened OnBulbOpened;

	UPROPERTY(Category="Unwither Sphere Manager")
	bool bConnectToUnwitherSphere = false;
	UPROPERTY(Category="Unwither Sphere Manager", NotEditable)
	AGardenUnwitherSphereManager UnwitherSphereManager;
	UPROPERTY(Category="Unwither Sphere Manager")
	int UnwitherSphereIndex = 0;

	UPROPERTY()
	UNiagaraSystem ImpactEffect;
	
	UPROPERTY()
	UNiagaraSystem DestroyEffect;

	// UPROPERTY()
	// ASeedSprayerWitherSimulation PaintablePlane;

	UPROPERTY(Category="References")
	TArray<ASubmersibleSoilPlantSprayer> PlantSprayers;

	TArray<ASubmersibleSoilPlantSprayer> UnfinishedPlantSprayers;

	UPROPERTY(Category="References")
	TArray<AGardenEnemySpawnerActor> EnemySpawners;

	// UPROPERTY()
	// bool bTypePercentage = false;

	UPROPERTY(Category="References")
	TArray<AActor> SmallRootSplines;	

	UPROPERTY(Category="References")
	TArray<AActor> ActorsToDestroyWithBulb;	

	UPROPERTY(Category="References")
	AGameplayUnwitherSphereActor UnwitherRootSplineActor;

	//Should be in the same order as PlantSprayers
	UPROPERTY(Category="References")
	TArray<AGameplayUnwitherSphereActor> UnwitherSoilRootActors;

	UPROPERTY()
	ASickleEnemyMovementArea MovementArea;
	
	FTimerHandle ExplodeTimerHandler;
	FTimerHandle OpenTimerHandler;
	FTimerHandle EnemySpawnerTimerHandler;
	FTimerHandle POITimerHandler;
	FTimerHandle WitherTimerHandler;
		
	UPROPERTY(Category="Delays")
	float ExplosionDuration = 0.75f;
	UPROPERTY(Category="Delays")
	float OpenBulbDelay = 1.9f;
	UPROPERTY(Category="Delays")
	float POIDelay = 0.35f;
	UPROPERTY(Category="Delays")
	float SpawnEnemiesDelayDuration = 2.0f;
	UPROPERTY(Category="Delays")
	float WitherDelayDuration = 0.0f;
	UPROPERTY(Category="Delays")
	bool bWitherRootWhenStartingExploding = false;

	bool bWitheringDelayStarted = false;

	UPROPERTY(Category="POI")
	float POIDuration = 3.0f;
	UPROPERTY(Category="POI")
	float POIBlendTime = 2.0f;
	UPROPERTY(Category="POI")
	float MinPOIDistance = 5000.0f;

	bool bBroadcastExplosion = true;

	TArray<AHazePlayerCharacter> PlayersInPOIDinstance;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SickleCuttableComp.OnCutWithSickle.AddUFunction(this, n"OnCutWithSickle");
		SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		
		VineImpact.SetCanActivate(false, this);
		VineImpact.OnVineWhipped.AddUFunction(this, n"OnVineWhipped");

		for (ASubmersibleSoilPlantSprayer PlantSprayer : PlantSprayers)
		{
			PlantSprayer.OnPlantedPercentageChange.AddUFunction(this, n"PlantPercentageChanged");
			PlantSprayer.FullyPlanted.AddUFunction(this, n"PlantSprayerFullyPlanted");

			UnfinishedPlantSprayers.Add(PlantSprayer);
		}

		if (EnemySpawners.Num() > 0 && MovementArea != nullptr)
		{
			MovementArea.OnCombatComplete.AddUFunction(this, n"EnemySpawnerAllEnemiesLost");
		}

		if(UnwitherSoilRootActors.Num() > 0)
		{
			for (AGameplayUnwitherSphereActor UnwitherSoilRootActor : UnwitherSoilRootActors)
			{
				UnwitherSoilRootActor.ManuallySetBlendFlowerRootStage1To2(0.0f);	
			}
		}
		

	}

	UFUNCTION()
	void EnemySpawnerAllEnemiesLost(ASickleEnemyMovementArea Area)
	{
		POITimerHandler = System::SetTimer(this, n"StartPointOfInterest", POIDelay, false);
		OpenTimerHandler = System::SetTimer(this, n"OpenBulb", OpenBulbDelay, false);
	}

	UFUNCTION()
	void FindUnwitherManager()
	{
		if(!bConnectToUnwitherSphere)
			return;

		TArray<AActor> UnwitherManagers;
		Gameplay::GetAllActorsOfClass(AGardenUnwitherSphereManager::StaticClass(), UnwitherManagers);

		if(UnwitherManagers.Num() > 0)
			UnwitherSphereManager = Cast<AGardenUnwitherSphereManager>(UnwitherManagers[0]);
	}

	UFUNCTION()
	void PlantPercentageChanged(ASubmersibleSoilPlantSprayer Area, float NewPercentage)
	{
		float ActualPercentage = NewPercentage/Area.RequierdPercentageForFullyPlanted;
		int Index = PlantSprayers.FindIndex(Area);

		if(UnwitherSoilRootActors.Num() > 0)
			UnwitherSoilRootActors[Index].ManuallySetBlendFlowerRootStage1To2(ActualPercentage);	
	}

	UFUNCTION()
	void PlantSprayerFullyPlanted(ASubmersibleSoilPlantSprayer Area)
	{
		int Index = PlantSprayers.FindIndex(Area);

		UnfinishedPlantSprayers.Remove(Area);

		Area.OnPlantedPercentageChange.Clear();

		if(UnwitherSoilRootActors.Num() > 0)	
			UnwitherSoilRootActors[Index].SetFlowerRootStage2();	

		if(UnfinishedPlantSprayers.Num() <= 0)
		{
			if(EnemySpawners.Num() > 0)
			{
				StartSpawningEnemies();
			}
			else
			{
				POITimerHandler = System::SetTimer(this, n"StartPointOfInterest", POIDelay, false);
				OpenTimerHandler = System::SetTimer(this, n"OpenBulb", OpenBulbDelay, false);
			}
		}
	}

	UFUNCTION()
	void StartSpawningEnemies()
	{
		if(EnemySpawners.Num() > 0)
			EnemySpawnerTimerHandler = System::SetTimer(this, n"AllowEnemySpawnersToSpawn", SpawnEnemiesDelayDuration, false);
	}

	UFUNCTION()
	void StartPointOfInterest()
	{
		float DistanceToCody = GetHorizontalDistanceTo(Game::GetCody());
		float DistanceToMay = GetHorizontalDistanceTo(Game::GetMay());

		if(DistanceToCody <= MinPOIDistance)
		{
			PlayersInPOIDinstance.Add(Game::GetCody());
		}
		
		if(DistanceToMay <= MinPOIDistance)
		{
			PlayersInPOIDinstance.Add(Game::GetMay());
		}

		FLookatFocusPointData FocusData;
		FocusData.Actor = this;
		FocusData.ShowLetterbox = false;

		for (AHazePlayerCharacter POIPlayer : PlayersInPOIDinstance)
		{
			LookAtFocusPoint(POIPlayer, FocusData);
		}
	}

	UFUNCTION()
	void OpenBulb()
	{
		OnBulbOpened.Broadcast();
		UnwitherComp.Wither();
		SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		VineImpact.SetCanActivate(true, this);

		UHazeAkComponent::HazePostEventFireForget(BulbOpenAudioEvent, this.GetActorTransform());		
	}

	UFUNCTION()
	void AllowEnemySpawnersToSpawn()
	{
		for (AGardenEnemySpawnerActor EnemySpawner : EnemySpawners)
		{
			EnemySpawner.EnemySpawnManagerComp.EnableSpawning();
			EnemySpawner.EnemySpawnManagerComp.EnableFinish();
		}		
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCutWithSickle(int DamageAmount)
	{
		UHazeAkComponent::HazePostEventFireForget(BulbDamageSickleAudioEvent, this.GetActorTransform());
		
		Niagara::SpawnSystemAtLocation(ImpactEffect, GetActorLocation());
		if(SickleCuttableComp.Health <= 0) 
		{
			StartExploding();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnVineWhipped()
	{
		// This makes the damage
		SickleCuttableComp.ApplyDamage(10, Game::GetCody(), false);

		// This will finalize the damage
		OnCutWithSickle(0);
	}

	UFUNCTION()
	void StartExploding()
	{
		if(UnwitherSoilRootActors.Num() > 0)
		{
			for (AGameplayUnwitherSphereActor UnwitherSoilRootActor : UnwitherSoilRootActors)
			{
				UnwitherSoilRootActor.BlendFlowerRootStage2to3();
				UnwitherSoilRootActor.UnWither();
			}
		}
		
		if (bBroadcastExplosion)
		{
			OnBulbStartedExploding.Broadcast(this);
		}

		SickleCuttableComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		VineImpact.SetCanActivate(false, this);
		Niagara::SpawnSystemAtLocation(DestroyEffect, GetActorLocation());

		if(bConnectToUnwitherSphere && WitherDelayDuration > 0)
		{
			WitherTimerHandler = System::SetTimer(this, n"StartWithering", WitherDelayDuration, false);
			bWitheringDelayStarted = true;
		}

		ExplodeTimerHandler = System::SetTimer(this, n"Explode", ExplosionDuration, false);

		if(bWitherRootWhenStartingExploding && UnwitherRootSplineActor != nullptr)
		{
			UnwitherRootSplineActor.UnWither();
		}
	}

	UFUNCTION()
	void StartWithering()
	{
		UnwitherSphereManager.UnwitherSpheres[UnwitherSphereIndex].UnWither();
	}

	UFUNCTION()
	void ExplodeBulb(bool bShouldBroadcast)
	{	
		bBroadcastExplosion = bShouldBroadcast;
		Explode();
	}

	UFUNCTION()
	void Explode()
	{		
		if(bConnectToUnwitherSphere && !bWitheringDelayStarted)
			UnwitherSphereManager.UnwitherSpheres[UnwitherSphereIndex].UnWither();

		if(!bWitherRootWhenStartingExploding && UnwitherRootSplineActor != nullptr)
		{
			UnwitherRootSplineActor.UnWither();
		}
		
		for (AActor ActorToDestroy : ActorsToDestroyWithBulb)
		{
			if(ActorToDestroy != nullptr)
			{
				ActorToDestroy.DestroyActor();
			}
		}

		if(SmallRootSplines.Num() > 0)
		{
			for (AActor RootSpline : SmallRootSplines)
			{
				if(RootSpline != nullptr)
					RootSpline.DestroyActor();
			}
		}

		System::ClearAndInvalidateTimerHandle(ExplodeTimerHandler);
		System::ClearAndInvalidateTimerHandle(EnemySpawnerTimerHandler);
		System::ClearAndInvalidateTimerHandle(POITimerHandler);
		System::ClearAndInvalidateTimerHandle(OpenTimerHandler);
		System::ClearAndInvalidateTimerHandle(WitherTimerHandler);

		if (bBroadcastExplosion)
		{
			OnBulbExploded.Broadcast(this);
		}

		Game::GetMay().SetCapabilityActionState(GardenAudioActions::ShieldedBuldExplosion, EHazeActionState::Active);

		if(SmallRootSplines.Num() > 0)
		{
			for (AActor SmallRootSpline : SmallRootSplines)
			{
				if(SmallRootSpline != nullptr)
					SmallRootSpline.DestroyActor();
			}
		}

		DestroyActor();
	}
}

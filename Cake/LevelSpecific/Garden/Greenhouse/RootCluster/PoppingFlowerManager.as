import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.PoppingFlowerActor;
import Cake.LevelSpecific.Garden.ControllablePlants.Seeds.SeedSprayerSystem;

class APoppingFlowerManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = "Billboard")
	UTextRenderComponent ManagerText;
	default ManagerText.SetText(FText::FromString("Popping Flower Manager"));
	default ManagerText.SetHorizontalAlignment(EHorizTextAligment::EHTA_Center);
	default ManagerText.SetVerticalAlignment(EVerticalTextAligment::EVRTA_TextCenter);
	default ManagerText.SetHiddenInGame(true);
	default ManagerText.XScale = 2;
	default ManagerText.YScale = 2;

	UPROPERTY(Category="References")
	ASubmersibleSoilPlantSprayer PlantSprayer;

	UPROPERTY(Category="References")
	TArray<APoppingFlowerActor> PoppingFlowers;

	UPROPERTY()
	bool bShufflePoppingFlowers = false;

	int NextIndex = 0;

	bool bStartPopping = false;

	float Timer = 0.0f;

	float CurrentDelay = 0.2f;

	float MinDelay = 0.1f;
	float MaxDelay = 0.35f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlantSprayer.FullyPlanted.AddUFunction(this, n"PlantSprayerFullyPlanted");

		if(bShufflePoppingFlowers)
			PoppingFlowers.Shuffle();	
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bStartPopping)
		{
			Timer += DeltaTime;

			if(Timer > CurrentDelay)
			{
				PopNextFlower(NextIndex);
				NextIndex++;

				if(NextIndex < PoppingFlowers.Num())
				{
					ResetTimer();
				}
				else
				{
					SetActorTickEnabled(false);
				}
			}
		}
	}

	UFUNCTION()
	void ResetTimer()
	{
		Timer = 0.0f;
		CurrentDelay = FMath::RandRange(MinDelay, MaxDelay);
	}

	UFUNCTION()
	void PlantSprayerFullyPlanted(ASubmersibleSoilPlantSprayer Area)
	{
		bStartPopping = true;
		ResetTimer();
	}

	UFUNCTION()
	void PopNextFlower(int NextFlowerIndex)
	{
		PoppingFlowers[NextFlowerIndex].PopUp();
	}
}

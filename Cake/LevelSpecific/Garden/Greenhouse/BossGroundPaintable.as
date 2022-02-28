import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.Greenhouse.Joy;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Garden.Greenhouse.PaintablePlaneContainer;

class ABossGroundPaintable : APaintablePlaneContainer
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MeshBody;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UWaterHoseImpactComponent WaterImpactComp;

	UPROPERTY()
	AJoy Joy;

	UPROPERTY()
	AActor ClearGooAroundSpawnPointLocation;

	UPROPERTY(Category = "Water")
	FLinearColor WaterColor = FLinearColor(0.f, 0.f, 0.f, 0.f);

	UPROPERTY(Category = "Water")
	float ImpactCleanRadius = 450.f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UNiagaraComponent KeyBeam;

	bool Active = false;
	float GooIntervalTemp;
	float GooInterval = 8;
	bool bClearGoAroundSoul = false;
	bool bClearGoAroundSpawnPoint = false;
	float floatKeepWatering = 0;
	FVector WaterImpactLocation;
	AHazePlayerCharacter PlayerTarget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterImpactComp.OnWaterProjectileImpact.AddUFunction(this, n"Watered");
		GooIntervalTemp = GooInterval;
	}

	UFUNCTION(BlueprintCallable)
	void StartPaintablePlane()
	{
		Game::GetCody().SetCapabilityActionState(n"GooActive", EHazeActionState::Active);
		Game::GetMay().SetCapabilityActionState(n"GooActive", EHazeActionState::Active);
		Joy.SetCapabilityActionState(n"SapPlaneActivated", EHazeActionState::Active);
		Joy.SetCapabilityAttributeObject(n"PaintablePlane", PaintablePlane);

		Active = true;
		PlayerTarget = Game::GetCody();
	}


	UFUNCTION(BlueprintCallable)
	void StopPaintablePlane()
	{
		Game::GetCody().SetCapabilityActionState(n"GooActive", EHazeActionState::Inactive);
		Game::GetMay().SetCapabilityActionState(n"GooActive", EHazeActionState::Inactive);

		Joy.SetCapabilityActionState(n"SapPlaneDeactivated", EHazeActionState::Active);
		Active = false;
	}


	UFUNCTION(NotBlueprintCallable)
	void Watered(FHitResult Impact)
	{
		if(PaintablePlane != nullptr && Impact.bBlockingHit)
		{
			WaterImpactLocation = Impact.ImpactPoint;
			floatKeepWatering = 0.5f;
		}	
	}

	UFUNCTION()
	void ClearGooAroundSoil()
	{
		bClearGoAroundSoul = true;
		System::SetTimer(this, n"StopClearingGooAroundSoil", 2.0f, false);
	}
	UFUNCTION()
	void StopClearingGooAroundSoil()
	{
		bClearGoAroundSoul = false;
	}

	UFUNCTION()
	void ClearGooAroundSpawnPoint()
	{
		if(Active == false)
			return;

		bClearGoAroundSpawnPoint = true;
		System::SetTimer(this, n"StopClearingGooAroundSpawnPoint", 1.0f, false);
	}
	UFUNCTION()
	void StopClearingGooAroundSpawnPoint()
	{
		bClearGoAroundSpawnPoint = false;
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!Active)
			return;
		
		if(floatKeepWatering > 0)
		{
			floatKeepWatering -= DeltaTime;
			PaintablePlane.LerpAndDrawTexture(WaterImpactLocation, ImpactCleanRadius, WaterColor,  FLinearColor(0.f, 0.f, 0.25f, 0.f), true, nullptr, true, FLinearColor(15,15,15));
		}	

		if(bClearGoAroundSoul)
			PaintablePlane.LerpAndDrawTexture(FVector(-12395, 31141, 4851), 735, WaterColor,  FLinearColor(0.f, 0.f, 0.75f, 0.f) * DeltaTime * 10, true, nullptr, true, FLinearColor(15,15,15));

		if(bClearGoAroundSpawnPoint)
			PaintablePlane.LerpAndDrawTexture(FVector(ClearGooAroundSpawnPointLocation.GetActorLocation()), 600, WaterColor,  FLinearColor(0.f, 0.f, 0.75f, 0.f) * DeltaTime * 10, true, nullptr, true, FLinearColor(15,15,15));
	}
}


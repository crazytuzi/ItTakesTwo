
class AJoyDecalManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY()
	TArray<ADecalActor> Decals;

	FHazeAcceleratedFloat AcceleratedFloat;
	TArray<UMaterialInstanceDynamic> MaterialInstances;

	bool AccelerateUp = false;
	bool AccelerateDown = false;

	UPROPERTY()
	bool PrintDev = false;
	UPROPERTY()
	bool DisabledFromStart = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(ADecalActor Decal : Decals)
		{
			UMaterialInstanceDynamic MaterialInstance = Decal.Decal.CreateDynamicMaterialInstance();
			MaterialInstances.AddUnique(MaterialInstance);
		
			if(DisabledFromStart)
			{
				for(UMaterialInstanceDynamic Material : MaterialInstances)
				{
					Material.SetScalarParameterValue(n"OpacityFade", 0);
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(PrintDev)
		{
			Print("AcceleratedFloat " + AcceleratedFloat.Value);
			Print("AccelerateUp " + AccelerateUp);
			Print("AccelerateDown " + AccelerateDown);
		}


		if(AccelerateUp == true)
		{
			AcceleratedFloat.SpringTo(1.1, 1, 0.9f, DeltaSeconds);
			if(AcceleratedFloat.Value >= 1)
			{
				AccelerateUp = false;
			}
		}

		if(AccelerateDown == true)
		{
			AcceleratedFloat.SpringTo(-0.1, 0.5f, 0.9f, DeltaSeconds);
			if(AcceleratedFloat.Value <= 0)
			{
				AccelerateDown = false;
			}
		}

		if(AccelerateUp == true or AccelerateDown == true)
		{
			for(UMaterialInstanceDynamic Material : MaterialInstances)
			{
				Material.SetScalarParameterValue(n"OpacityFade", AcceleratedFloat.Value);
			}
		}
	}

	UFUNCTION()
	void FadeInDecals()
	{	
		if(!AccelerateDown)
		{
			AccelerateUp = true;
		}
	}

	UFUNCTION()
	void FadeOutDecals()
	{	
		if(!AccelerateUp)
		{
			AccelerateDown = true;
		}
	}
}


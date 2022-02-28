import Cake.LevelSpecific.Garden.LevelActors.FrogPond.FrogPondTrellisPlatform;
import Cake.LevelSpecific.Garden.LevelActors.WateringPlantActor;

event void TrellisPlantLeavesUp();
event void TrellisPlantLeavesDown();

class AFrogPondTrellisPlants : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent StemMeshComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;
	default DisableComp.bRenderWhileDisabled = true;

	UPROPERTY(Category = "Setup")
	TArray<AFrogPondTrellisPlatform> PlatformArray;

	UPROPERTY(Category = "Setup")
	AWateringPlantActor ConnectedWateringPlant;

	UPROPERTY()
	TrellisPlantLeavesUp AudioTrellisPlantLeavesUp;

	UPROPERTY()
	TrellisPlantLeavesDown AudioTrellisPlantLeavesDown;

	float CurrentMaterialValue = 0.f;
	float TargetMaterialValue = 0.f;

	bool bLeavesAreRising = false;
	bool bLeavesAreFalling = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(ConnectedWateringPlant != nullptr)
		{
			ConnectedWateringPlant.WaterHoseComp.OnWateringBegin.AddUFunction(this, n"OnWateringBegin");
			ConnectedWateringPlant.WaterHoseComp.OnWateringEnd.AddUFunction(this, n"OnWateringEnd");

			ConnectedWateringPlant.WaterHoseComp.OnFullyWithered.AddUFunction(this, n"OnFullyWithered");
		}

		for(auto Platform : PlatformArray)
		{
			Platform.InitializePlatform();

			if(Platform.DynamicMaterialInstance != nullptr)
				Platform.DynamicMaterialInstance.SetScalarParameterValue(n"BlendValue", 0.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(CurrentMaterialValue != TargetMaterialValue)
		{
			float NewMaterialValue = FMath::FInterpConstantTo(CurrentMaterialValue, TargetMaterialValue, DeltaTime, 1.f);
			SetShaderParamValue(NewMaterialValue);
			CurrentMaterialValue = NewMaterialValue;
		}
		else if(CurrentMaterialValue == TargetMaterialValue && TargetMaterialValue == 0.f)
		{
			SetPlatformCollision(false);
			SetActorTickEnabled(false);
		}

		if(!bLeavesAreRising && CurrentMaterialValue > 0)
		{
			bLeavesAreRising = true;
			AudioTrellisPlantLeavesUp.Broadcast();
		}
		else if(CurrentMaterialValue == 0)
			bLeavesAreRising = false;

		if(!bLeavesAreFalling && CurrentMaterialValue < 1)
		{
			bLeavesAreFalling = true;
			AudioTrellisPlantLeavesDown.Broadcast();
		}
		else if(CurrentMaterialValue == 1)
			bLeavesAreFalling = false;
	}

	UFUNCTION()
	void OnFullyWithered()
	{
		TargetMaterialValue = 0.f;
	}

	UFUNCTION()
	void OnWateringBegin()
	{
		SetActorTickEnabled(true);
		TargetMaterialValue = 1.f;
		SetPlatformCollision(true);
	}

	UFUNCTION()
	void OnWateringEnd()
	{

	}

	void SetShaderParamValue(float Value)
	{
		for (auto Platform : PlatformArray)
		{
			Platform.DynamicMaterialInstance.SetScalarParameterValue(n"BlendValue", Value);
		}
	}

	void SetPlatformCollision(bool Enabled)
	{
		if(Enabled)
		{
			//AudioTrellisPlantLeavesUp.Broadcast();
			for (auto Platform : PlatformArray)
			{
				Platform.PlatformMesh.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			}
		}
		else
		{
			for (auto Platform : PlatformArray)
			{
				Platform.PlatformMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
		}

	}
}
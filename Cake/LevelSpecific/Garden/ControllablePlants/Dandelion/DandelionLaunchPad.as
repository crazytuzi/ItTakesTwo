import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.Dandelion;
import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionLaunchComponent;
import Cake.LevelSpecific.Garden.LevelActors.WateringPlantActor;

UCLASS(Abstract, HideCategories = "Rendering Debug Actor Input Replication LOD Cooking")
class ADandelionLaunchPad : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = WindLauncherSocket)
	UNiagaraComponent WindNiagaraComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY(DefaultComponent, Attach = SkeletalMesh, AttachSocket = WindLauncherSocket)
	UStaticMeshComponent WindTrigger;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USkeletalMeshComponent SkeletalMesh;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UDandelionLaunchComponent DandelionLaunchComp;

	UPROPERTY()
	AWateringPlantActor WateringPlant;

	UPROPERTY(Category = "Properties")
	float LeafRotationSpeed = 800.f;

	UPROPERTY(Category = "Properties")
	bool bRequireWatering = true;

	UPROPERTY()
	bool bActive = true;

	UFUNCTION(BlueprintEvent)
	void BP_LaunchPadStart()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchPadStop()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_LaunchPadWindBoost()
	{}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bRequireWatering)
		{
			bActive = false;
		}

		WindTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (WateringPlant != nullptr && WateringPlant.WaterHoseComp != nullptr)
		{
			const float WaterLevel = GetCurrentWaterLevel();
			float CurRot = FMath::ExpoIn(75.f, 0.f, WaterLevel);

			float AlphaValue = FMath::GetMappedRangeValueClamped(FVector2D(0.4f, 1.f),FVector2D(0.f, 1.f), WaterLevel);
			WindNiagaraComp.SetFloatParameter(n"AlphaScale", AlphaValue);

			if(WaterLevel <= 0.4f && WindTrigger.CollisionEnabled != ECollisionEnabled::NoCollision)
			{
				bActive = false;
				WindTrigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);
			}
			else if(WaterLevel > 0.4f && WindTrigger.CollisionEnabled != ECollisionEnabled::QueryOnly)
			{
				bActive = true;
				WindTrigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
			}
			
			if (WaterLevel > 0.f)
			{
				WindNiagaraComp.Activate();
				BP_LaunchPadStart();
			}

			if (WaterLevel == 0.f)
			{
				WindNiagaraComp.Deactivate();
				BP_LaunchPadStop();
			}
		}
	}

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
       ADandelion Dandelion = Cast<ADandelion>(OtherActor);

	   if(Dandelion == nullptr || (Dandelion != nullptr && !Dandelion.HasControl()))
		   return;

		Dandelion.LaunchDandelion(LaunchPadPower, DandelionLaunchComp.LaunchTime);

		Dandelion.SetAnimBoolParam(n"Launched", true);

		BP_LaunchPadWindBoost();
    }

	float GetLaunchPadPower() const property
	{
		if (bActive)
		{
			return DandelionLaunchComp.LaunchHeight;
		}
		
		return 0.f;
	}

	float GetCurrentWaterLevel() const property
	{
		if(!bRequireWatering)
		{
			return 1.0f;
		}

		return WateringPlant.WaterHoseComp.CurrentWaterLevel;
	}
}

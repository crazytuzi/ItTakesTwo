import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;

UCLASS(Abstract)
class AWaterableCatapult : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ArmRoot;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	UStaticMeshComponent ArmMesh;

	UPROPERTY(DefaultComponent, Attach = ArmRoot)
	USceneComponent BucketRoot;
	
	UPROPERTY(DefaultComponent, Attach = BucketRoot)
	UStaticMeshComponent BucketMesh;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseImpactComp;
	default WaterHoseImpactComp.TimeUntilDecay = 1.0f;

	UPROPERTY(DefaultComponent, Attach = BucketMesh)
	USickleCuttableComponent SickleCuttableComponent;	

	UPROPERTY(EditDefaultsOnly)
	TArray<FWaterLevelColor> Colors;

	UPROPERTY()
	bool bPreviewFullyWatered = false;

	UPROPERTY()
	float FullyWateredRotation = 10.f;

	UPROPERTY()
	float WitheredRotation = -90.f;

	UPROPERTY()
	float WitheredScale = 0.5f;

	UPROPERTY()
	float LaunchDecaySpeed = 10.0f;
	UPROPERTY()
	float LaunchDecayAccelerationSpeed = 1.0f;
	UPROPERTY()
	float LaunchTimeUntilDecay = 0.1f;
	
	float DefaultTimeUntilDecay;
	float DefaultDecaySpeed;
	float DefaultDecayAccelerationSpeed;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewFullyWatered)
		{
			ArmRoot.SetRelativeRotation(FRotator(FullyWateredRotation, 0.f, 0.f));
			ArmRoot.SetRelativeScale3D(FVector(1.0f, 1.0f, 1.0f));
		}
		else
		{
			ArmRoot.SetRelativeRotation(FRotator(WitheredRotation, 0.f, 0.f));
			ArmRoot.SetRelativeScale3D(FVector(1.0f, WitheredScale, WitheredScale));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterHoseImpactComp.OnHitWithWater.AddUFunction(this, n"Watered");
		WaterHoseImpactComp.OnFullyWatered.AddUFunction(this, n"FullyWatered");
		WaterHoseImpactComp.OnFullyWithered.AddUFunction(this, n"FullyWithered");
		SickleCuttableComponent.OnCutWithSickle.AddUFunction(this, n"HitWithSickle");
		SickleCuttableComponent.ChangeValidActivator(EHazeActivationPointActivatorType::None);

		DefaultTimeUntilDecay = WaterHoseImpactComp.TimeUntilDecay;
		DefaultDecaySpeed = WaterHoseImpactComp.DecaySpeed;
		DefaultDecayAccelerationSpeed = WaterHoseImpactComp.DecayAccelerationSpeed;
	}

	UFUNCTION()
	void FullyWatered()
	{
		WaterHoseImpactComp.TimeUntilDecay = 0.0f;
		SickleCuttableComponent.ChangeValidActivator(EHazeActivationPointActivatorType::May);
	}

	UFUNCTION()
	void FullyWithered()
	{
		WaterHoseImpactComp.DecaySpeed = DefaultDecaySpeed;
		WaterHoseImpactComp.TimeUntilDecay = DefaultTimeUntilDecay;
	}


	UFUNCTION()
	void LaunchCatapult()
	{
		WaterHoseImpactComp.TimeUntilDecay = LaunchTimeUntilDecay;
		WaterHoseImpactComp.DecaySpeed = LaunchDecaySpeed;
		WaterHoseImpactComp.DecayAccelerationSpeed = LaunchDecayAccelerationSpeed;
	}

	UFUNCTION()
	void HitWithSickle(int DamageAmout)
	{
		WaterHoseImpactComp.TimeUntilDecay = DefaultTimeUntilDecay;
		SickleCuttableComponent.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		LaunchCatapult();		
	}


	UFUNCTION(NotBlueprintCallable)
	void Watered()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurPitch = FMath::Lerp(WitheredRotation, FullyWateredRotation, WaterHoseImpactComp.CurrentWaterLevel);
		float CurScale = FMath::Lerp(WitheredScale, 1.0f, WaterHoseImpactComp.CurrentWaterLevel);
		ArmRoot.SetRelativeRotation(FRotator(CurPitch, 0.f, 0.f));
		ArmRoot.SetRelativeScale3D(FVector(1.0f, CurScale, CurScale));

		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(ArmMesh, Colors);
	}
}
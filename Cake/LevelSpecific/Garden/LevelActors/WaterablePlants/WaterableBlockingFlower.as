import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

UCLASS(Abstract)
class AWaterableBlockingFlower : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent Leaf1Root;

	UPROPERTY(DefaultComponent, Attach = Leaf1Root)
	UStaticMeshComponent Leaf1Mesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent Leaf2Root;

	UPROPERTY(DefaultComponent, Attach = Leaf2Root)
	UStaticMeshComponent Leaf2Mesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent Leaf1bRoot;

	UPROPERTY(DefaultComponent, Attach = Leaf1bRoot)
	UStaticMeshComponent Leaf1bMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent Leaf2bRoot;

	UPROPERTY(DefaultComponent, Attach = Leaf2bRoot)
	UStaticMeshComponent Leaf2bMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent WateringMesh;

	UPROPERTY(DefaultComponent, Attach = WateringMesh)
	UWaterHoseImpactComponent WaterHoseImpactComp;
	default WaterHoseImpactComp.ImpactValidation = EWaterImpactType::ParentComponent;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 40000.f;

	UPROPERTY(EditDefaultsOnly)
	TArray<FWaterLevelColor> Colors;

	UPROPERTY()
	bool bPreviewFullyWatered = false;

	UPROPERTY()
	float HowMuchRotationToAdd = 45.0f;

	float Leaf1StartRotation;

	float Leaf2StartRotation;
	
	float Leaf1bStartRotation = 20.f;

	float Leaf2bStartRotation = -20.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewFullyWatered)
		{
			Leaf1Root.SetRelativeRotation(FRotator(0.f, 0.f, Leaf1StartRotation + HowMuchRotationToAdd));
			Leaf2Root.SetRelativeRotation(FRotator(0.f, 0.f, Leaf2StartRotation - HowMuchRotationToAdd));
			Leaf1bRoot.SetRelativeRotation(FRotator(0.f, 0.f, Leaf1bStartRotation + HowMuchRotationToAdd));
			Leaf2bRoot.SetRelativeRotation(FRotator(0.f, 0.f, Leaf2bStartRotation - HowMuchRotationToAdd));
		}
		else
		{
			Leaf1Root.SetRelativeRotation(FRotator(0.f, 0.f, Leaf1StartRotation));
			Leaf2Root.SetRelativeRotation(FRotator(0.f, 0.f, Leaf2StartRotation));
			Leaf1bRoot.SetRelativeRotation(FRotator(0.f, 0.f, Leaf1bStartRotation));
			Leaf2bRoot.SetRelativeRotation(FRotator(0.f, 0.f, Leaf2bStartRotation));
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WaterHoseImpactComp.OnHitWithWater.AddUFunction(this, n"Watered");
		WaterHoseImpactComp.OnFullyWatered.AddUFunction(this, n"FullyWatered");
	}

	UFUNCTION(NotBlueprintCallable)
	void Watered()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float Cur1Pitch = FMath::Lerp(Leaf1StartRotation, Leaf1StartRotation + HowMuchRotationToAdd, WaterHoseImpactComp.CurrentWaterLevel);
		float Cur2Pitch = FMath::Lerp(Leaf2StartRotation, Leaf2StartRotation - HowMuchRotationToAdd, WaterHoseImpactComp.CurrentWaterLevel);
		
		Leaf1Root.SetRelativeRotation(FRotator(0.f, 0.f, Cur1Pitch));
		Leaf2Root.SetRelativeRotation(FRotator(0.f, 0.f, Cur2Pitch));

		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(Leaf1Mesh, Colors);
		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(Leaf2Mesh, Colors);

		float Cur1bPitch = FMath::Lerp(Leaf1bStartRotation, Leaf1bStartRotation + HowMuchRotationToAdd, WaterHoseImpactComp.CurrentWaterLevel);
		float Cur2bPitch = FMath::Lerp(Leaf2bStartRotation, Leaf2bStartRotation - HowMuchRotationToAdd, WaterHoseImpactComp.CurrentWaterLevel);
		
		Leaf1bRoot.SetRelativeRotation(FRotator(0.f, 0.f, Cur1bPitch));
		Leaf2bRoot.SetRelativeRotation(FRotator(0.f, 0.f, Cur2bPitch));

		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(Leaf1bMesh, Colors);
		WaterHoseImpactComp.UpdateColorBasedOnWaterLevel(Leaf2bMesh, Colors);
	}

	UFUNCTION()
	void FullyWatered()
	{
		WaterHoseImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}
}
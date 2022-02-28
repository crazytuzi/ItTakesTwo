import Vino.Movement.Swinging.SwingComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

class AWaterableSwingPoint : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SwingPointMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USwingPointComponent SwingComp;
	default SwingComp.ValidationType = EHazeActivationPointActivatorType::None;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.f;

	UPROPERTY()
	UCurveFloat WitherCurve;

	UPROPERTY(EditDefaultsOnly)
	FVector StartScale;

	UMaterialInstanceDynamic Material;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SwingPointMesh.SetRelativeScale3D(StartScale);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Material = SwingPointMesh.CreateDynamicMaterialInstance(0);
		WaterHoseComp.OnFullyWatered.AddUFunction(this, n"FullyWatered");
	}

	UFUNCTION()
	void FullyWatered()
	{
		SwingComp.ChangeValidActivator(EHazeActivationPointActivatorType::Both);
		WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float NewWitherValue = WitherCurve.GetFloatValue(WaterHoseComp.CurrentWaterLevel);
		Material.SetScalarParameterValue(n"BlendValue", NewWitherValue);

		// if (CurScale == FVector(1.f, 1.f, 2.f))
		// 	SetActorTickEnabled(false);
	}
}
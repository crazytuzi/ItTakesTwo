import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;

	UCLASS(Abstract)
class AWaterableRamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RampRoot;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseComp;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh RampMesh;

	UPROPERTY()
	int RampSegments = 2.f;

	UPROPERTY()
	float MaxAngle = 35.f;

	UPROPERTY()
	bool bPreviewMaxAngle = false;

	UPROPERTY(NotEditable, NotVisible)
	TArray<UStaticMeshComponent> RampMeshes;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		RampMeshes.Empty();

		for (int Index = 0, Count = RampSegments; Index < Count; ++ Index)
		{
			UStaticMeshComponent CurMeshComp = UStaticMeshComponent::Create(this);
			CurMeshComp.SetStaticMesh(RampMesh);
			CurMeshComp.AttachToComponent(RampRoot);
			CurMeshComp.SetRelativeLocation(FVector(1000.f * Index, 0.f, 0.f));
			CurMeshComp.SetRelativeScale3D(FVector(1.f, 2.f, 0.2f));
			RampMeshes.Add(CurMeshComp);
		}

		if (bPreviewMaxAngle)
			RampRoot.SetRelativeRotation(FRotator(MaxAngle, 0.f, 0.f));
		else
			RampRoot.SetRelativeRotation(FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurAngle = FMath::Lerp(0.f, MaxAngle, WaterHoseComp.CurrentWaterLevel);
		RampRoot.SetRelativeRotation(FRotator(CurAngle, 0.f, 0.f));
	}
}
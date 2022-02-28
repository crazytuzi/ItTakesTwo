import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
UCLASS(Abstract)
class AVineWall : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(EditDefaultsOnly)
	UStaticMesh WallMesh;

	UPROPERTY(NotEditable, NotVisible)
	TArray<UStaticMeshComponent> WallMeshes;

	UPROPERTY(DefaultComponent)
	UWaterHoseImpactComponent WaterHoseComp;

	UPROPERTY()
	int Width = 2;

	UPROPERTY()
	int Height = 2;

	UPROPERTY()
	bool IsWaterable = false;

	UPROPERTY()
	float TimeUntilDecay = 4;
	
	UPROPERTY()
	float DecaySpeedModifer = 1;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		WaterHoseComp.TimeUntilDecay = TimeUntilDecay;
		WaterHoseComp.DecaySpeed  = DecaySpeedModifer;
    }

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		WallMeshes.Empty();

		for (int HeightIndex = 0; HeightIndex < Height; ++ HeightIndex)
		{
			for (int Index = 0; Index < Width; ++ Index)
			{
				UStaticMeshComponent CurMeshComp = UStaticMeshComponent::Create(this);
				CurMeshComp.SetStaticMesh(WallMesh);
				CurMeshComp.SetRelativeRotation(FRotator(90.f, 0.f, 0.f));
				FVector Loc = FVector(0.f, 500.f * Index, 0.f) + FVector(0.f, 0.f, HeightIndex * 1000.f);
				CurMeshComp.SetRelativeLocation(Loc);
				WallMeshes.Add(CurMeshComp);
			}
		}
	}
}
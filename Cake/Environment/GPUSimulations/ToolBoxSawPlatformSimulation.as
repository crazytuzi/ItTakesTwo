import Rice.RenderTextureDrawing.RenderTextureDrawing;
import Cake.Environment.GPUSimulations.Simulation;
import Cake.Environment.GPUSimulations.PaintablePlane;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseImpactComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Shed.ToolBoxBoss.ToolBoxBossSawPlatform;

class AToolBoxSawPlatformSimulation : APaintablePlane
{
	UPROPERTY(Category = "Options")
	AToolBoxBossSawPlatform ToolBoxSawPlatform;
	
	UPROPERTY(Category = "Options")
	AActor BuzzSaw;

	UPROPERTY(Category = "Options")
	float PlatformSize = 1500;

	UPROPERTY()
	bool ShouldPaint = false;

	FVector WorldLocationToTextureLocation(FVector WorldLocation) const override
	{
		FVector LocalPosition = ToolBoxSawPlatform.GetActorTransform().InverseTransformPosition(WorldLocation);
		LocalPosition /= PlatformSize;
		LocalPosition += FVector::OneVector;
		LocalPosition *= 0.5;
		//LocalPosition = FVector(FMath::Clamp(LocalPosition.X, 0.0f, 1.0f), FMath::Clamp(LocalPosition.Y, 0.0f, 1.0f), 0);
		
		return FVector(LocalPosition.X, LocalPosition.Y, 0);
	}

	FVector TextureLocationToWorldLocation(FVector TextureLocation) const override { return FVector::ZeroVector; }

	float WorldRadiusToTextureRadius(float WorldRadius) const override { return WorldRadius; }

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Super::ConstructionScript();
	}
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Super::BeginPlay();
		LastActorLocation = BuzzSaw.GetActorLocation();
		LerpAndDrawTexture(LastActorLocation, 0.03f, FLinearColor(1,1,1,1), FLinearColor(1,1,1,1));
	}
	
	FVector LastActorLocation = FVector::ZeroVector;
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		if(BuzzSaw.GetActorLocation() != LastActorLocation && ShouldPaint)
		{
			LastActorLocation = BuzzSaw.GetActorLocation();
			LerpAndDrawTexture(LastActorLocation, 0.03f, FLinearColor(1,1,1,1), FLinearColor(1,1,1,1));
		}
	}
}
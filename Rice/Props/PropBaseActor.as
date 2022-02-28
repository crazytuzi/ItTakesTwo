import Peanuts.Spline.SplineComponent;

UCLASS(HideCategories = "Shape Lighting Navigation Physics Activation Cooking Input Mobile HLOD AssetUserData")
class UTagContainerComponent : USphereComponent
{
    default bIsEditorOnly = true;
    default bHiddenInGame = true;
    default bVisible = false;
	default SetCollisionEnabled(ECollisionEnabled::NoCollision);
};

UCLASS(HideCategories = "Rendering StaticMesh Physics Collision Shape Actor Cooking Input")
class APropBaseActor : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
    default Root.Mobility = EComponentMobility::Static;

    UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
    UTagContainerComponent TagContainer;
    default TagContainer.Mobility = EComponentMobility::Static;

	UFUNCTION(BlueprintEvent)
	TArray<UStaticMesh> GetUsedMeshes()
	{
		TArray<UStaticMesh> Meshes;
		return Meshes;
	}

	UFUNCTION(BlueprintEvent)
	UStaticMeshComponent BPSplineMeshGetReplacementMesh() // Implemented in BP
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	TArray<USplineMeshComponent> BPSplineMeshGetMeshComponents() // Implemented in BP
	{
		return TArray<USplineMeshComponent>();
	}

	UFUNCTION(BlueprintEvent)
	UHazeSplineComponent BPSplineMeshGetSpline() // Implemented in BP
	{
		return nullptr;
	}
}

UFUNCTION(Category = "Collision")
void MarkGenerateOverlapsDuringStreaming(AActor Actor)
{
	Actor.bGenerateOverlapEventsDuringLevelStreaming = true;
}
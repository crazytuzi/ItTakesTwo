UCLASS(Abstract)
class AClockTownFallenTree : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent TreeBottomMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent TreeTopMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeSkeletalMeshComponentBase Lumberjack;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat TreeFallCurve;

	UPROPERTY(EditDefaultsOnly)
	UCurveFloat ChopCurve;

	float MaxRotation = 108.f;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PlatformMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PlatformMesh) * CullDistanceMultiplier);
		TreeBottomMesh.SetCullDistance(Editor::GetDefaultCullingDistance(TreeBottomMesh) * CullDistanceMultiplier);
		TreeTopMesh.SetCullDistance(Editor::GetDefaultCullingDistance(TreeTopMesh) * CullDistanceMultiplier);
		Lumberjack.SetCullDistance(Editor::GetDefaultCullingDistance(Lumberjack) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}
}
class AClockTownPigHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent HatchMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		PlatformMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PlatformMesh) * CullDistanceMultiplier);
		HatchMesh.SetCullDistance(Editor::GetDefaultCullingDistance(HatchMesh) * CullDistanceMultiplier);
	}

	UFUNCTION()
	void StartHatchSequence()
	{
		BP_StartHatchSequence();
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartHatchSequence() {}
}
event void FClockTownGuardedGateEvent();

UCLASS(Abstract)
class AClockTownGuardedGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent DoorMesh;

	UPROPERTY()
	FClockTownGuardedGateEvent OnGateOpened;

	UPROPERTY()
	FClockTownGuardedGateEvent OnGateClosed;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DoorMesh.SetCullDistance(Editor::GetDefaultCullingDistance(DoorMesh) * CullDistanceMultiplier);
	}

	UFUNCTION()
	void OpenGate()
	{
		BP_OpenGate();
	}

	UFUNCTION()
	void CloseGate()
	{
		BP_CloseGate();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenGate() {}

	UFUNCTION(BlueprintEvent)
	void BP_CloseGate() {}
}
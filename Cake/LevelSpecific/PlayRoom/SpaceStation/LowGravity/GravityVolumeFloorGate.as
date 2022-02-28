class AGravityVolumeFloorGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent FloorRoot;

	UPROPERTY(DefaultComponent, Attach = FloorRoot)
	UStaticMeshComponent FloorMesh;

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
UCLASS(Abstract)
class ASizeBasedValveCog : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CogRoot;

	UPROPERTY(DefaultComponent, Attach = CogRoot)
	UStaticMeshComponent CogMesh;

	UPROPERTY(NotEditable)
	float CurrentLerpValue = 0.f;

	UPROPERTY()
	FRotator TargetRot = FRotator(0.f, 0.f, -720.f);

	void UpdateLerpValue(float Value)
	{
		CurrentLerpValue = Value;
		BP_UpdateRotation();
	}

	UFUNCTION(BlueprintEvent)
	void BP_UpdateRotation() {}
}

class APinWheelTurbineToy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Base;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SpinningWheel;

	bool bStartMoving = false;

	UPROPERTY()
	float SpinSpeed = -20;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bStartMoving = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bStartMoving)
			return;

		SpinningWheel.AddLocalRotation(FRotator(0, 0, SpinSpeed * DeltaSeconds * 6));
	}
}



class ABackstageFallbouncePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;

	FHazeAcceleratedFloat AcceleratedFloat;
	bool bStartMoving = false;
	float TargetPitchValue = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay(){}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStartMoving)
		{
			AcceleratedFloat.SpringTo(-15.4, 120, 0.85f, DeltaSeconds);
			TargetPitchValue = AcceleratedFloat.Value;
			PlatformMesh.SetRelativeRotation(FRotator(0, 0, TargetPitchValue));
		}
	}

	UFUNCTION()
	void StartPlatform()
	{
		if(Game::GetCody().HasControl())
		{
			NetStartPlatform();
		}
	}
	UFUNCTION(NetFunction)
	void NetStartPlatform()
	{
		bStartMoving = true;
	}
}


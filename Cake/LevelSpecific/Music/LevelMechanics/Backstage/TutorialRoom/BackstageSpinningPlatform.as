
class ABackstageSpinningPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent PlatformMesh;
	bool bStartMoving = false;
	FRotator OriginalRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalRotation = GetActorRotation();
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bStartMoving)
		{
			AddActorLocalRotation(FRotator(1.35,0,0));

			FRotator RelativeRotation;
			RelativeRotation.Yaw = FMath::Sin(Time::GameTimeSeconds * 1.15f) * 2.f;
			PlatformMesh.SetRelativeRotation(RelativeRotation);
		}
	}


	UFUNCTION()
	void StartPlatform()
	{
		if(this.HasControl())
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


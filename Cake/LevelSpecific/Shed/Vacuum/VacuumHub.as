UCLASS(Abstract)
class AVacuumHub : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.LDMaxDrawDistance = 12000.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bRenderWhileDisabled = true;
	default DisableComp.AutoDisableRange = 5000.f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	UAkAudioEvent LoopingIdleEvent;

	UPROPERTY()
	UAkAudioEvent ChangeDirectionEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (LoopingIdleEvent != nullptr)
			HazeAkComp.HazePostEvent(LoopingIdleEvent);
	}

	UFUNCTION()
	void ConnectedHoseDirectionChanged()
	{
		if (ChangeDirectionEvent != nullptr)
			HazeAkComp.HazePostEvent(ChangeDirectionEvent);
	}

	UFUNCTION()
	void AttachHoseToHub(TArray<USphereComponent> CollisionSpheres)
	{
		for (USphereComponent CurSphere : CollisionSpheres)
		{
			CurSphere.AttachToComponent(SkelMesh, n"Hips", EAttachmentRule::KeepWorld);
		}
	}
}
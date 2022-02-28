class AVacuumBossPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY()
	bool bAtTop = false;

	UPROPERTY()
	AActor TopRef;

	UPROPERTY()
	AActor BottomRef;

	FVector BottomPosition = FVector(-2730.f, 0.f, -630.f);

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		/*if (bAtTop)
		{
			SetToTop();
		}
		else
		{
			SetToBottom();
		}*/
	}

	UFUNCTION()
	void SetToTop()
	{
		TeleportActor(TopRef.ActorLocation, ActorRotation);
	}

	UFUNCTION()
	void SetToBottom()
	{
		TeleportActor(BottomRef.ActorLocation, ActorRotation);
	}
}
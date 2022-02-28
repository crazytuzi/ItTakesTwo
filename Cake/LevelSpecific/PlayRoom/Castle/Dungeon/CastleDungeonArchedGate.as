class ACastleDungeonArchedGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BlockingVolume;
	default BlockingVolume.SetCollisionProfileName(n"BlockAll");
	default BlockingVolume.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazePropComponent ArchProp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GateRoot;

	UPROPERTY(DefaultComponent, Attach = GateRoot)
	UStaticMeshComponent GateMesh;

	FHazeTimeLike CloseGateTimelike;
	default CloseGateTimelike.Duration = 1.f;

	FVector GateStartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CloseGateTimelike.BindUpdate(this, n"OnCloseGateUpdate");
	}

	UFUNCTION()
	void CloseGate(bool bSnap = false)
	{
		BlockingVolume.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
		GateStartLocation = GateRoot.RelativeLocation;

		if (bSnap)
			CloseGateTimelike.SetNewTime(CloseGateTimelike.Duration);

		CloseGateTimelike.Play();
	}

	UFUNCTION()
	void OnCloseGateUpdate(float Value)
	{
		FVector NewRelativeLocation = FMath::Lerp(GateStartLocation, FVector::ZeroVector, Value);
		GateRoot.SetRelativeLocation(NewRelativeLocation);
	}
}
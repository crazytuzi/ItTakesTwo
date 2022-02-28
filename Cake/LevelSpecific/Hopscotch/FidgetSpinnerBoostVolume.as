class AFidgetSpinnerBoostVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Box;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Plane01;
	default Plane01.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Plane02;
	default Plane02.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Plane03;
	default Plane03.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Plane04;
	default Plane04.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = Box)
	UStaticMeshComponent TempMesh;
	default TempMesh.bHiddenInGame = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnComponentBeginOverlap.AddUFunction(this, n"BoxBeginOverlap");
		Box.OnComponentEndOverlap.AddUFunction(this, n"BoxEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Plane01.SetRelativeScale3D(FVector(ActorScale3D.X, ActorScale3D.Z, 1.f));
		Plane02.SetRelativeScale3D(FVector(ActorScale3D.X, ActorScale3D.Z, 1.f));
		Plane03.SetRelativeScale3D(FVector(ActorScale3D.Y, ActorScale3D.Z, 1.f));
		Plane04.SetRelativeScale3D(FVector(ActorScale3D.Y, ActorScale3D.Z, 1.f));
	}
	
	UFUNCTION()
	void BoxBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		Player.SetCapabilityActionState(n"FidgetBoost", EHazeActionState::Active);
	}

	UFUNCTION()
	void BoxEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (!Player.HasControl())
			return;

		Player.SetCapabilityActionState(n"FidgetBoost", EHazeActionState::Inactive);
	}
}
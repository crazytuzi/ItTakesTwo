class ADummyMicrophoneMonster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent SnakeHeadMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeSkeletalMeshComponentBase HeadMesh;

	UPROPERTY()
	UMaterialInstance CableMat;

	TArray<UHazeCableComponent> CableArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (int i = 0; i < 6; i++)
		{
			UHazeCableComponent Cable = UHazeCableComponent::Create(this);
			Cable.AttachToComponent(SnakeHeadMesh);
			Cable.CableLength = FMath::RandRange(1500.f, 2500.f);
			Cable.bAttachEnd = false;
			Cable.CableWidth = 100.f;
			Cable.SetMaterial(0, CableMat);
			CableArray.Add(Cable);
		}		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetCableForce();
	}

	void SetCableForce()
	{
		for (UHazeCableComponent Cable : CableArray)
		{
			FVector NewCableForce = MeshRoot.GetForwardVector() * -1.f;
			NewCableForce *= 40000.f;
			Cable.CableForce = NewCableForce;
		}
	}
}
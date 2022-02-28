class ALightRoomEntranceDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh01;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh02;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh03;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh04;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh05;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh06;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh07;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh08;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh09;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh10;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BlockingCollision;

	TArray<UStaticMeshComponent> MeshArray;

	float RotationSpeed = 50.f;
	int LastRotation = 0;

	float Timer = 0.f;
	float TotalRotationToAdd = 360.f;
	
	bool bShouldTick = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshArray.Add(Mesh01);
		MeshArray.Add(Mesh02);
		MeshArray.Add(Mesh03);
		MeshArray.Add(Mesh04);
		MeshArray.Add(Mesh05);
		MeshArray.Add(Mesh06);
		MeshArray.Add(Mesh07);
		MeshArray.Add(Mesh08);
		MeshArray.Add(Mesh09);
		MeshArray.Add(Mesh10);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldTick)
			return;

		Timer += DeltaTime;
		if (Timer <= TotalRotationToAdd/RotationSpeed)
		{
			for (int i = 0; i < MeshArray.Num(); i++)
			{
				float Rot = FMath::EaseInOut(0.f, 360.f * (i + 1), Timer/(TotalRotationToAdd/RotationSpeed), 3.f);
				MeshArray[i].SetRelativeRotation(FRotator(0.f, Rot, 0.f));
			}
			
			float MeshRotYaw = FMath::Lerp(0.f, 180.f, Timer/(TotalRotationToAdd/RotationSpeed)); 
			MeshRoot.SetRelativeRotation(FRotator(0.f, MeshRotYaw, 0.f));

		} else 
		{
			for (int i = 0; i < MeshArray.Num(); i++)
			{
				MeshArray[i].SetRelativeRotation(FRotator::ZeroRotator);
			}
			MeshRoot.SetRelativeRotation(FRotator(0.f, 180.f, 0.f));
			bShouldTick = false;
			BlockingCollision.CollisionEnabled = ECollisionEnabled::NoCollision;
		}
	}

	UFUNCTION()
	void OpenDoor()
	{
		bShouldTick = true;
	}
}
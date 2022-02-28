class ATagFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);
	// default MeshComp.

	UPROPERTY(Category = "Niagara")
	UNiagaraSystem CubeExplosion;

	UPROPERTY(Category = "Materials")
	UMaterialInstance Material3;

	UPROPERTY(Category = "Materials")
	UMaterialInstance Material2;

	UPROPERTY(Category = "Materials")
	UMaterialInstance Material1;

	UPROPERTY(Category = "Materials")
	UMaterialInstance Material0;

	FRotator StartingRot;
	FRotator LeftRot;
	FRotator RightRot;
	
	float Timer;
	float TimerStartValue = 1.f;
	float ConstInterpSpeed;
	float ConstInterpSpeedDefault = 100.f;

	bool bCanFloorShake;
	bool bIsActive;
	bool bRotatingLeft;

	float DistanceCheck;
	float DistanceCheckDefault = 0.5f;

	int LifeCount;
	int LifeCountDefault = 2;

	bool bGameIsActive;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartingRot = MeshComp.RelativeRotation;
		LeftRot = StartingRot + FRotator(9.f, 0.f, 0.f);
		RightRot = StartingRot + FRotator(-9.f, 0.f, 0.f);

		MeshComp.SetMaterial(1, Material2);

		BoxComp.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");

		LifeCount = LifeCountDefault;
	}

	UFUNCTION()
	void FloorShake()
	{
		Timer = TimerStartValue;
		bCanFloorShake = true;
		DistanceCheck = DistanceCheckDefault;
		ConstInterpSpeed = ConstInterpSpeedDefault;
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void FloorDissappear()
	{
		MeshComp.SetHiddenInGame(true);
		MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

		BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

		Niagara::SpawnSystemAtLocation(CubeExplosion, ActorLocation);

		bCanFloorShake = false;
		bIsActive = false;
	}

	UFUNCTION()
	void FloorReappear()
	{
		MeshComp.SetHiddenInGame(false);
		MeshComp.SetRelativeRotation(StartingRot);
		MeshComp.SetMaterial(1, Material2);
		MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

		BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Overlap);

		bIsActive = true;
	}

	UFUNCTION()
	void ResetFloorLife()
	{
		LifeCount = LifeCountDefault;
	}

	UFUNCTION(NetFunction)
	void UpdateFloorLifeCount()
	{
		LifeCount--;

		switch(LifeCount)
		{
			case 1:  MeshComp.SetMaterial(1, Material1); break;
			case 0:  MeshComp.SetMaterial(1, Material0); FloorShake(); break;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanFloorShake)
		{
			Timer -= DeltaTime;

			if (bRotatingLeft && MeshComp.RelativeRotation != LeftRot)
			{
				float RotDistance = LeftRot.Pitch - MeshComp.RelativeRotation.Pitch;
				RotDistance = FMath::Abs(RotDistance);

				if (RotDistance <= DistanceCheck)
				{
					DistanceCheck *= 1.15f;
					ConstInterpSpeed *= 1.15f;
					bRotatingLeft = false;
				}

				MeshComp.SetRelativeRotation(FMath::RInterpConstantTo(MeshComp.RelativeRotation, LeftRot, DeltaTime, ConstInterpSpeed));
			}
			else if (!bRotatingLeft && MeshComp.RelativeRotation != RightRot)
			{
				float RotDistance = RightRot.Pitch - MeshComp.RelativeRotation.Pitch;
				RotDistance = FMath::Abs(RotDistance);

				if (RotDistance <= DistanceCheck)
				{
					DistanceCheck *= 1.15f;
					ConstInterpSpeed *= 1.15f;
					bRotatingLeft = true;
				}
				
				MeshComp.SetRelativeRotation(FMath::RInterpConstantTo(MeshComp.RelativeRotation, RightRot, DeltaTime, ConstInterpSpeed));
			}

			if (Timer <= 0.f)
				FloorDissappear();
		}
		else
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		if (!bGameIsActive)
			return;

		if (!HasControl())
			return;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		UpdateFloorLifeCount();
    }
}
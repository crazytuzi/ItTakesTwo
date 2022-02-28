import Cake.LevelSpecific.Clockwork.Fishing.FishingPileFlingableObj;

struct FFlingableTrajectory
{
	UPROPERTY()
	FVector Apos;
	
	UPROPERTY()
	FVector Bpos;
	
	UPROPERTY()
	FVector ControlPoint;
}

class AFishingCatchPile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;
	default SphereComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SphereComp.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent)
	UNiagaraComponent DustEffect;
	default DustEffect.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent FishingAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ObjectLandEvent;

	UPROPERTY()
	TArray<AFishingFlingableObj> FlingableObj;
	default FlingableObj.SetNum(8); 

	TArray<FVector> DirectionArray;
	default DirectionArray.SetNum(8);

	TArray<FFlingableTrajectory> FlingableStruct;
	default FlingableStruct.SetNum(8);

	TArray<float> AlphaArray;
	default AlphaArray.SetNum(8);

	float RadiusRange = 60.f;

	int FinishedNumber;

	int MaxNumber = 8;

	float AlphaSpeed = 0.85f;

	bool bCanFlingItems;
	bool bCanPlayNiagra;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DustEffect.SetActive(false);
		DustEffect.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanFlingItems)
			FlingItems(DeltaTime);
	}

	UFUNCTION()
	void FlingItems(float DeltaTime)
	{
		if (FinishedNumber >= 8)
		{
			bCanFlingItems = false;
			bCanPlayNiagra = false;
			DustEffect.SetActive(false);
			DustEffect.Deactivate();
			return;
		}

		for (int i = 0; i < AlphaArray.Num() - 1; i++)
		{
			if (AlphaArray[i] >= 1.f)
			{
				FinishedNumber++;
				continue;
			}

			AlphaArray[i] += AlphaSpeed * DeltaTime;
			FVector NextLoc = Math::GetPointOnQuadraticBezierCurve(FlingableStruct[i].Apos, FlingableStruct[i].ControlPoint, FlingableStruct[i].Bpos, AlphaArray[i]);

			if (FlingableObj[i] == nullptr)
				continue;

			FlingableObj[i].SetActorLocation(NextLoc);
			
			FRotator Rotation = FRotator::MakeFromX(DirectionArray[i]);
			float RotAmount = 3.f;
			FRotator NextRot = FlingableObj[i].ActorRotation + (Rotation * RotAmount * DeltaTime);
			
			FlingableObj[i].SetActorRotation(NextRot);
		}		
	}

	UFUNCTION(NetFunction)
	void NetRustlePileEffects()
	{
		if (!bCanPlayNiagra)
		{
			bCanPlayNiagra = true;
			DustEffect.SetActive(true);
			DustEffect.Activate();
		}
	}

	UFUNCTION(NetFunction)
	void NetBeginFlingSequence()
	{
		for (int i = 0; i < AlphaArray.Num() - 1; i++)
		{
			AlphaArray[i] = 0.f;
		}

		FinishedNumber = 0;

		SetDirections();
		SetTrajectory();

		bCanFlingItems = true;

		FishingAkComp.HazePostEvent(ObjectLandEvent);
	}

	void SetDirections()
	{
		for (int i = 0; i < DirectionArray.Num() - 1; i++)
		{
			float RX = FMath::RandRange(-1.f, 1.f); 
			float RY = FMath::RandRange(-1.f, 1.f); 
			float RZ = FMath::RandRange(-1.f, 1.f); 

			FVector Direction = FVector(RX, RY, RZ);
			Direction.Normalize();

			DirectionArray[i] = Direction;
		}
	}

	void SetTrajectory()
	{
		for (int i = 0; i < FlingableStruct.Num() - 1; i++)
		{
			float RX = FMath::RandRange(-RadiusRange, RadiusRange); 
			float RY = FMath::RandRange(-RadiusRange, RadiusRange); 
			FlingableStruct[i].Apos = ActorLocation + FVector(RX, RY, 0.f);

			float DirectionAmount = 190.f;
			FlingableStruct[i].Bpos = FlingableStruct[i].Apos + (DirectionArray[i] * DirectionAmount);

			float RHeight = FMath::RandRange(850.f, 1250.f);
			FlingableStruct[i].ControlPoint = (FlingableStruct[i].Apos + FlingableStruct[i].Bpos) * 0.5f;
			FlingableStruct[i].ControlPoint += FVector(0.f, 0.f, RHeight);
		}
	}
}
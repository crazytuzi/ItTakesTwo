import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;

class ACurlingTube : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TubeMeshComp1;
	default TubeMeshComp1.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TubeMeshComp2;
	default TubeMeshComp2.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TubeMeshComp3;
	default TubeMeshComp3.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	UHazeAkComponent ShuffleAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TubeMovementEvent;

	FVector OriginalLoc;
	FVector TargetLoc;

	float MinDistance = 15.f;
	float TubeSpeed = 1500.f;

	bool bIsProvidingNewStone;
	bool bIsReturning;

	UPROPERTY(Category = "Setup")
	UMaterial Material;

	bool bPlayAudio;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalLoc = ActorLocation;

		TargetLoc = OriginalLoc;
		TargetLoc += FVector(0.f, 0.f, -800.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bIsProvidingNewStone)
		{
			if (!bPlayAudio)
			{
				bPlayAudio = true;
				AudioTubeMoveEvent();
			}

			float Distance = (ActorLocation - TargetLoc).Size();
			
			if (Distance <= MinDistance)
			{
				bIsProvidingNewStone = false;
				bPlayAudio = false;
				System::SetTimer(this, n"ReturnTube", 0.8f, false);
				return;
			}

			SetActorLocation(FMath::VInterpConstantTo(ActorLocation, TargetLoc, DeltaTime, TubeSpeed));  
		}
		else if (bIsReturning)
		{
			if (!bPlayAudio)
			{
				bPlayAudio = true;
				AudioTubeMoveEvent();
			}

			float Distance = (ActorLocation - OriginalLoc).Size();
			
			if (Distance <= MinDistance)
			{
				bIsReturning = false;
				bPlayAudio = false;
				return;
			}

			SetActorLocation(FMath::VInterpConstantTo(ActorLocation, OriginalLoc, DeltaTime, TubeSpeed));  
		}
	}

	UFUNCTION()
	void ReturnTube()
	{
		bIsReturning = true;
	}
	
	void AudioTubeMoveEvent()
	{
		ShuffleAkComp.HazePostEvent(TubeMovementEvent);
	}
}
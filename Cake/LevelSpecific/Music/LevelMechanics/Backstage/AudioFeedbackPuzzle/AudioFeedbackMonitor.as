import Cake.LevelSpecific.Music.LevelMechanics.Backstage.AudioFeedbackPuzzle.AudioFeedbackMicrophone;
class AAudioFeedbackMonitor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MonitorMesh01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MonitorMesh02;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ConnectorMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent SphereComp;

	UPROPERTY()
	FHazeTimeLike ShakeSpeakersTimeline;
	default ShakeSpeakersTimeline.Duration = 0.5f;
	default ShakeSpeakersTimeline.bLoop = true;

	UPROPERTY()
	UNiagaraSystem ExplosionFX;

	TArray<AAudioFeedbackMicrophone> MicArray;
	
	bool bShouldBeDestroyed = false;

	float MonitorShakeAmount = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SphereComp.OnComponentBeginOverlap.AddUFunction(this, n"SphereBeginOverlap");
		SphereComp.OnComponentEndOverlap.AddUFunction(this, n"SphereEndOverlap");

		ShakeSpeakersTimeline.BindUpdate(this, n"ShakeSpeakersTimelineUpdate");
		ShakeSpeakersTimeline.PlayFromStart();

		TArray<AActor> ActorArray;
		SphereComp.GetOverlappingActors(ActorArray);

		AAudioFeedbackMicrophone Mic;

		for (AActor Actor : ActorArray)
		{
			Mic = Cast<AAudioFeedbackMicrophone>(Actor);
			
			if (Mic != nullptr)
			{
				MicArray.AddUnique(Mic);
				CheckMicArraySize();
			}
		}
	}

	UFUNCTION()
	void ShakeSpeakersTimelineUpdate(float CurrentValue)
	{
		MonitorMesh01.SetRelativeRotation(FMath::LerpShortestPath(FRotator(0.f, -15.f, 0.f), FRotator(0.f, -15.f, MonitorShakeAmount), CurrentValue));
		MonitorMesh02.SetRelativeRotation(FMath::LerpShortestPath(FRotator(0.f, 15.f, 0.f), FRotator(0.f, 15.f, MonitorShakeAmount), CurrentValue));
	}

	UFUNCTION()
	void SphereBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AAudioFeedbackMicrophone Mic = Cast<AAudioFeedbackMicrophone>(OtherActor);
		
		if (Mic != nullptr)
		{
			MicArray.AddUnique(Mic);
			CheckMicArraySize();
		}
	}

	UFUNCTION()
	void SphereEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AAudioFeedbackMicrophone Mic = Cast<AAudioFeedbackMicrophone>(OtherActor);
		
		if (Mic != nullptr)
			MicArray.Remove(Mic);
	}

	UFUNCTION()
	void CheckMicArraySize()
	{
		switch (MicArray.Num())
		{
			case 0:
				MonitorShakeAmount = 0.f;
				break;

			case 1:
				MonitorShakeAmount = 1.f;
				break;

			case 2:
				MonitorShakeAmount = 2.f;
				break;

			case 3:
				MonitorShakeAmount = 3.f;
				break;	

			case 4:
				MonitorShakeAmount = 4.f;
				break;	
		}
		
		if (MicArray.Num() >= 4 && !bShouldBeDestroyed)
		{
			bShouldBeDestroyed = true;
			System::SetTimer(this, n"DestroyMonitor", 2.f, false);
		}
	}

	UFUNCTION()
	void DestroyMonitor()
	{
		Niagara::SpawnSystemAtLocation(ExplosionFX, GetActorLocation());
		DestroyActor();
	}
}
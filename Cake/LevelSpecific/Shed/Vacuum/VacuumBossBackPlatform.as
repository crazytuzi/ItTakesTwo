import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
event void FOnVacuumBossBackPlatformActivated();

class AVacuumBossBackPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformUpEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformDownEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MovePlatformTimeLike;
	default MovePlatformTimeLike.Duration = 1.f;

	bool bGoingUp = false;

	UPROPERTY()
	AVacuumHoseActor PlatformHoseActor;

	UPROPERTY()
	FOnVacuumBossBackPlatformActivated OnVacuumBossBackPlatformActivated;

	FVector StartLocation;
	FVector EndLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		EndLocation = StartLocation + FVector(0.f, 0.f, 1150.f);

		MovePlatformTimeLike.BindUpdate(this, n"UpdateMovePlatform");
		MovePlatformTimeLike.BindFinished(this, n"FinishMovePlatform");
	}

	UFUNCTION()
	void ActivatePlatform()
	{
		if (bGoingUp)
			return;

		bGoingUp = true;
		BP_ActivatePlatform();
		UHazeAkComponent::HazePostEventFireForget(PlatformUpEvent, GetActorTransform());
		PlatformHoseActor.bUseAudioComponents = true;		
		
		PlatformHoseActor.FrontHazeAkComp.HazePostEvent(PlatformHoseActor.StartBlowOrSuckVacuumFrontEvent);
		PlatformHoseActor.BackHazeAkComp.HazePostEvent(PlatformHoseActor.StartBlowOrSuckVacuumBackEvent);		
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivatePlatform() {}

	UFUNCTION()
	void DeactivatePlatform()
	{
		if (!bGoingUp)
			return;

		bGoingUp = false;
		BP_DeactivatePlatform();
		UHazeAkComponent::HazePostEventFireForget(PlatformDownEvent, GetActorTransform());

		System::SetTimer(this, n"StopVacuumHoseDelayed", 3.f, false);
	}

	UFUNCTION()
	void StopVacuumHoseDelayed()
	{	
		PlatformHoseActor.FrontHazeAkComp.HazePostEvent(PlatformHoseActor.StopBlowOrSuckVacuumFrontEvent);
		PlatformHoseActor.BackHazeAkComp.HazePostEvent(PlatformHoseActor.StopBlowOrSuckVacuumBackEvent);
	}

	UFUNCTION(BlueprintEvent)
	void BP_DeactivatePlatform() {}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMovePlatform(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMovePlatform()
	{
		if (bGoingUp)
			OnVacuumBossBackPlatformActivated.Broadcast();
	}
}
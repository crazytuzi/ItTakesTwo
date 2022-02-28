import Cake.LevelSpecific.SnowGlobe.Mountain.MovingIce;

event void FFallingTrussEvent();

class AFallingTruss : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	// Add a UStaticMeshComp later! Attach an actor for now

	UPROPERTY()
	AHazeActor ConnectedTruss;

	UPROPERTY()
	TArray<AActor> ConnectedCollisionActors;

	UPROPERTY()
	AHazeCameraActor ConnectedCamera;

	UPROPERTY()
	FHazeTimeLike TrussFallTimeline;

	UPROPERTY()
	TArray<AMovingIce> MovingIceArray;

	UPROPERTY()
	TArray<ATriggerableFX> ConnectedFX;

	UPROPERTY()
	FFallingTrussEvent TrussFallMiddleEvent;

	UPROPERTY()
	FFallingTrussEvent TrussFallEndEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TrussFallingEvent;

	FRotator StartRot = FRotator::ZeroRotator;
	FRotator TargetRot = FRotator(-30.f, 0.f, 0.f);

	bool bHasTriggeredOtherTrusses = false;

	UPROPERTY()
	bool bShowTargetState = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetState)
			MeshRoot.SetRelativeRotation(TargetRot);
		else
			MeshRoot.SetRelativeRotation(StartRot);

		ConnectTrussMesh();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshRoot.SetRelativeRotation(StartRot);
		
		TrussFallTimeline.BindUpdate(this, n"TrussFallTimelineUpdate");
		TrussFallTimeline.BindFinished(this, n"TrussFallTimelineFinished");
		
		ConnectTrussMesh();	

		for (auto Actor : ConnectedCollisionActors)
			Actor.AttachToComponent(MeshRoot, n"", EAttachmentRule::KeepWorld);

		//TrussFallTimeline.PlayFromStart();
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION()
	void StartTrussFall()
	{
		TrussFallTimeline.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(TrussFallingEvent, FTransform());
	}

	UFUNCTION()
	void TrussFallTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartRot, TargetRot, CurrentValue));
		ConnectedCamera.SetActorRotation(FMath::LerpShortestPath(StartRot, TargetRot, CurrentValue));
		
		if (CurrentValue > 0.175 && !bHasTriggeredOtherTrusses)
		{
			bHasTriggeredOtherTrusses = true;
			TrussFallMiddleEvent.Broadcast();
			for (auto Ice : MovingIceArray)
				Ice.StartMoving();

			for (auto FX : ConnectedFX)
				FX.TriggerFX();
		}
	}

	UFUNCTION()
	void TrussFallTimelineFinished(float CurrentValue)
	{
		TrussFallEndEvent.Broadcast();
	}

	void ConnectTrussMesh()
	{
		if (ConnectedTruss != nullptr)
		{
			TArray<AActor> Actors;
			GetAttachedActors(Actors);
			for (auto Actor : Actors)
			{
				if (Actor == ConnectedTruss)
					return;	
			}
			ConnectedTruss.AttachToComponent(MeshRoot, n"", EAttachmentRule::SnapToTarget);	
		}
	}
}
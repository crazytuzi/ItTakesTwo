import Peanuts.Audio.AudioStatics;

class AHopscotchDungeonTimedPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformStartMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformStopMoveAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformFullyInAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformFullyOutAudioEvent;

	//Rtpc_Playroom_Hopscotch_Platform_Dungeon_TimedPlatform_Velocity (-1, 1)

	UPROPERTY()
	bool bIsYellow = false;

	UPROPERTY()
	bool bShowTargetState;

	float CurrentPlatformAlpha = 0.f;

	bool bHasStartedAudio = false;

	FVector StartLocation = FVector::ZeroVector;

	FVector CurrentVelocity = FVector::ZeroVector;
	FVector LocLastTick = FVector::ZeroVector;
	FVector TargetDirection = FVector::ZeroVector;

	bool bPuzzleIsSolved = false;

	UPROPERTY(Meta = (MakeEditWidget))
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MeshRoot.SetRelativeLocation(StartLocation);
		TargetDirection = ActorTransform.TransformPosition(TargetLocation) - ActorLocation;
		TargetDirection.Normalize();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CurrentPlatformAlpha != 0.f && !bHasStartedAudio)
		{
			bHasStartedAudio = true;
			HazeAkComp.HazePostEvent(PlatformStartMoveAudioEvent);
		} else if (CurrentPlatformAlpha == 0.f && bHasStartedAudio)
		{
			bHasStartedAudio = false;
			HazeAkComp.HazePostEvent(PlatformStopMoveAudioEvent);
		}

		// AUDIO RTPC 
		CurrentVelocity = (MeshRoot.WorldLocation - LocLastTick) / DeltaTime;
		LocLastTick = MeshRoot.WorldLocation;
		float Speed = CurrentVelocity.DotProduct(TargetDirection);
		Speed = FMath::GetMappedRangeValueClamped(FVector2D(-400.f, 400.f), FVector2D(-1.f, 1.f), Speed);
		HazeAkComp.SetRTPCValue("Rtpc_Playroom_Hopscotch_Platform_Dungeon_TimedPlatform_Velocity", Speed);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetState)
			MeshRoot.SetRelativeLocation(TargetLocation);
		else
			MeshRoot.SetRelativeLocation(StartLocation);
	}

	UFUNCTION()
	void PuzzleWasSolved()
	{
		bPuzzleIsSolved = true;
	}

	UFUNCTION()
	void UpdatePosition(float Alpha)
	{
		if (bPuzzleIsSolved)
			return;

		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLocation, TargetLocation, Alpha));
		CurrentPlatformAlpha = Alpha;
		
		if (Alpha == 1.f)
			HazeAkComp.HazePostEvent(PlatformFullyOutAudioEvent);
		else if (Alpha == 0.f)
			HazeAkComp.HazePostEvent(PlatformFullyInAudioEvent);
	}
}
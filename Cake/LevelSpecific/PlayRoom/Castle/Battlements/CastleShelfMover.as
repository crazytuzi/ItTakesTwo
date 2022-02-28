import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleElevator;

class ACastleShelfMover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetbVisualizeComponent(true);

	UPROPERTY(meta = (MakeEditWidget))
	FVector Movement = FVector(1500, 0, 0);

	UPROPERTY()
	FVector StartLocation;
	UPROPERTY()
	FVector EndLocation;

	UPROPERTY()
	ACastleElevator ElevatorRef;

	UPROPERTY()
	float Progress;

	UPROPERTY()
	bool bExtended;

	UFUNCTION(CallInEditor)
	void ToggleShelfExtension()
	{
		if (bExtended)
		{
			AddActorWorldOffset(-GetActorTransform().TransformVector(Movement));
			
			bExtended = false;
		}
		else
		{
			AddActorWorldOffset(GetActorTransform().TransformVector(Movement));
			bExtended = true;
		}
	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		EndLocation = ActorTransform.TransformPosition(Movement);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateShelfLocation();
	}

	void UpdateShelfLocation()
	{		
		if (ElevatorRef == nullptr)
			return;

		float NewProgress = FMath::GetMappedRangeValueClamped(FVector2D(0, 0.4f), FVector2D(0, 1), ElevatorRef.ElevatorProgress);

		FVector NewLocation = FMath::Lerp(StartLocation, EndLocation, NewProgress);
		SetActorLocation(NewLocation);
	}

	UFUNCTION()
	void SetShelfProgress(float Loc_Progress)
	{
		float ClampedProgress = FMath::Clamp(Loc_Progress, 0.f, 1.f);
		Progress = ClampedProgress;
	}
}
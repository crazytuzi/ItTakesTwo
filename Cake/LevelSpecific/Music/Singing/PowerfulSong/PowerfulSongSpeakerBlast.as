
class APowerfulSongSpeakerBlast : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(Category = Movement)
	float MovementSpeed = 8000.0f;

	UPROPERTY(Category = Movement)
	float DistanceMax = 2000.0f;

	FVector StartLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AddActorWorldOffset(ActorForwardVector * MovementSpeed * DeltaTime);

		if(StartLocation.DistSquared(ActorLocation) > FMath::Square(DistanceMax))
		{
			SetLifeSpan(2.0f);
			SetActorTickEnabled(false);
			BP_OnDistanceMaximumReached();
		}
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Distance Maximum Reached"))
	void BP_OnDistanceMaximumReached() {}
}

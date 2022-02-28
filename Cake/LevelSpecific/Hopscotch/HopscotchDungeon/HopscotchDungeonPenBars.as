import Cake.LevelSpecific.Hopscotch.HopscotchDungeon.HopscotchDungeonSwiveldoor;
class AHopscotchDungeonPenBars : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh2;

	UPROPERTY()
	AHopscotchDungeonSwivelDoor ConnectedDoor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PenBarsOpenAudioEvent;

	UPROPERTY()
	FHazeTimeLike MoveBarsTimeline;

	FVector StartLocation = FVector::ZeroVector;
	FVector TargetLocation = FVector(0.f, 0.f, 500.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveBarsTimeline.BindUpdate(this, n"MoveBarsTimelineUpdate");
	}

	UFUNCTION()
	void MoveBarsTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLocation, TargetLocation, CurrentValue));
	}

	UFUNCTION()
	void OpenPens()
	{
		MoveBarsTimeline.PlayFromStart();
		ConnectedDoor.EnableDoor();
		UHazeAkComponent::HazePostEventFireForget(PenBarsOpenAudioEvent, this.GetActorTransform());
	}
}
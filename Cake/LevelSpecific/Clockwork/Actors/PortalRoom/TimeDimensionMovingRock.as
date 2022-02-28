import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;
class ATimeDimensionMovingRock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RockMesh;

	UPROPERTY(DefaultComponent, Attach = RockMesh)
	UTimeControlActorComponent TimeComp;

	UPROPERTY(DefaultComponent, Attach = RockMesh)
	UBoxComponent BoxCollision;

	FVector StartingLocation;

	UPROPERTY(meta = (MakeEditWidget))
	FVector TargetLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeComp.TimeIsChangingEvent.AddUFunction(this, n"TimeIsChanging");
	}

	UFUNCTION()
	void TimeIsChanging(float PointInTime)
	{
		RockMesh.SetRelativeLocation(FMath::Lerp(StartingLocation, TargetLocation, PointInTime));
	}
}
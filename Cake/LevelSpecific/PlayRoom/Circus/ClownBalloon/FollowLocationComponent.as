import Cake.LevelSpecific.PlayRoom.Circus.Cannon.CannonTargetOscillation;
class UFollowLocationComponent : USceneComponent
{
	UPROPERTY()
	AActor TrackActor;

	FVector Offset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Offset = Owner.ActorLocation - TrackActor.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UCannonTargetOscillation Oscillation = UCannonTargetOscillation::Get(TrackActor);
		Owner.SetActorLocation(Oscillation.WorldLocation + Offset);
	}
}
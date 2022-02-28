import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlComponent;

/* While cody is in this volume he will be forced to target the specified actor for time control. */
class AForcedTimeControlVolume : AVolume
{
	default BrushComponent.SetCollisionProfileName(n"TriggerPlayerOnly");

	UPROPERTY(Category = "Time Control")
	AHazeActor ForcedTargetActor;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if (ForcedTargetActor == nullptr)
			return;
		UTimeControlComponent TimeControl = UTimeControlComponent::Get(OtherActor);
		if (TimeControl != nullptr)
			TimeControl.ForcedTargetComponent = UTimeControlActorComponent::Get(ForcedTargetActor);
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		UTimeControlComponent TimeControl = UTimeControlComponent::Get(OtherActor);
		if (TimeControl != nullptr)
			TimeControl.ForcedTargetComponent = nullptr;
	}
};
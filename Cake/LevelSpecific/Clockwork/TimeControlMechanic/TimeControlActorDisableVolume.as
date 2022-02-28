import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

/*
	When a player is inside this volume, the targeted time control actors
	cannot be time controlled. Prevents weirdness with time controlling
	objects into players.
*/
class ATimeControlActorDisableVolume : AVolume
{
	UPROPERTY(Category = "Time Control")
	TArray<AActor> BlockedTimeControlActors;

	private TArray<AActor> BlockingActors;
	private bool bIsBlocking = false;

	UFUNCTION(BlueprintOverride)
	void ActorBeginOverlap(AActor OtherActor)
	{
		if (Cast<AHazePlayerCharacter>(OtherActor) == nullptr)
			return;

		BlockingActors.Add(OtherActor);
		if (!bIsBlocking)
		{
			for(auto Actor : BlockedTimeControlActors)
			{
				if (Actor != nullptr)
					UTimeControlActorComponent::Get(Actor).DisableTimeControl(this);
			}
			bIsBlocking = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ActorEndOverlap(AActor OtherActor)
	{
		if (Cast<AHazePlayerCharacter>(OtherActor) == nullptr)
			return;

		BlockingActors.Remove(OtherActor);
		if (bIsBlocking && BlockingActors.Num() == 0)
		{
			for(auto Actor : BlockedTimeControlActors)
			{
				if (Actor != nullptr)
					UTimeControlActorComponent::Get(Actor).EnableTimeControl(this);
			}
			bIsBlocking = false;
		}
	}
};
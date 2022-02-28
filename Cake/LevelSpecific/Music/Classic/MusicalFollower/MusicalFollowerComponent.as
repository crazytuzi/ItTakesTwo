import Cake.LevelSpecific.Music.Classic.MusicalFollower.MusicalFollower;

void AddFollowerToList(AHazeActor TargetActor, AMusicalFollower NewFollower)
{
	UMusicalFollowerComponent FollowersComp = UMusicalFollowerComponent::Get(TargetActor);
	if(FollowersComp != nullptr)
	{
		FollowersComp.Followers.Add(NewFollower);
	}
}

AMusicalFollower GetLastFollower(AHazeActor TargetActor)
{
	UMusicalFollowerComponent FollowersComp = UMusicalFollowerComponent::Get(TargetActor);
	if(FollowersComp != nullptr && FollowersComp.Followers.Num() > 0)
	{
		return FollowersComp.Followers.Last();
	}

	return nullptr;
}

void RemoveFromList(AHazeActor TargetActor, AMusicalFollower FollowerToRemove)
{
	UMusicalFollowerComponent FollowersComp = UMusicalFollowerComponent::Get(TargetActor);
	if(FollowersComp != nullptr)
	{
		FollowersComp.Followers.Remove(FollowerToRemove);
	}
}

class UMusicalFollowerComponent : UActorComponent
{
	TArray<AMusicalFollower> Followers;

	UPROPERTY(Category = Location)
	FVector FlyingTargetOffset = FVector(0.0f, 0.0f, -500.0f);

	// Also applied when flying or hovering too close to the ground.
	UPROPERTY(Category = Location)
	FVector GroundedTargetOffset = FVector::ZeroVector;

	UPROPERTY(Category = Location)
	float LeaderDistanceToPlayer = 100.0f;
}

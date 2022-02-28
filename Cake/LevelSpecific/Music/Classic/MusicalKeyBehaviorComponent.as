import Cake.SteeringBehaviors.SteeringBehaviorComponent;

event void FMusicalKeyLostFollowTarget(AHazeActor Key, AHazeActor LastFollowTarget);
event void FMusicalKeyNewFollowTarget(AHazeActor Key, AHazeActor NewFollowTarget);

class UMusicalKeyBehaviorComponent : UActorComponent
{
	AHazeActor HazeOwner;
	
	UPROPERTY()
	FMusicalKeyLostFollowTarget OnLostFollowTarget;

	UPROPERTY()
	FMusicalKeyNewFollowTarget OnNewFollowTarget;
}

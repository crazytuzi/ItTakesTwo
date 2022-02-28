import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;


void InitalizeDelayDeath(ASickleEnemy Enemy)
{
	auto DelayDeath = USickleEnemyDelayDeathComponent::GetOrCreate(Enemy);
}	

// We need to delay the death so all the network messages have time to come in
// when there is other networked component attached to the owner
class USickleEnemyDelayDeathComponent : UActorComponent
{
	const float MaxDuration = 10;
	float CreationTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Cast<AHazeActor>(Owner).DisableActor(this);
		CreationTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		Cast<AHazeActor>(Owner).EnableActor(this);
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		// This component cant be disabled
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(Time::GetGameTimeSince(CreationTime) > MaxDuration)
		{
			Owner.DestroyActor();
		}
	}

}
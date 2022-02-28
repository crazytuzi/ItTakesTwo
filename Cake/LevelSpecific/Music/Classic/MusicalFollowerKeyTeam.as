import Cake.LevelSpecific.Music.Classic.MusicalKeyBehaviorComponent;

class UMusicalFollowerKeyTeam : UHazeAITeam
{
	// Total amount of keys in the level.
	private int NumKeys = 0;
	private TMap<AHazeActor, AHazeActor> KeyAndFollowTarget;

	int GetKeysTotal() const
	{
		return NumKeys;
	}

	UFUNCTION()
	void Handle_FollowTargetLost(AHazeActor MusicalKey, AHazeActor LastFollowTarget)
	{
		KeyAndFollowTarget.Remove(MusicalKey);
	}

	UFUNCTION()
	void Handle_NewTargetFollow(AHazeActor MusicalKey, AHazeActor LastFollowTarget)
	{
		KeyAndFollowTarget.Add(MusicalKey, LastFollowTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberJoined(AHazeActor Member)
	{
		UMusicalKeyBehaviorComponent KeyBehavior = UMusicalKeyBehaviorComponent::Get(Member);
		KeyBehavior.OnNewFollowTarget.AddUFunction(this, n"Handle_FollowTargetLost");
		KeyBehavior.OnLostFollowTarget.AddUFunction(this, n"Handle_NewTargetFollow");
		NumKeys++;
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		UMusicalKeyBehaviorComponent KeyBehavior = UMusicalKeyBehaviorComponent::Get(Member);
		KeyBehavior.OnNewFollowTarget.Unbind(this, n"Handle_FollowTargetLost");
		KeyBehavior.OnLostFollowTarget.Unbind(this, n"Handle_NewTargetFollow");
		NumKeys--;
	}

	// Check if any follow target for the key is a player and return a random player.
	AHazePlayerCharacter GetRandomPlayerFollowTarget() const
	{
		TArray<AHazePlayerCharacter> PlayerList;

		for(auto Entry : KeyAndFollowTarget)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Entry.Value);
			if(Player != nullptr)
			{
				PlayerList.Add(Player);
			}
		}

		if(PlayerList.Num() == 0)
		{
			return nullptr;
		}

		return PlayerList.Num() > 1 ? PlayerList[FMath::RandRange(0, 1)] : PlayerList[0];
	}
}

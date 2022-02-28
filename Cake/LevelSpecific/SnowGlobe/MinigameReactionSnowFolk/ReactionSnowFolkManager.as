import Cake.LevelSpecific.SnowGlobe.MinigameReactionSnowFolk.ReactionSnowFolk;

UFUNCTION(Category = "ReactionSnowFolkManager")
void ActivateReactionSnowFolkWithActivationLevel(ESnowFolkActivationLevel Level, 
	bool bTriggerReaction = false, FVector LookAt = FVector::ZeroVector, float RotationTime = 1.f)
{
	if (Level == ESnowFolkActivationLevel::None)
		return;

	TArray<AReactionSnowFolkManager> Managers;
	GetAllActorsOfClass(Managers);

	for (auto Manager : Managers)
	{
		if (Manager.ActivationLevel != Level)
			continue;
		
		if (!bTriggerReaction)
			Manager.ActivateSnowFolk();
		else 
			Manager.ActivateSnowFolkWithReactionAndRotation(LookAt, RotationTime);
	}
}

class AReactionSnowFolkManager : AHazeActor
{
	UPROPERTY(Category = "Setup")
	TArray<AReactionSnowFolk> ReactionLeaders;
	
	// Disables all connected leaders & followers for later activation.
	UPROPERTY(Category = "Setup")
	bool bStartDisabled;

	// Which activation level the manager responds to.
	UPROPERTY(Category = "Setup")
	ESnowFolkActivationLevel ActivationLevel;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp3;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ReactionEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (ReactionLeaders.Num() == 0 || !bStartDisabled)
			return;

		for (AReactionSnowFolk Folk : ReactionLeaders)
		{
			Folk.DisableActor(this);

			TArray<AActor> SnowFolkFollowers;
			Folk.GetAttachedActors(SnowFolkFollowers);

			for (AActor Follower : SnowFolkFollowers)
			{
				AReactionSnowFolk SnowFolkFollower = Cast<AReactionSnowFolk>(Follower);
				SnowFolkFollower.DisableActor(this);
			}
		}
	}

	UFUNCTION(NetFunction)
	void ActivateReactions()
	{
		if (ReactionLeaders.Num() == 0)
			return;

		for (AReactionSnowFolk Folk : ReactionLeaders)
		{
			if (Folk.IsActorDisabled())
				continue;

			Folk.ActivateReaction();
		}

		AkComp1.HazePostEvent(ReactionEvent);
		AkComp2.HazePostEvent(ReactionEvent);
		AkComp3.HazePostEvent(ReactionEvent);
	}

	UFUNCTION(NetFunction)
	void ActivateRotations(FVector LookAtRotation, float Time)
	{
		if (ReactionLeaders.Num() == 0)
			return;

		for (AReactionSnowFolk Folk : ReactionLeaders)
		{
			if (Folk.IsActorDisabled())
				continue;

			Folk.ActivateRotationToVector(LookAtRotation, Time);

			TArray<AActor> SnowFolkFollowers;
			Folk.GetAttachedActors(SnowFolkFollowers);

			for (AActor Follower : SnowFolkFollowers)
			{
				AReactionSnowFolk SnowFolkFollower = Cast<AReactionSnowFolk>(Follower);
				SnowFolkFollower.ActivateRotationToVector(LookAtRotation, Time);
			}
		}
	}

	UFUNCTION(NetFunction)
	void ActivateSnowFolk()
	{
		if (ReactionLeaders.Num() == 0)
			return;

		for (AReactionSnowFolk Folk : ReactionLeaders)
		{
			if (Folk.IsActorDisabled(this))
				Folk.EnableActor(this);

			TArray<AActor> SnowFolkFollowers;
			Folk.GetAttachedActors(SnowFolkFollowers);

			for (AActor Follower : SnowFolkFollowers)
			{
				AReactionSnowFolk SnowFolkFollower = Cast<AReactionSnowFolk>(Follower);
				
				if (SnowFolkFollower.IsActorDisabled(this))
					SnowFolkFollower.EnableActor(this);
			}
		}
	}

	UFUNCTION(NetFunction)
	void ActivateSnowFolkWithReactionAndRotation(FVector LookAtRotation, float RotationTime)
	{
		if (ReactionLeaders.Num() == 0)
			return;

		for (AReactionSnowFolk Folk : ReactionLeaders)
		{
			if (Folk.IsActorDisabled(this))
				Folk.EnableActor(this);

			TArray<AActor> SnowFolkFollowers;
			Folk.GetAttachedActors(SnowFolkFollowers);

			for (AActor Follower : SnowFolkFollowers)
			{
				AReactionSnowFolk SnowFolkFollower = Cast<AReactionSnowFolk>(Follower);

				if (SnowFolkFollower.IsActorDisabled(this))
					SnowFolkFollower.EnableActor(this);

				SnowFolkFollower.ActivateRotationToVector(LookAtRotation, RotationTime);
			}

			Folk.ActivateReaction();
			Folk.ActivateRotationToVector(LookAtRotation, RotationTime);
		}

		AkComp1.HazePostEvent(ReactionEvent);
		AkComp2.HazePostEvent(ReactionEvent);
		AkComp3.HazePostEvent(ReactionEvent);
	}
}
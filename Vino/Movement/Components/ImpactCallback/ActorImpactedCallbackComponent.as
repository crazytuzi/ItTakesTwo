delegate void FActorImpactedByPlayerDelegate(AHazePlayerCharacter ImpactingPlayer, const FHitResult& Hit);
event void FActorImpactedByPlayerEvent(AHazePlayerCharacter ImpactingPlayer, const FHitResult& Hit);

delegate void FActorImpactedDelegate(AHazeActor ImpactingActor, const FHitResult& Hit);
event void FActorImpactedEvent(AHazeActor ImpactingActor, const FHitResult& Hit);

delegate void FActorNoLongerImpactingByPlayerDelegate(AHazePlayerCharacter ImpactedPlayer);
event void FActorNoLongerImpactingByPlayerEvent(AHazePlayerCharacter ImpactedPlayer);

delegate void FActorNoLongerImpactingDelegate(AHazeActor ImpactedActor);
event void FActorNoLongerImpactingEvent(AHazeActor ImpactedActor);

enum EImpactDirection
{
	UpImpact,
	ForwardImpact,
	DownImpact,
}

UCLASS(HideCategories = " ComponentReplication Activation Cooking Collision")
class UActorImpactedCallbackComponent : UActorComponent
{
	/*
		Default behaviour is that the callback is synced from the Control side of the impacter. You can disable this if you want to, but this should be for gameplay affecting behaviour.
	*/
	UPROPERTY(Category = "Impacted")
	bool bCanBeActivedLocallyOnTheRemote = false;

	UPROPERTY(Category = "Impacted")
	FActorNoLongerImpactingByPlayerEvent OnUpImpactEndingPlayer;

	UPROPERTY(Category = "Impacted")
	FActorNoLongerImpactingByPlayerEvent OnForwardImpactEndingPlayer;

	UPROPERTY(Category = "Impacted")
	FActorNoLongerImpactingByPlayerEvent OnDownImpactEndingPlayer;

	UPROPERTY(Category = "Impacted")
	FActorNoLongerImpactingEvent OnUpImpactEnding;

	UPROPERTY(Category = "Impacted")
	FActorNoLongerImpactingEvent OnForwardImpactEnding;

	UPROPERTY(Category = "Impacted")
	FActorNoLongerImpactingEvent OnDownImpactEnding;

	UPROPERTY(Category = "Impacted")
	FActorImpactedByPlayerEvent OnActorUpImpactedByPlayer;

	UPROPERTY(Category = "Impacted")
	FActorImpactedByPlayerEvent OnActorForwardImpactedByPlayer;

	UPROPERTY(Category = "Impacted")
	FActorImpactedByPlayerEvent OnActorDownImpactedByPlayer;

	UPROPERTY(Category = "Impacted")
	FActorImpactedEvent OnActorUpImpacted;

	UPROPERTY(Category = "Impacted")
	FActorImpactedEvent OnActorForwardImpacted;

	UPROPERTY(Category = "Impacted")
	FActorImpactedEvent OnActorDownImpacted;

	UFUNCTION(NetFunction)
	void NetImpactedByPlayer(AHazePlayerCharacter HazePlayer, const FHitResult& Hit, EImpactDirection Direction)
	{
		LocalImpactedByPlayer(HazePlayer, Hit, Direction);
	}

	UFUNCTION(NetFunction)
	void NetImpactedByActor(AHazeActor HazeActor, const FHitResult& Hit, EImpactDirection Direction)
	{
		LocalImpactedByActor(HazeActor, Hit, Direction);
	}

	UFUNCTION(NetFunction)
	void NetImpactEndedByPlayer(AHazePlayerCharacter HazePlayer, EImpactDirection Direction)
	{
		LocalImpactedEndedByPlayer(HazePlayer, Direction);
	}

	UFUNCTION(NetFunction)
	void NetImpactEndedByActor(AHazeActor HazeActor, EImpactDirection Direction)
	{
		LocalImpactedEndedByActor(HazeActor, Direction);
	}

	void LocalImpactedByPlayer(AHazePlayerCharacter HazePlayer, const FHitResult& Hit, EImpactDirection Direction)
	{
		if (Direction == EImpactDirection::UpImpact)
		{
			OnActorUpImpactedByPlayer.Broadcast(HazePlayer, Hit);
		}
		else if (Direction == EImpactDirection::ForwardImpact)
		{
			OnActorForwardImpactedByPlayer.Broadcast(HazePlayer, Hit);
		}
		else if (Direction == EImpactDirection::DownImpact)
		{
			OnActorDownImpactedByPlayer.Broadcast(HazePlayer, Hit);
		}
	}

	void LocalImpactedByActor(AHazeActor HazeActor, const FHitResult& Hit, EImpactDirection Direction)
	{
		if (Direction == EImpactDirection::UpImpact)
		{
			OnActorUpImpacted.Broadcast(HazeActor, Hit);
		}
		else if (Direction == EImpactDirection::ForwardImpact)
		{
			OnActorForwardImpacted.Broadcast(HazeActor, Hit);
		}
		else if (Direction == EImpactDirection::DownImpact)
		{
			OnActorDownImpacted.Broadcast(HazeActor, Hit);
		}
	}

	void LocalImpactedEndedByPlayer(AHazePlayerCharacter HazePlayer, EImpactDirection Direction)
	{
		if (Direction == EImpactDirection::UpImpact)
		{
			OnUpImpactEndingPlayer.Broadcast(HazePlayer);
		}
		else if (Direction == EImpactDirection::ForwardImpact)
		{
			OnForwardImpactEndingPlayer.Broadcast(HazePlayer);
		}
		else if (Direction == EImpactDirection::DownImpact)
		{
			OnDownImpactEndingPlayer.Broadcast(HazePlayer);
		}
	}

	void LocalImpactedEndedByActor(AHazeActor HazeActor, EImpactDirection Direction)
	{
		if (Direction == EImpactDirection::UpImpact)
		{
			OnUpImpactEnding.Broadcast(HazeActor);
		}
		else if (Direction == EImpactDirection::ForwardImpact)
		{
			OnForwardImpactEnding.Broadcast(HazeActor);
		}
		else if (Direction == EImpactDirection::DownImpact)
		{
			OnDownImpactEnding.Broadcast(HazeActor);
		}
	}

	void ActorImpactedByPlayer(AHazePlayerCharacter HazePlayer, const FHitResult& Hit, EImpactDirection Direction)
	{
		if (bCanBeActivedLocallyOnTheRemote)
		{
			LocalImpactedByPlayer(HazePlayer, Hit, Direction);
		}
		else
		{
			if (HazePlayer.HasControl())
				NetImpactedByPlayer(HazePlayer, Hit, Direction);
		}
	}

	void ActorImpacted(AHazeActor HazeActor, const FHitResult& Hit, EImpactDirection Direction)
	{
		if (bCanBeActivedLocallyOnTheRemote)
		{
			LocalImpactedByActor(HazeActor, Hit, Direction);
		}
		else
		{
			if (HazeActor.HasControl())
				NetImpactedByActor(HazeActor, Hit, Direction);
		}
	}

	void ActorImpactEndedByPlayer(AHazePlayerCharacter HazePlayer, EImpactDirection Direction)
	{
		if (bCanBeActivedLocallyOnTheRemote)
		{
			LocalImpactedEndedByPlayer(HazePlayer, Direction);
		}
		else
		{
			if (HazePlayer.HasControl())
				NetImpactEndedByPlayer(HazePlayer, Direction);
		}
	}

	void ActorImpactEnded(AHazeActor HazeActor, EImpactDirection Direction)
	{
		if (bCanBeActivedLocallyOnTheRemote)
		{
			LocalImpactedEndedByActor(HazeActor, Direction);
		}
		else
		{
			if (HazeActor.HasControl())
				NetImpactEndedByActor(HazeActor, Direction);
		}
	}	

};

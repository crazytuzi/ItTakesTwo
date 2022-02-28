struct FFollowRotationCameraPriorityActor
{
	USceneComponent ComponentToFollow;
	EHazeCameraPriority Priority;
	UObject Instigator;
}

class UFollowRotationCameraComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	TArray<FFollowRotationCameraPriorityActor> PriorityActors;

	void Follow(USceneComponent ComponentToFollow, EHazeCameraPriority Priority, UObject Instigator)
	{
//		ComponentToFollow.Owner.OnEndPlay.AddUFunction(this, n"OnActorToFollowEndPlay");

		int i = 0;
		for (; i < PriorityActors.Num(); i++)
		{
			if (PriorityActors[i].Priority <= Priority)
				break;
		}
		FFollowRotationCameraPriorityActor PriorityActor;
		PriorityActor.ComponentToFollow = ComponentToFollow;
		PriorityActor.Priority = Priority;
		PriorityActors.Insert(PriorityActor, i);
	}

	void UnfollowByInstigator(UObject Instigator)
	{
		for (int i = PriorityActors.Num() - 1; i >= 0; i--)
		{
			if (PriorityActors[i].Instigator == Instigator)
			{
				PriorityActors[i].ComponentToFollow.Owner.OnEndPlay.UnbindObject(this);		
				PriorityActors.RemoveAt(i);			
			}
		}
	}

	USceneComponent GetComponentToFollow()
	{
		if (PriorityActors.Num() == 0)
			return nullptr;

		return PriorityActors[0].ComponentToFollow;
	}

	UFUNCTION()
	void OnActorToFollowEndPlay(AActor Actor, EEndPlayReason::Type Reason)
	{
		/*
		for (int i = PriorityActors.Num() - 1; i >= 0; i--)
		{
			if (PriorityActors[i].ComponentToFollow == nullptr || PriorityActors[i].ComponentToFollow.Owner == Actor)
			{
				Actor.OnEndPlay.UnbindObject(this);
				PriorityActors.RemoveAt(i);
			}
		}
		*/
	}

}
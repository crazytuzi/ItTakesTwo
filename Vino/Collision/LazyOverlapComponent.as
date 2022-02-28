struct FLazyOverlapSlot
{
	UPrimitiveComponent Component 		= nullptr;
	bool 				bIsOverlapping 	= false;

	FLazyOverlapSlot(UPrimitiveComponent Comp)
	{
		Component = Comp;
		bIsOverlapping = false;
	}	
}

// Handles overlaps for a set of primitive component against a set of other primitive components.
// For small sets of components this is cheaper than using regular unreal overlapsso is nice to 
// use when you want to optimize something that shouldn't trigger overlap against many other things.
// The drawback is that overlap checking will be done infrequently when at longer distances
// so will not be as exact, and you will be able to get tunnelling.
// Note that if you only ever overlap with players, you can use the LazyPlayerOverlapManagerComponent instead.
class ULazyOverlapComponent : UActorComponent
{
    // If components are beyond this distance from owning actor we do not check overlaps at all
    UPROPERTY(BlueprintReadOnly, EditAnywhere)
    float OverlapMaxDistance = 10000.f;
 
    // Components closer than this distance from owning actor will update overlaps every frame
    UPROPERTY(BlueprintReadOnly, EditAnywhere)
    float ResponsiveDistance = 2500.f;

	// This far outside responsive distance we use maximum tick interval
    UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float MaxTickIntervalDistanceOffset = 2500.f;

	// Maximum tick interval, in seconds, used when closest overlapper is further away than 
	// ResponsiveDistance + MaxTickIntervalDistanceOffset 
    UPROPERTY(BlueprintReadOnly, EditAnywhere)
	float MaxTickInterval = 1.f;

	// If set, we will automatically check overlaps agains any of our owners
	// primitive components with this tag. 
	// If 'None', you need to manually specify which components should check 
	// for overlaps using the AddOwnCollision function.
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly)
	FName OwnCollisionsTag = NAME_None;

	// These players capsule components will automatically be used to check overlaps against
	UPROPERTY()
	EHazeSelectPlayer PlayerOverlappers = EHazeSelectPlayer::Both;

	// Check overlap against the first shape component of these actors. 
	// If there are no shape components, use first primitive component.
	// If the OverlapperTag is set, we check against first component with that tag instead.
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly)
	TArray<AActor> OverlappingActors;

	// If set, we will only use components with this tag when finding components from the OverlappingActors list
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly)
	FName OverlapperComponentTag = NAME_None;	

    private TArray<UPrimitiveComponent> OwnCollisions;
    private TArray<FLazyOverlapSlot> Overlappers;
 
    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		if (OwnCollisionsTag != NAME_None)
		{
			TArray<UActorComponent> Comps = Owner.GetComponentsByTag(UPrimitiveComponent::StaticClass(), OwnCollisionsTag);
			for (UActorComponent Comp : Comps)
			{
				AddOwnCollision(Cast<UPrimitiveComponent>(Comp));
			}
		}

		for (AActor Overlapper : OverlappingActors)
		{
			AddOverlapperActor(Overlapper, OverlapperComponentTag);
		}

		if ((PlayerOverlappers == EHazeSelectPlayer::May) || (PlayerOverlappers == EHazeSelectPlayer::Both))
			AddOverlapper(Game::May.CapsuleComponent);
		if ((PlayerOverlappers == EHazeSelectPlayer::Cody) || (PlayerOverlappers == EHazeSelectPlayer::Both))
			AddOverlapper(Game::Cody.CapsuleComponent);

		SetComponentTickEnabled((OwnCollisions.Num() > 0) && (Overlappers.Num() > 0));
    }
 
	UFUNCTION()
	void AddOwnCollision(UPrimitiveComponent CollisionComp)
	{
		if (CollisionComp == nullptr)
			return;
		OwnCollisions.AddUnique(CollisionComp);
		CollisionComp.bGenerateOverlapEvents = false;
		SetComponentTickEnabled(Overlappers.Num() > 0);
	}

	UFUNCTION()
	void AddOverlapper(UPrimitiveComponent OverlapperComp)
	{
		if (OverlapperComp == nullptr)
			return;

		for (FLazyOverlapSlot Overlapper : Overlappers)
		{
			if (Overlapper.Component == OverlapperComp)
				return;
		}

		Overlappers.Add(FLazyOverlapSlot(OverlapperComp));
		SetComponentTickEnabled(OwnCollisions.Num() > 0);
	}

	UFUNCTION()
	void AddOverlapperActor(AActor OverlapperActor, FName Tag = NAME_None)
	{
		if (OverlapperActor == nullptr)
			return;
		
		if (Tag == NAME_None)
		{
			UPrimitiveComponent OverlapperComp = UShapeComponent::Get(OverlapperActor);
			if (OverlapperComp == nullptr)
				OverlapperComp = UPrimitiveComponent::Get(OverlapperActor);
			AddOverlapper(OverlapperComp);
		}
		else
		{
			TArray<UActorComponent> Comps = Owner.GetComponentsByTag(UPrimitiveComponent::StaticClass(), Tag);
			for (UActorComponent Comp : Comps)
			{
				AddOverlapper(Cast<UPrimitiveComponent>(Comp));
			}
		}
	}

	UFUNCTION()
	void RemoveOverlapper(UPrimitiveComponent OverlapperComp)
	{
		bool bIsEndingOverlap = false;
		for (int i = Overlappers.Num() - 1; i >= 0; i--)
		{
			if (Overlappers[i].Component == OverlapperComp)
			{
				if (Overlappers[i].bIsOverlapping)
					bIsEndingOverlap = true;
				Overlappers.RemoveAtSwap(i);
			}
		}

		if (bIsEndingOverlap)
		{
			// Iterate over copy in case of side effects changing the list
			TArray<UPrimitiveComponent> CurrentOwnCollisions = OwnCollisions;
			for (UPrimitiveComponent OwnComp : OwnCollisions)
			{
				OwnComp.TriggerMutualEndOverlap(OverlapperComp);
			}
		}

		if (Overlappers.Num() == 0)
			SetComponentTickEnabled(false);
	}

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason)
    {
		TArray<UPrimitiveComponent> EndingOverlaps;
		for (FLazyOverlapSlot Overlapper : Overlappers)
		{
			if (Overlapper.bIsOverlapping)
				EndingOverlaps.Add(Overlapper.Component);
		}

		if (EndingOverlaps.Num() > 0)
		{
			// Iterate over copy in case of side effects changing the list
			TArray<UPrimitiveComponent> CurrentOwnCollisions = OwnCollisions;
			for (UPrimitiveComponent OwnComp : OwnCollisions)
			{
				for (UPrimitiveComponent OverlapperComp : EndingOverlaps)
				{
					OwnComp.TriggerMutualEndOverlap(OverlapperComp);
				}
			}
		}
    }
 
    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		TArray<UPrimitiveComponent> BeginningOwnOverlaps;
		TArray<UPrimitiveComponent> BeginningOtherOverlaps;
		TArray<UPrimitiveComponent> EndingOwnOverlaps;
		TArray<UPrimitiveComponent> EndingOtherOverlaps;

        float MinDistSqr = MAX_flt;
		FVector OwnLoc = Owner.ActorLocation;
		float OverlapMaxDistSqr = FMath::Square(OverlapMaxDistance);
        for (FLazyOverlapSlot& Overlapper : Overlappers)
        {
			if (Overlapper.Component == nullptr)
				continue;

            float DistSqr = (Overlapper.Component.WorldLocation - OwnLoc).SizeSquared();
            if (DistSqr < MinDistSqr)
                MinDistSqr = DistSqr;
 
            if (DistSqr <= OverlapMaxDistSqr)
            {
                for (UPrimitiveComponent OwnCollision : OwnCollisions)
                {
                    if (OwnCollision == nullptr)
                        continue;

					bool bIsOverlapping = Trace::ComponentOverlapComponent(Overlapper.Component, OwnCollision, OwnCollision.WorldLocation, OwnCollision.WorldTransform.Rotation);
					if (bIsOverlapping != Overlapper.bIsOverlapping)
                    {
						Overlapper.bIsOverlapping = bIsOverlapping;
                        if (bIsOverlapping)
						{
							BeginningOwnOverlaps.Add(OwnCollision);
							BeginningOtherOverlaps.Add(Overlapper.Component);
						}
                        else
						{
							EndingOwnOverlaps.Add(OwnCollision);
							EndingOtherOverlaps.Add(Overlapper.Component);
						}
                    }
                }
            }
            else if (Overlapper.bIsOverlapping)
            {
				// Out of max range, end overlap
				Overlapper.bIsOverlapping = false;
                for (UPrimitiveComponent OwnCollision : OwnCollisions)
                {
					EndingOwnOverlaps.Add(OwnCollision);
					EndingOtherOverlaps.Add(Overlapper.Component);
				}				
            }
        }
 
		float MaxTickIntervalDistance = ResponsiveDistance + MaxTickIntervalDistanceOffset;
        if (MaxTickIntervalDistance > 0.f)
		{
			if (MinDistSqr < FMath::Square(ResponsiveDistance))
			{
				SetComponentTickInterval(0.f);
			}
			else
			{
				float Fraction = (MaxTickIntervalDistanceOffset > 0 ) ? (FMath::Sqrt(MinDistSqr) - ResponsiveDistance) / MaxTickIntervalDistanceOffset : 1.f;
				float TickInterval = FMath::Clamp(FMath::Lerp(0.f, MaxTickInterval, FMath::Square(Fraction)), 0.f, 1.f);
	            SetComponentTickInterval(TickInterval);
			}
        }

		// Trigger any begin/end overlaps after update, to minimize risk of sideeffects fouling stuff up
		for (int i = 0; i < BeginningOwnOverlaps.Num(); i++)
		{
			BeginningOwnOverlaps[i].TriggerMutualBeginOverlap(BeginningOtherOverlaps[i]);
		}
		for (int i = 0; i < EndingOwnOverlaps.Num(); i++)
		{
			EndingOwnOverlaps[i].TriggerMutualEndOverlap(EndingOtherOverlaps[i]);
		}
    
#if EDITOR
//		bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
		{
			if (MinDistSqr > OverlapMaxDistSqr)
				System::DrawDebugSphere(OwnLoc, 800.f, 4, FLinearColor::Red, 0.0f, 40.f);
			else
				System::DrawDebugSphere(OwnLoc, 500.f, 4, FLinearColor::Green, 0.0f, 30.f);
		}
#endif
	
	}
};


import Peanuts.Triggers.HazeTriggerBase;

event void FActorTriggerEvent(AHazeActor Actor);

class AActorTrigger : AHazeTriggerBase
{
    UPROPERTY(Category = "Actor Trigger")
    TArray<TSubclassOf<AHazeActor>> TriggerOnActorClasses;

    UPROPERTY(Category = "Actor Trigger")
    TArray<AHazeActor> TriggerOnSpecificActors;

    UPROPERTY(Category = "Actor Trigger")
    FActorTriggerEvent OnActorEnter;

    UPROPERTY(Category = "Actor Trigger")
    FActorTriggerEvent OnActorLeave;

    bool ShouldTrigger(AActor Actor) override
    {
        if (TriggerOnSpecificActors.Contains(Cast<AHazeActor>(Actor)))
            return true;

        for (auto SubClass : TriggerOnActorClasses)
        {
            if (!SubClass.IsValid())
                continue;
            if (Actor.IsA(SubClass))
                return true;
        }

        return false;
    }

    void EnterTrigger(AActor Actor) override
    {
        OnActorEnter.Broadcast(Cast<AHazeActor>(Actor));
    }

    void LeaveTrigger(AActor Actor) override
    {
        OnActorLeave.Broadcast(Cast<AHazeActor>(Actor));
    }

	bool IsOverlappingShape(UShapeComponent Shape) const
	{
		if(!bEnabled)
			return false;

		if(!BrushComponent.IsCollisionEnabled())
			return false;

		float DistSq = Shape.GetWorldLocation().DistSquared(BrushComponent.GetWorldLocation());
		float ShapeCollisionSize = GetShapeCollisionSize(Shape);
		float TriggerCollisionSize = GetShapeCollisionSize(BrushComponent.GetCollisionShape());
	
		if(DistSq > FMath::Square((ShapeCollisionSize + TriggerCollisionSize) * 2))
			return false;

		return Trace::ComponentOverlapComponent(
			Shape,
			BrushComponent,
			BrushComponent.WorldLocation,
			BrushComponent.ComponentQuat,
			bTraceComplex = false
		);
	}

	private float GetShapeCollisionSize(UShapeComponent Shape) const
	{
		auto Box = Cast<UBoxComponent>(Shape);
		if(Box != nullptr)
		{
			FVector Extends = Box.GetScaledBoxExtent();
			return FMath::Max(Extends.X, FMath::Max(Extends.Y, Extends.Z));
		}

		auto Sphere = Cast<USphereComponent>(Shape);
		if(Sphere != nullptr)
		{
			return Sphere.GetScaledSphereRadius();
		}

		auto Capsule = Cast<UCapsuleComponent>(Shape);
		if(Capsule != nullptr)
		{
			return Capsule.GetScaledCapsuleHalfHeight();
		}

		return 0;
	}

	private float GetShapeCollisionSize(FCollisionShape Shape) const
	{
		FVector Extends = Shape.GetExtent();
		return FMath::Max(Extends.X, FMath::Max(Extends.Y, Extends.Z));
	}
};
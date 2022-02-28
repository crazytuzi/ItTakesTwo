UCLASS(NotPlaceable, HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Replication", ComponentWrapperClass)
class AHazeTriggerBase : AVolume
{
    // If checked, delegates on this trigger will be completely independent in network.
    UPROPERTY(BlueprintReadOnly, Category = "Trigger")
    bool bTriggerLocally = false;

    default bGenerateOverlapEventsDuringLevelStreaming = true;
	default BrushComponent.SetCollisionProfileName(n"Trigger");

	// If true, the trigger will react to actors, if false it's inert. Use SetTriggerEnabled to enable/disable.
	UPROPERTY(Category = "Trigger", BlueprintReadOnly)
	bool bEnabled = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ECollisionEnabled CollisionEnabled = bEnabled ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision;
		BrushComponent.SetCollisionEnabled(CollisionEnabled);
	}

    // Overridable for subclasses to determine if an actor triggers the volume
    bool ShouldTrigger(AActor Actor)
    {
        return false;
    }

    // Overridable for subclasses that triggers when an actor enters the volume
    void EnterTrigger(AActor Actor)
    {
    }

    // Overridable for subclasses that triggers when an actor leaves the volume
    void LeaveTrigger(AActor Actor)
    {
    }

    // Overridable to determine whether this side is the side to determine overlaps for the passed actor
    bool ShouldControlOverlapsFor(AActor Actor)
    {
        AHazeActor HazeActor = Cast<AHazeActor>(Actor);
        if (HazeActor == nullptr)
            return true;

        return HazeActor.HasControl();
    }

	bool OverlapWithCrumbComponent(AActor OtherActor, FName CrumbDelegateName)
	{
		auto CrumbComp = UHazeCrumbComponent::Get(OtherActor);
		if (CrumbComp == nullptr)
			return false;
			
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.Movement = EHazeActorReplicationSyncTransformType::AttemptWait_AllowManualMovement;
		CrumbParams.AddObject(n"OtherActor", OtherActor);

		CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, CrumbDelegateName), CrumbParams);

		return true;
	}

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        if (bTriggerLocally)
        {
            if (!ShouldTrigger(OtherActor))
                return;
            EnterTrigger(OtherActor);
        }
        else if (ShouldControlOverlapsFor(OtherActor) && ShouldTrigger(OtherActor))
        {
			if (OverlapWithCrumbComponent(OtherActor, n"Crumb_TriggerEnter"))
				return;

			NetTriggerEnter(OtherActor);
        }
    }

    // Trigger volume decided to trigger an enter for the actor
    UFUNCTION(NetFunction)
    void NetTriggerEnter(AActor OtherActor)
    {
        EnterTrigger(OtherActor);
    }

	UFUNCTION(NotBlueprintCallable)
	void Crumb_TriggerEnter(const FHazeDelegateCrumbData& CrumbData)
	{
		EnterTrigger(Cast<AActor>(CrumbData.GetObject(n"OtherActor")));
	}

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        if (bTriggerLocally)
        {
            if (!ShouldTrigger(OtherActor))
                return;
            LeaveTrigger(OtherActor);
        }
        else if (ShouldControlOverlapsFor(OtherActor) && ShouldTrigger(OtherActor))
        {
			if (OverlapWithCrumbComponent(OtherActor, n"Crumb_TriggerLeave"))
				return;

			NetTriggerLeave(OtherActor);
        }
    }

    // Trigger volume decided to trigger a leave for the actor
    UFUNCTION(NetFunction)
    void NetTriggerLeave(AActor OtherActor)
    {
        LeaveTrigger(OtherActor);
    }

	UFUNCTION(NotBlueprintCallable)
	void Crumb_TriggerLeave(const FHazeDelegateCrumbData& CrumbData)
	{
		LeaveTrigger(Cast<AActor>(CrumbData.GetObject(n"OtherActor")));
	}

	UFUNCTION()
	void SetTriggerEnabled(bool bNewEnabled = false)
	{
		bEnabled = bNewEnabled;
		ECollisionEnabled CollisionEnabled = bEnabled ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision;
		BrushComponent.SetCollisionEnabled(CollisionEnabled);
	}
};
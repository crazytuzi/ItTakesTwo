
 
/* Will disable once the players have exited the volume */

class USwarmSlideDisableCollision : UBoxComponent
{
	default CollisionEnabled = ECollisionEnabled::QueryOnly;
	default SetCollisionObjectType(ECollisionChannel::ECC_WorldStatic);
	default SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);
	// default bGenerateOverlapEventsDuringLevelStreaming = false;

	bool bHasLeftVolume_May = false;
	bool bHasLeftVolume_Cody = false;

	// If true, the trigger will react to actors, if false it's inert. Use SetTriggerEnabled to enable/disable.
	UPROPERTY(Category = "Trigger", BlueprintReadOnly)
	bool bEnabled = true;

    UPROPERTY(BlueprintReadOnly, Category = "Trigger")
    bool bTriggerLocally = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetTriggerEnabled(bEnabled);
	}

	UFUNCTION()
	void SetTriggerEnabled(bool bNewEnabled = false)
	{
		bEnabled = bNewEnabled;
		SetCollisionEnabled(bEnabled ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision);

		OnComponentBeginOverlap.Unbind(this, n"HandleComponentBeginOverlap");
		OnComponentEndOverlap.Unbind(this, n"HandleComponentEndOverlap");

		if(bEnabled)
		{
			OnComponentBeginOverlap.AddUFunction(this, n"HandleComponentBeginOverlap");
			OnComponentEndOverlap.AddUFunction(this, n"HandleComponentEndOverlap");
		}
		
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SetCollisionEnabled(bEnabled ? ECollisionEnabled::QueryOnly : ECollisionEnabled::NoCollision);
	}

	// UFUNCTION(BlueprintOverride)
	// void Tick(const float Dt)
	// {
	// 	PrintToScreen("" + Owner.GetName() + " is ticking." + " HasLeftVolume_May: " + bHasLeftVolume_May + ", HasLefVolume_Cody: " + bHasLeftVolume_Cody, Color = FLinearColor::Red);
	// }

	UFUNCTION()
	void HandleComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
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

	UFUNCTION()
    void HandleComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
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

    void LeaveTrigger(AActor Actor) 
    {
		if(HasControl() == false)
			return;

		if(!bHasLeftVolume_May && Actor == Game::GetMay())
			bHasLeftVolume_May = true;

		if(!bHasLeftVolume_Cody && Actor == Game::GetCody())
			bHasLeftVolume_Cody = true;

//		Print("LeaveTrigger: " + Actor.GetName(), Duration = 3.f);
//		Print(" HasLeftVolume_May: " + bHasLeftVolume_May + ", HasLefVolume_Cody: " + bHasLeftVolume_Cody);

		/*
			 the call might come in twice due to the swarm being disabled, which triggers OnComponentEndOverlap,
			 about the same time we perform this network call.  Our repro case was killing the 
			 swarm while going through it in slide with High lag. 
		 */
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		if(HazeOwner.IsActorDisabled(this))
			return;

		if(bHasLeftVolume_Cody && bHasLeftVolume_May)
			NetDisableSwarm();
	}

	int DebugTimesDisabled = 0;

	UFUNCTION(NetFunction)
	void NetDisableSwarm()
	{

#if TEST 
		DebugTimesDisabled++;
		if(DebugTimesDisabled > 1)
		{
			devEnsure(false,
				Owner.GetName() + 
				" tried to disable itself twice. \n 
				Everything is still working but it's a sign of something being wrong. \n 
				Please let Sydney know about this"
			);
		}
//		Print("Disabling Overlapping Swarm: " + Owner.GetName(), Duration = 3.f);
#endif TEST

		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.DisableActor(this);
		SetTriggerEnabled(false);
	}

	UFUNCTION(BlueprintPure)	
	bool BothPlayersHaveLeftVolume() const
	{
		return bHasLeftVolume_Cody && bHasLeftVolume_May;
	}

    bool ShouldTrigger(AActor Actor) 
    {
        auto Player = Cast<AHazePlayerCharacter>(Actor);
        if (Player == nullptr)
            return false;

		return true;
    }

    void EnterTrigger(AActor Actor)
    {
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

    // Overridable to determine whether this side is the side to determine overlaps for the passed actor
    bool ShouldControlOverlapsFor(AActor Actor)
    {
        AHazeActor HazeActor = Cast<AHazeActor>(Actor);
        if (HazeActor == nullptr)
            return true;

        return HazeActor.HasControl();
    }

}
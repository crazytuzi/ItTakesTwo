import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

struct FCastleEnemyKnockback
{
	int KnockbackId = -1;
	FVector SourceLocation;
    FVector Displacement;
    float TimeRemaining = 0.f;
	float Duration = 0.f;
	float Height = 0.f;
    UCurveFloat KnockbackCurve = nullptr;
    UCurveFloat KnockUpCurve = nullptr;
	FName Tag;
	bool bNeutralized = false;
};

class UCastleEnemyKnockbackComponent : UActorComponent
{
	TArray<FCastleEnemyKnockback> LocalKnockbacks;
	int NextLocalId = 1;

	TArray<FCastleEnemyKnockback> RemoteKnockbacks;

	bool bHaveBaseLocation = false;
	FVector BaseLocation;
	FVector PredictedBaseLocation;

	int ControlHandshake = -1;
	TArray<FCastleEnemyKnockback> QueuedLocalKnockbacks;
	TArray<FCastleEnemyKnockback> QueuedRemoteKnockbacks;

	bool ShouldQueueKnockbacks() const
	{
		if (!HasControl())
			return false;
		if (ControlHandshake != -1)
			return true;
		return false;
	}

	int GetHighestRemoteId() const
	{
		int Id = 0;
		for (auto& Knock : RemoteKnockbacks)
		{
			if (Knock.KnockbackId > Id)
				Id = Knock.KnockbackId;
		}

		return Id;
	}

	int GetHighestLocalId() const
	{
		int Id = 0;
		for (auto& Knock : LocalKnockbacks)
		{
			if (Knock.KnockbackId > Id)
				Id = Knock.KnockbackId;
		}

		return Id;
	}

	void FlushQueuedKnockbacks()
	{

		for(FCastleEnemyKnockback Knock : QueuedLocalKnockbacks)
		{
			Log(""+Owner+" - Control: "+HasControl()+" - Dequeue local knock "+Knock.KnockbackId);
			LocalKnockbacks.Add(Knock);
			NetAddRemoteKnockback(Network::HasWorldControl(), Knock);
		}
		QueuedLocalKnockbacks.Empty();

		for(FCastleEnemyKnockback Knock : QueuedRemoteKnockbacks)
		{
			Log(""+Owner+" - Control: "+HasControl()+" - Dequeue remote knock "+Knock.KnockbackId);
			RemoteKnockbacks.Add(Knock);
		}
		QueuedRemoteKnockbacks.Empty();
	}

	UFUNCTION(NetFunction)
	void NetAddRemoteKnockback(bool bFromControl, FCastleEnemyKnockback Knockback)
	{
		if (bFromControl == Network::HasWorldControl())
			return;

		if (ShouldQueueKnockbacks())
		{
			Log(""+Owner+" - Control: "+HasControl()+" - Queued Remote Knockback "+Knockback.KnockbackId);
			QueuedRemoteKnockbacks.Add(Knockback);
		}
		else
		{
			Log(""+Owner+" - Control: "+HasControl()+" - Remote Knockback "+Knockback.KnockbackId);
			RemoteKnockbacks.Add(Knockback);
		}
	}
};

class UCastleEnemyTakeDamageKnockbackCapability : UHazeCapability
{
    default CapabilityTags.Add(n"CastleEnemyKnockback");

    UPROPERTY()
    float BaseKnockbackDistance = 30.f;
    UPROPERTY()
    float KnockbackTime = 0.25f;
    UPROPERTY()
    UCurveFloat KnockbackCurve;

    UPROPERTY()
    float KnockUpHeight = 30.f;
    // Note: knock up does not happen at all if you don't specify a curve
    UPROPERTY()
    UCurveFloat KnockUpCurve;

	// Which knockback tags to respond to. If this array is empty, only respond to knockbacks without a tag.
	UPROPERTY()
	TArray<FName> RespondToKnockbackTags;

    ACastleEnemy Enemy;
	UCastleEnemyKnockbackComponent KnockComp;

    default TickGroup = ECapabilityTickGroups::BeforeMovement;
    default TickGroupOrder = 30;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		KnockComp = UCastleEnemyKnockbackComponent::GetOrCreate(Enemy);

        Enemy.OnKnockedBack.AddUFunction(this, n"OnKnockedBack");
    }

    UFUNCTION()
    void OnKnockedBack(ACastleEnemy KnockedEnemy, FCastleEnemyKnockbackEvent Event)
    {
        // Can't knockback on damage events that are non-directional
        if (Event.Direction.IsNearlyZero())
            return;

		// Filter out knockbacks we're interested in
		if (RespondToKnockbackTags.Num() != 0)
		{
			if (!RespondToKnockbackTags.Contains(Event.KnockbackTag))
				return;
		}
		else
		{
			if (Event.KnockbackTag != NAME_None)
				return;
		}

		bool bControlKnock = false;
		if (Event.Source == nullptr)
			bControlKnock = Enemy.HasControl();
		else
			bControlKnock = Event.Source.HasControl();

		if (!bControlKnock)
			return;

        // Add an impulse dependent on the damage event's weight
        FCastleEnemyKnockback Knockback;
		Knockback.KnockbackId = KnockComp.NextLocalId++;
		Knockback.SourceLocation = Enemy.ActorLocation;
        Knockback.Displacement = Event.Direction * (BaseKnockbackDistance * Event.HorizontalForce);
		Knockback.Duration = KnockbackTime * Event.DurationMultiplier;
        Knockback.TimeRemaining = Knockback.Duration;
		Knockback.Height = KnockUpHeight * Event.VerticalForce;
		Knockback.Tag = Event.KnockbackTag;

		if (Event.KnockBackCurveOverride != nullptr)
			Knockback.KnockbackCurve = Event.KnockBackCurveOverride;
		else
			Knockback.KnockbackCurve = KnockbackCurve;

		if (Event.KnockUpCurveOverride != nullptr)
			Knockback.KnockUpCurve = Event.KnockUpCurveOverride;
		else
			Knockback.KnockUpCurve = KnockUpCurve;

		if (KnockComp.ShouldQueueKnockbacks())
		{
			Log(""+Owner+" - Control: "+HasControl()+" - Local Queued Knockback "+Knockback.KnockbackId);
			KnockComp.QueuedLocalKnockbacks.Add(Knockback);
		}
		else
		{
			Log(""+Owner+" - Control: "+HasControl()+" - Local Knockback "+Knockback.KnockbackId);
			KnockComp.LocalKnockbacks.Add(Knockback);
			KnockComp.NetAddRemoteKnockback(Network::HasWorldControl(), Knockback);
		}
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        return EHazeNetworkActivation::DontActivate; 
    }
};
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyTakeDamageKnockbackCapability;

class UCastleEnemyControlledBySideCapability : UHazeCapability
{
    default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 101;

    default CapabilityTags.Add(n"CastleEnemyControlledBySide");

    ACastleEnemy Enemy;
	AHazePlayerCharacter ControlPlayer;
	UHazeCrumbComponent CrumbComp;
	UCastleEnemyKnockbackComponent KnockComp;

	float AttemptLockTimer = 0.f;
	bool bLocked = false;
	
	bool bRequestingLock = false;
	bool bLockSuccess = false;

	bool bIsControlLocking = false;
	int ControlLockingPreRejects = 0;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Enemy);
		KnockComp = UCastleEnemyKnockbackComponent::Get(Enemy);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
		if (!Network::IsNetworked())
			return EHazeNetworkActivation::DontActivate; 
		if (Enemy.bKilled)
			return EHazeNetworkActivation::DontActivate; 
        if (Enemy.AggroedPlayer != nullptr && !Enemy.AggroedPlayer.HasControl())
            return EHazeNetworkActivation::ActivateUsingCrumb; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if (bLockSuccess)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Player", Enemy.AggroedPlayer);
	}

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		ControlPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"Player"));

		bLocked = false;
		AttemptLockTimer = 0.f;

		bLockSuccess = false;
		bRequestingLock = false;
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		devEnsure(bLockSuccess || !bLocked || !Enemy.HasActorBegunPlay(), "Cannot block CastleEnemyControlledBySideCapability while locking.");
		if (bLockSuccess)
		{
			Unlock();

			devEnsure(KnockComp.QueuedLocalKnockbacks.Num() == 0, "QueuedLocalKnockbacks is not empty");
			devEnsure(KnockComp.QueuedRemoteKnockbacks.Num() == 0, "QueuedRemoteKnockbacks is not empty");

			Enemy.SetControlSide(ControlPlayer);
			if (Enemy.HasControl())
				Enemy.OnReceivedControl();

			Log(""+Owner+" - Control: "+HasControl()+" - Post SetControlSide "+ControlPlayer);
		}
		else
		{
			if (bLocked)
				Log(""+Owner+" - Control: "+HasControl()+" SetControlSide Failed");
		}
    }

	bool CanLock()
	{
		if (Owner.IsAnyCapabilityActive(n"CastleEnemyKnockback"))
			return false;
		if (Owner.IsAnyCapabilityActive(n"CastleEnemyAttack"))
			return false;
		return true;
	}

	void Lock()
	{
		ensure(!bLocked);
		bLocked = true;
		Owner.BlockCapabilities(n"CastleEnemyKnockback", this);
		Owner.BlockCapabilities(n"CastleEnemyAttack", this);
		Enemy.BlockAutoDisable(true);

		Log(""+Owner+" - Control: "+HasControl()+" - LOCK");
	}

	void Unlock()
	{
		ensure(bLocked);
		bLocked = false;
		Owner.UnblockCapabilities(n"CastleEnemyKnockback", this);
		Owner.UnblockCapabilities(n"CastleEnemyAttack", this);
		Enemy.BlockAutoDisable(false);

		Log(""+Owner+" - Control: "+HasControl()+" - UNLOCK");
	}

	UFUNCTION()
	void Crumb_RequestLockOfRemote(FHazeDelegateCrumbData Crumb)
	{
		if (HasControl())
		{
			bRequestingLock = true;
		}
		else
		{
			if (ControlLockingPreRejects > 0)
			{
				// We already handled the lock response in PreTick earlier,
				// the crumb should be ignored now
				ControlLockingPreRejects -= 1;
				return;
			}

			bIsControlLocking = false;

			if (CanLock())
			{
				Lock();
				NetLockResponseFromRemote(true);
				bLockSuccess = true;
			}
			else
			{
				NetLockResponseFromRemote(false);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetLockResponseFromRemote(bool bSuccess)
	{
		if (HasControl())
		{
			bRequestingLock = false;
			if (bSuccess)
			{
				bLockSuccess = true;
			}
			else
			{
				Unlock();
				AttemptLockTimer = 0.5f;
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetStartControlLocking()
	{
		if (!HasControl())
			bIsControlLocking = true;
	}

    UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl() && bIsControlLocking)
		{
			// If we have a crumb that will arrive in the future
			// that wants to lock us, we pre-reject the lock
			// if at any point we become unable to lock.
			// This prevents deadlocks from occurring because the crumb trail is stalled.
			if (!CanLock())
			{
				bIsControlLocking = false;
				ControlLockingPreRejects += 1;
				NetLockResponseFromRemote(false);
				Log(""+Owner+" - Control: "+HasControl()+" - Early Lock Reject");
			}
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (HasControl())
		{
			if (!bRequestingLock)
			{
				AttemptLockTimer -= DeltaTime;
				if (AttemptLockTimer <= 0.f)
				{
					if (CanLock())
					{
						Lock();

						NetStartControlLocking();

						FHazeDelegateCrumbParams CrumbParams;
						CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
						CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_RequestLockOfRemote"), CrumbParams);
					}
				}
			}
		}
    }
};
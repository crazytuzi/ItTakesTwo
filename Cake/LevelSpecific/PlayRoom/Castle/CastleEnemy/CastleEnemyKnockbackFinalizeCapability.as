import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyTakeDamageKnockbackCapability;

class UCastleEnemyKnockbackFinalizeCapability : UCharacterMovementCapability
{
    default CapabilityTags.Add(n"CastleEnemyKnockback");

    ACastleEnemy Enemy;
	UCastleEnemyKnockbackComponent KnockComp;

    default TickGroup = ECapabilityTickGroups::ActionMovement;
    default TickGroupOrder = 30;

	bool bKnockbacksDone = false;
	FVector LocalBaseLocation;

    UFUNCTION(BlueprintOverride)
    void Setup(FCapabilitySetupParams Params)
    {
        Enemy = Cast<ACastleEnemy>(Owner);
		KnockComp = UCastleEnemyKnockbackComponent::GetOrCreate(Enemy);

		Super::Setup(Params);
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        if (KnockComp.LocalKnockbacks.Num() != 0 || KnockComp.RemoteKnockbacks.Num() != 0)
            return EHazeNetworkActivation::ActivateLocal; 
        return EHazeNetworkActivation::DontActivate; 
    }

    UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
        if (bKnockbacksDone)
            return EHazeNetworkDeactivation::DeactivateLocal; 
        return EHazeNetworkDeactivation::DontDeactivate; 
    }

    UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		bKnockbacksDone = false;
		LocalBaseLocation = Enemy.ActorLocation;

		if (HasControl())
		{
			FVector ActiveBaseLocation;
			if (KnockComp.LocalKnockbacks.Num() != 0)
				ActiveBaseLocation = KnockComp.LocalKnockbacks[0].SourceLocation;
			else if (KnockComp.RemoteKnockbacks.Num() != 0)
				ActiveBaseLocation = KnockComp.RemoteKnockbacks[0].SourceLocation;
			NetSendBaseLocation(ActiveBaseLocation);
		}
		else
		{
			if (KnockComp.RemoteKnockbacks.Num() != 0)
				KnockComp.PredictedBaseLocation = KnockComp.RemoteKnockbacks[0].SourceLocation;
			else if (KnockComp.LocalKnockbacks.Num() != 0)
				KnockComp.PredictedBaseLocation = KnockComp.LocalKnockbacks[0].SourceLocation;
			else
				KnockComp.PredictedBaseLocation = Enemy.ActorLocation;
		}

		Owner.TriggerMovementTransition(this);

        Owner.BlockCapabilities(n"CastleEnemyMovement", this);
        Owner.BlockCapabilities(n"CastleEnemyAggro", this);
        Owner.BlockCapabilities(n"CastleEnemyControlledBySide", this);
        Owner.BlockCapabilities(n"CastleEnemyAttack", this);
        Owner.BlockCapabilities(n"CastleEnemyAbility", this);
        Owner.BlockCapabilities(n"CastleEnemyFalling", this);

		Log(""+Owner+" - Control: "+HasControl()+" - Activate Knockback");
    }

    UFUNCTION(BlueprintOverride)
    void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		ensure(bKnockbacksDone || Enemy.Level.IsBeingRemoved() || Enemy.World.IsTearingDown());

        MoveComp.SetVelocity(FVector::ZeroVector);
		Enemy.MeshOffsetComponent.ResetWithTime(0.f);

        Owner.UnblockCapabilities(n"CastleEnemyMovement", this);
        Owner.UnblockCapabilities(n"CastleEnemyAggro", this);
        Owner.UnblockCapabilities(n"CastleEnemyControlledBySide", this);
        Owner.UnblockCapabilities(n"CastleEnemyAttack", this);
        Owner.UnblockCapabilities(n"CastleEnemyAbility", this);
        Owner.UnblockCapabilities(n"CastleEnemyFalling", this);

		Owner.TriggerMovementTransition(this);

		KnockComp.FlushQueuedKnockbacks();

		Log(""+Owner+" - Control: "+HasControl()+" - Deactivate Knockback");
    }

	UFUNCTION(NetFunction)
	void NetSendBaseLocation(FVector BaseLocation)
	{
		KnockComp.bHaveBaseLocation = true;
		KnockComp.BaseLocation = BaseLocation;
	}

	FVector GetBaseLocation()
	{
		// If we've already received a base location, use it
		if (KnockComp.bHaveBaseLocation)
			return KnockComp.BaseLocation;

		// Try to use the most likely base location we predicted
		return KnockComp.PredictedBaseLocation;
	}

	bool bHasAnyAllowedKnockbacks;
    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		bool bNeutralizeAllKnockback = false;
		if (IsActioning(n"NeutralizeKnockback"))
			bNeutralizeAllKnockback = true;

		bHasAnyAllowedKnockbacks = false;

		float TotalTimeRemaining = 0.f;
		bool bAllFinished = true;

		FVector CurrentDisplacement;
		float CurrentHeight = 0.f;

		FName CurrentTag;

		int NumLocal = KnockComp.LocalKnockbacks.Num();
		int NumRemote = KnockComp.RemoteKnockbacks.Num();

		for (int i = NumLocal + NumRemote - 1; i >= 0; --i)
		{
			FCastleEnemyKnockback& Knock = (i >= NumLocal) ? KnockComp.RemoteKnockbacks[i-NumLocal] : KnockComp.LocalKnockbacks[i];
			Knock.TimeRemaining -= DeltaTime;

			if (bNeutralizeAllKnockback)
				Knock.bNeutralized = true;

			if (Knock.TimeRemaining > 0.f)
			{
				bAllFinished = false;
				TotalTimeRemaining = FMath::Max(TotalTimeRemaining, Knock.TimeRemaining);
			}

			if (Knock.bNeutralized)
				continue;
			
			bHasAnyAllowedKnockbacks = true;
			float KnockPct = FMath::Clamp(1.f - (Knock.TimeRemaining / FMath::Max(Knock.Duration, 0.01f)), 0.f, 1.f);

			// Calculate current height for this knockback
			//  Height is only cosmetic, so we don't try to sync it
			float KnockHeight = 0.f;
			UCurveFloat UpCurve = Knock.KnockUpCurve;
			if (Knock.KnockUpCurve != nullptr)
				KnockHeight = Knock.KnockUpCurve.GetFloatValue(KnockPct) * Knock.Height;

			if (KnockHeight > CurrentHeight)
				CurrentHeight = KnockHeight;

			// Calculate current displacement for this knockback
			float DisplacePct = KnockPct;
			UCurveFloat KnockCurve = Knock.KnockbackCurve;
			if (Knock.KnockbackCurve != nullptr)
				DisplacePct = FMath::Clamp(Knock.KnockbackCurve.GetFloatValue(KnockPct), 0.f, 1.f);
			CurrentDisplacement += Knock.Displacement * DisplacePct;

			// Update the tag used for animation, purely visual
			if (Knock.Tag != NAME_None && CurrentTag == NAME_None)
				CurrentTag = Knock.Tag;
		}

		// Lerp our local base location towards the actual confirmed base location
		//  This will try to ensure that the enemy ends at the same location
		if (bNeutralizeAllKnockback)
		{
			LocalBaseLocation = Enemy.ActorLocation;
			KnockComp.BaseLocation = Enemy.ActorLocation;
			KnockComp.PredictedBaseLocation = Enemy.ActorLocation;
		}
		else
		{
			LocalBaseLocation = FMath::Lerp(LocalBaseLocation, GetBaseLocation(), DeltaTime / (TotalTimeRemaining + DeltaTime));
		}

		// Update displacemnt from our local base location
		FVector TargetLocation = LocalBaseLocation + CurrentDisplacement;

		if (MoveComp.CanCalculateMovement() && bHasAnyAllowedKnockbacks)
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyKnockback");
			Movement.ApplyDelta(TargetLocation - Enemy.ActorLocation);
			MoveComp.Move(Movement);

			if (bAllFinished)
				Enemy.SendMovementAnimationRequest(Movement, n"Movement", NAME_None);
			else if (Enemy.bKilled)
				Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyDeath", CurrentTag);
			else
				Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyKnockback", CurrentTag);
		}

		// Update visual height of mesh
		if (bHasAnyAllowedKnockbacks)
			Enemy.MeshOffsetComponent.OffsetLocationWithTime(Enemy.ActorLocation + FVector(0.f, 0.f, CurrentHeight), 0.f);
		else
			Enemy.MeshOffsetComponent.ResetWithTime(0.f);

		// Do handshake for stopping the 
		if (bAllFinished)
		{
			if (!Network::IsNetworked())
			{
				bKnockbacksDone = true;
				KnockComp.LocalKnockbacks.Empty();
				KnockComp.RemoteKnockbacks.Empty();
			}
			else if (HasControl())
			{
				if (KnockComp.ControlHandshake == -1)
					NetControlHandshake(KnockComp.GetHighestRemoteId());
			}
			else
			{
				if (KnockComp.ControlHandshake != -1)
				{
					// If we've added any local knockbacks after the control
					// initiated the handshake, deny the handshake
					if (KnockComp.GetHighestLocalId() > KnockComp.ControlHandshake)
					{
						NetHandshakeDeclined();
					}
					else
					{
						// Handshake was succesful, deactivate the knockback capability and finalize
						NetHandshakeAccepted();
					}
				}
			}
		}
		else if (TotalTimeRemaining > 0.1f)
		{
			// Decline the handshake if we still have a fair duration to go in our knockback,
			// so the other side doesn't have to wait so long
			if (KnockComp.ControlHandshake != -1)
			{
				NetHandshakeDeclined();
			}
		}
    }

	UFUNCTION(NetFunction)
	void NetControlHandshake(int ControlId)
	{
		KnockComp.ControlHandshake = ControlId;
	}

	UFUNCTION(NetFunction)
	void NetHandshakeAccepted()
	{
		KnockComp.bHaveBaseLocation = false;
		KnockComp.LocalKnockbacks.Empty();
		KnockComp.RemoteKnockbacks.Empty();

		// Knockback is fully done, end the capability
		KnockComp.ControlHandshake = -1;
		bKnockbacksDone = true;
	}

	UFUNCTION(NetFunction)
	void NetHandshakeDeclined()
	{
		KnockComp.ControlHandshake = -1;

		// Add all the knockbacks we queued earlier, we're going to continue this knockback
		KnockComp.FlushQueuedKnockbacks();
	}
};
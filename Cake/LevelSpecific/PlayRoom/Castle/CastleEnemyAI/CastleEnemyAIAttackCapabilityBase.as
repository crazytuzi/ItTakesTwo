import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleStatics;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastlePlayer.CastleComponent;

struct FAttackExecuteEvent
{
	FVector AttackLocation;
	FVector AttackDirection;
	AHazePlayerCharacter AttackingPlayer;
	bool bCanceled = false;
};

class UCastleEnemyAIAttackCapabilityBase : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 150;

	default CapabilityTags.Add(n"CastleEnemyAI");
	default CapabilityTags.Add(n"CastleEnemyAttack");

	ACastleEnemy Enemy;

	// How long it takes for the attack to execute and fire the projectile
	UPROPERTY()
	float AttackPoint = 0.2f;

	// Amount of time before the attack point that we track the player for
	UPROPERTY()
	float PreAttackTrackTime = 0.f;

	// Amount of time the enemy is 'stuck' after attacking
	UPROPERTY()
	float PostAttackTime = 0.f;

	// Only attack if we're closer than this distance to a player
	UPROPERTY()
	float AttackMaxDistance = 300.f;

	// Minimum cooldown for the attack
	UPROPERTY()
	float AttackCooldownMin = 4.f;

	// Maximum cooldown for the attack
	UPROPERTY()
	float AttackCooldownMax = 6.f;

	// Don't attack unless the player is within this many degrees of our forward facing
	UPROPERTY()
	float FacingMaxAngle = 40.f;

	// Don't attack unless the player is inside line of sight
	UPROPERTY()
	bool bAttackRequiresLineOfSight = true;

	// Whether to track instantly, or based on facing direction
	UPROPERTY()
	bool bTrackInstantly = false;

	// Min cooldown after the player first gets in range before we can start an attack
	UPROPERTY()
	float FirstInRangeCooldownMin = 0.f;

	// Max cooldown after the player first gets in range before we can start an attack
	UPROPERTY()
	float FirstInRangeCooldownMax = 0.f;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	AHazePlayerCharacter AttackingPlayer;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector AttackLocation;
	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector AttackDirection;

	float Cooldown = 0.f;
	bool bCanceled = false;
	bool bExecuted = false;
	bool bAttackDone = false;
	float AttackTimer = 0.f;
	int CanceledAttackCounter = 0;
	UHazeBaseMovementComponent MoveComp;
	UCastleComponent PlayerCastleComp;
	UHazeCrumbComponent CrumbComp;

	FVector FinalTrackDirection;
	bool bHaveFinalTrack = false;
	bool bWasTracking = false;

	float OutOfRangeTimer = 0.f;
	float InRangeCooldown = 0.f;
	bool bTriggeredInRangeCooldown = false;

	TArray<FAttackExecuteEvent> PendingExecutes;

	UPROPERTY()
	UAkAudioEvent ActivatedAudioEvent;
	UPROPERTY()
	UAkAudioEvent SwingAudioEvent;
	UPROPERTY()
	UNiagaraSystem AttackEffect;

	UHazeAkComponent HazeAkComp;

	bool CanStartAttack()
	{
		if (Cooldown > 0.f)
			return false;
		if (Enemy.IsActorDisabled())
			return false;
		return true;
	}

	int GetTargetPriority(AHazePlayerCharacter Player)
	{
		return 0;
	}

	bool HasAttackControl()
	{
		return HasControl();
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Enemy = Cast<ACastleEnemy>(Owner);
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		HazeAkComp = UHazeAkComponent::Get(Owner, n"HazeAkComponent");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (IsReadyToExecute() && PendingExecutes.Num() > 0)
		{
			ExecuteAttack(PendingExecutes[0]);
			PendingExecutes.RemoveAt(0);
		}

		if (Cooldown > 0.f)
		{
			Cooldown -= DeltaTime;
		}

		if (AttackingPlayer == nullptr && CanStartAttack())
		{
			int MaxPriority = 0;
			float MinDistance = MAX_flt;
			for (auto Player : Game::GetPlayers())
			{
				float Distance = Player.ActorLocation.Distance(Enemy.ActorLocation);
				if (Enemy.EnemyLoseAggroRange > 0.f && Distance > Enemy.EnemyLoseAggroRange)
					continue;
				if (Enemy.EnemyLoseAggroRange <= 0.f && Distance > Enemy.EnemyAggroRange)
					continue;
				if (Distance > AttackMaxDistance)
					continue;

				if (bAttackRequiresLineOfSight && !Enemy.HasLineOfSightTo(Player))
					continue;

				if (!Enemy.CanTargetPlayer(Player))
					continue;

				FVector ToPlayer = Player.ActorLocation - Enemy.ActorLocation;
				float FacingAngle = Enemy.ActorForwardVector.AngularDistance(ToPlayer); 
				if (FacingAngle > FMath::DegreesToRadians(FacingMaxAngle))
					continue;

				int PlayerPriority = GetTargetPriority(Player);
				if (PlayerPriority > MaxPriority || (Distance < MinDistance && PlayerPriority >= MaxPriority))
				{
					if (!bTriggeredInRangeCooldown && FirstInRangeCooldownMax > 0.f)
					{
						bTriggeredInRangeCooldown = true;
						InRangeCooldown = FMath::RandRange(FirstInRangeCooldownMin, FirstInRangeCooldownMax);
					}

					if (InRangeCooldown <= 0.f)
					{
						AttackingPlayer = Player;
						MinDistance = Distance;
						MaxPriority = PlayerPriority;
					}
				}
			}
		}

		if (bTriggeredInRangeCooldown)
		{
			InRangeCooldown -= DeltaTime;

			if (AttackingPlayer == nullptr)
			{
				OutOfRangeTimer += DeltaTime;
				if (OutOfRangeTimer >= 10.f)
				{
					InRangeCooldown = 0.f;
					OutOfRangeTimer = 0.f;
					bTriggeredInRangeCooldown = false;
				}
			}
			else
			{
				OutOfRangeTimer = 0.f;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (AttackingPlayer != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate; 
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsAttackDone() || Enemy.bKilled)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate; 
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"AttackingPlayer", AttackingPlayer);
		Params.AddVector(n"AttackLocation", AttackingPlayer.ActorCenterLocation);

		if (bTrackInstantly)
		{
			FVector ToPlayer = (AttackingPlayer.ActorLocation - Enemy.ActorLocation);
			ToPlayer.Z = 0.f;
			Params.AddVector(n"AttackDirection", ToPlayer.GetSafeNormal());
		}
		else
		{
			Params.AddVector(n"AttackDirection", Enemy.ActorForwardVector);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bCanceled = false;
		bAttackDone = false;
		AttackingPlayer = Cast<AHazePlayerCharacter>(ActivationParams.GetObject(n"AttackingPlayer"));
		PlayerCastleComp = UCastleComponent::Get(AttackingPlayer);
		AttackLocation = ActivationParams.GetVector(n"AttackLocation");
		AttackDirection = ActivationParams.GetVector(n"AttackDirection");
		AttackTimer = 0.f;
		bWasTracking = true;
		BP_OnStartAttack();

		Enemy.BlockCapabilities(n"CastleEnemyAI", this);
		Enemy.BlockCapabilities(n"CastleEnemyAggro", this);
		Enemy.BlockCapabilities(n"CastleEnemyControlledBySide", this);
		Enemy.BlockCapabilities(n"CastleEnemyMovement", this);
	}

	void UpdateTrackedTargetLocation(float DeltaTime)
	{
		if (PlayerCastleComp != nullptr && PlayerCastleComp.bIsBlinking)
		{
			AttackLocation = PlayerCastleComp.BlinkStartLocation;
			AttackLocation.Z = AttackingPlayer.ActorCenterLocation.Z;
		}
		else
		{
			AttackLocation = AttackingPlayer.ActorCenterLocation;
		}


		FVector ToPlayer = (AttackingPlayer.ActorLocation - Enemy.ActorLocation);
		ToPlayer.Z = 0.f;
		ToPlayer = ToPlayer.GetSafeNormal();

		if (bTrackInstantly)
		{
			AttackDirection = ToPlayer;
		}
		else
		{
			AttackDirection = FMath::QInterpConstantTo(
				FRotator::MakeFromX(AttackDirection).Quaternion(),
				FRotator::MakeFromX(ToPlayer).Quaternion(),
				DeltaTime,
				Enemy.FacingRotationSpeed).ForwardVector;
		}

		OnUpdateAttackDirection();
	}

	void OnUpdateAttackDirection()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (!bExecuted)
		{
			bCanceled = true;

			if (HasAttackControl())
			{
				FAttackExecuteEvent Event;
				Event.AttackDirection = AttackDirection;
				Event.AttackLocation = AttackLocation;
				Event.AttackingPlayer = AttackingPlayer;
				Event.bCanceled = true;

				CanceledAttackCounter += 1;
				NetExecuteAttack(Event);
			}
			else
			{
				if (PendingExecutes.Num() > 0)
				{
					ExecuteAttack(PendingExecutes[0]);
					PendingExecutes.RemoveAt(0);
				}
				else
				{
					CanceledAttackCounter += 1;
				}
			}
		}

		AttackingPlayer = nullptr;
		bExecuted = false;
		bHaveFinalTrack = false;
		Enemy.UnblockCapabilities(n"CastleEnemyAI", this);
		Enemy.UnblockCapabilities(n"CastleEnemyAggro", this);
		Enemy.UnblockCapabilities(n"CastleEnemyControlledBySide", this);
		Enemy.UnblockCapabilities(n"CastleEnemyMovement", this);
		Enemy.StopAllSlotAnimations();

		Cooldown = FMath::RandRange(AttackCooldownMin, AttackCooldownMax);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Count down the timer until our attack point to execute the attack
		AttackTimer += DeltaTime;
		if (AttackTimer >= AttackPoint)
		{
			if (!bExecuted)
			{
				if (!bCanceled)
				{
					if(HasAttackControl())
					{
						FAttackExecuteEvent Event;
						Event.AttackDirection = AttackDirection;
						Event.AttackLocation = AttackLocation;
						Event.AttackingPlayer = AttackingPlayer;
						NetExecuteAttack(Event);
					}
				}
			}
		}
		else
		{
			if (IsStillTracking())
				UpdateTrackedTargetLocation(DeltaTime);
		}

		if (PreAttackTrackTime > 0.f && bWasTracking && !IsStillTracking())
		{
			if (HasAttackControl())
			{
				bWasTracking = false;
				NetSendFinalTrackedTarget(AttackDirection);
			}
			else
			{
				if (bHaveFinalTrack)
				{
					if (!AttackDirection.Equals(FinalTrackDirection))
					{
						AttackDirection = FMath::QInterpConstantTo(
							FRotator::MakeFromX(AttackDirection).Quaternion(),
							FRotator::MakeFromX(FinalTrackDirection).Quaternion(),
							DeltaTime,
							PI * 2.f).ForwardVector;
						OnUpdateAttackDirection();
					}
					else
					{
						bWasTracking = false;
					}
				}
			}
		}

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement Movement = MoveComp.MakeFrameMovement(n"CastleEnemyAttack");
			if (HasControl())
			{
				MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(AttackDirection), Enemy.FacingRotationSpeed);
				Movement.ApplyTargetRotationDelta();
			}
			else
			{
				FHazeActorReplicationFinalized ConsumedParams;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

				MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(AttackDirection), Enemy.FacingRotationSpeed);
				Movement.ApplyTargetRotationDelta();
			}

			MoveComp.Move(Movement);
			CrumbComp.LeaveMovementCrumb();

			Enemy.SetAnimBoolParam(n"TelegraphingAttack", !bExecuted);
			Enemy.SendMovementAnimationRequest(Movement, n"CastleEnemyAttack", NAME_None);
		}
	}

	UFUNCTION(NetFunction)
	void NetSendFinalTrackedTarget(FVector TrackDirection)
	{
		bHaveFinalTrack = true;
		FinalTrackDirection = TrackDirection;
	}

	bool IsAttackDone() const
	{
		return bExecuted && AttackTimer >= AttackPoint + PostAttackTime;
	}

	bool IsReadyToExecute() const
	{
		if (!bExecuted && AttackTimer >= AttackPoint && IsActive())
			return true;
		if (CanceledAttackCounter > 0)
			return true;
		return false;
	}

	float GetChargePercentage()
	{
		if (AttackPoint <= 0.f)
			return 1.f;
		return FMath::Min(1.f, AttackTimer / AttackPoint);
	}

	bool IsStillTracking()
	{
		return AttackTimer <= PreAttackTrackTime;
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetExecuteAttack(FAttackExecuteEvent Event)
	{
		if (IsReadyToExecute())
			ExecuteAttack(Event);
		else
			PendingExecutes.Add(Event);
	}

	void ExecuteAttack(FAttackExecuteEvent Event)
	{
		if (CanceledAttackCounter > 0)
			CanceledAttackCounter -= 1;

		if (IsActive())
		{
			bExecuted = true;
			AttackTimer = AttackPoint;
		}

		MoveComp.SetTargetFacingRotation(Math::MakeRotFromX(Event.AttackDirection), Enemy.FacingRotationSpeed);

		BP_OnExecuteAttack(Event);
		PlayEffects(Event);
		Enemy.SetCapabilityActionState(n"AudioStartAttack", EHazeActionState::ActiveForOneFrame);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for(auto& PendingEvt : PendingExecutes)
			ExecuteAttack(PendingEvt);
		PendingExecutes.Empty();
	}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Start Attack"))
	void BP_OnStartAttack() {}

	UFUNCTION(BlueprintEvent, Meta = (DisplayName = "On Execute Attack"))
	void BP_OnExecuteAttack(FAttackExecuteEvent Event) {}

	void PlayEffects(FAttackExecuteEvent Event)
	{
		if (AttackEffect != nullptr)
		{
			Niagara::SpawnSystemAtLocation(AttackEffect,
				Enemy.Mesh.GetSocketLocation(n"LeftAttach"),
				Enemy.ActorRotation);
		}
	}
};
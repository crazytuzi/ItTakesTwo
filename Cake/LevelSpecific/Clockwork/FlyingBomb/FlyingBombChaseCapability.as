import Cake.LevelSpecific.Clockwork.FlyingBomb.FlyingBomb;
import Peanuts.Network.RelativeCrumbLocationCalculator;

class UFlyingBombChaseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"FlyingBombChase");
	default CapabilityTags.Add(n"FlyingBombAI");
	default CapabilityDebugCategory = n"FlyingBomb";

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 50;

	AFlyingBomb Bomb;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	AClockworkBird BirdWithinAggroRange; 
	UBirdFlyingBombTrackerComponent TrackerWithinAggroRange;

	AClockworkBird ChasingBird; 
	UBirdFlyingBombTrackerComponent ChasingTracker;

	const float ChaseBackwardOffset = 400.f;
	const float ChaseCreepOffset = 400.f;

	int BombNumber;
	FVector ChaseStartLocation;
	bool bStartedChasing = false;
	bool bReachedChaseTarget = false;
	bool bUsingCrumbCalculator = false;

	FHazeAcceleratedRotator AccelRotation;
	FHazeAcceleratedVector AccelInitialPosition;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bomb = Cast<AFlyingBomb>(Owner);
		MoveComp = Bomb.MoveComp;
		CrumbComp = Bomb.CrumbComp;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		BirdWithinAggroRange = nullptr;
		TrackerWithinAggroRange = nullptr;

		if (Bomb.CurrentState == EFlyingBombState::Idle && Bomb.HeldByBird == nullptr)
		{
			for (auto Bird : Bomb.NearbyBirds)
			{
				if (Bird.ActorLocation.Distance(Bomb.ActorLocation) >= Bomb.AggroRadius)
					continue;
				if (Bird.ActivePlayer == nullptr)
					continue;

				auto TrackerComp = UBirdFlyingBombTrackerComponent::Get(Bird.ActivePlayer);
				if (TrackerComp != nullptr)
				{
					if (TrackerComp.HeldBomb != nullptr)
					{
						BirdWithinAggroRange = Bird;
						TrackerWithinAggroRange = TrackerComp;
						break;
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Bomb.CurrentState != EFlyingBombState::Idle)
			return EHazeNetworkActivation::DontActivate;
		if (Bomb.HeldByBird != nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (BirdWithinAggroRange == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (TrackerWithinAggroRange.ChasingBombs.Num() >= TrackerWithinAggroRange.MaxChasingBombs)
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Bird", BirdWithinAggroRange);
		ActivationParams.AddObject(n"Tracker", TrackerWithinAggroRange);

		ActivationParams.AddNumber(n"BombNumber", TrackerWithinAggroRange.BombCounter);
		TrackerWithinAggroRange.BombCounter += 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ChasingTracker = Cast<UBirdFlyingBombTrackerComponent>(ActivationParams.GetObject(n"Tracker"));
		ChasingBird = Cast<AClockworkBird>(ActivationParams.GetObject(n"Bird"));

		Bomb.SetControlSide(ChasingBird.ActivePlayer);

		Bomb.ChasingTracker = ChasingTracker;
		Bomb.ChasingBird = ChasingBird;

		ChasingTracker.ChasingBombs.Add(Bomb);

		bStartedChasing = false;
		bReachedChaseTarget = false;
		ChaseStartLocation = Bomb.ActorLocation;
		BombNumber = ActivationParams.GetNumber(n"BombNumber");
		Bomb.State = EFlyingBombState::Chasing;

		FRotator StartRotation = Bomb.ActorRotation;
		StartRotation.Pitch = Bomb.VisualRoot.RelativeRotation.Pitch;
		StartRotation.Roll = 0.f;
		AccelRotation.SnapTo(StartRotation);

		AccelInitialPosition.SnapTo(Bomb.ActorLocation, Bomb.ActorVelocity);

		CrumbComp.IncludeCustomParamsInActorReplication(
			FVector::ZeroVector, Bomb.VisualRoot.RelativeRotation,
			Instigator = this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ChasingTracker.ChasingBombs.Remove(Bomb);

		Bomb.ChasingTracker = nullptr;
		Bomb.ChasingBird = nullptr;

		if (bUsingCrumbCalculator)
			CrumbComp.RemoveCustomWorldCalculator(this);
		CrumbComp.RemoveCustomParamsFromActorReplication(this);
	}

	UFUNCTION()
	void Crumb_CaughtUpToPlayer(FHazeDelegateCrumbData CrumbData)
	{
		bUsingCrumbCalculator = true;
		CrumbComp.MakeCrumbsUseCustomWorldCalculator(
			URelativeCrumbLocationCalculator::StaticClass(),
			this, ChasingBird.RootComponent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;

		if (HasControl())
		{
			FRotator WantRotation = AccelRotation.Value;
			FVector WantPosition;
			float RotationAccel = 1.f;

			FVector ChaseOffset = ChasingTracker.GetChaseSlot(BombNumber);
			ChaseOffset.X -= ChaseBackwardOffset;

			if (bReachedChaseTarget)
			{
				float ChasePct = (ActiveDuration - Bomb.ChaseTargetDelay - Bomb.ChaseEstablishTime) / Bomb.ChaseCatchupTime;
				ChaseOffset *= Bomb.ChaseCurve.GetFloatValue(ChasePct);

				FTransform TargetSpace = ChasingBird.Mesh.WorldTransform;
				FVector CurrentOffset = ChaseOffset;
				WantPosition = TargetSpace.TransformPosition(CurrentOffset);

				FVector DeltaToBird = (ChasingBird.ActorLocation - Bomb.ActorLocation);
				if (!DeltaToBird.IsNearlyZero())
				{
					WantRotation = FRotator::MakeFromX(DeltaToBird);
					WantRotation.Pitch += 90.f;
					WantRotation.Roll = 0.f;
				}
			}
			else if (bStartedChasing)
			{
				FTransform TargetSpace = ChasingBird.Mesh.WorldTransform;
				FVector ChaseTarget = TargetSpace.TransformPosition(ChaseOffset);

				WantPosition = AccelInitialPosition.AccelerateTo(ChaseTarget,
					FMath::Max(Bomb.ChaseEstablishTime - (ActiveDuration - Bomb.ChaseTargetDelay), 0.f), DeltaTime);
				RotationAccel = 0.5f;

				if (AccelInitialPosition.Value.Equals(ChaseTarget, 10.f))
				{
					Bomb.SetCapabilityActionState(n"ChaseLockedOn", EHazeActionState::Active);
					bReachedChaseTarget = true;
				}

				if (!MoveComp.Velocity.IsNearlyZero())
				{
					WantRotation = FRotator::MakeFromX(MoveComp.Velocity.GetSafeNormal());
					WantRotation.Pitch += 90.f;
					WantRotation.Roll = 0.f;
				}

				if (!bUsingCrumbCalculator)
				{
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
					CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_CaughtUpToPlayer"), CrumbParams);
				}
			}
			else
			{
				RotationAccel = Bomb.ChaseTargetDelay;
				if (ActiveDuration >= Bomb.ChaseTargetDelay)
					bStartedChasing = true;

				FVector DeltaToBird = (ChasingBird.ActorLocation - Bomb.ActorLocation);
				if (!DeltaToBird.IsNearlyZero())
				{
					WantRotation = FRotator::MakeFromX(DeltaToBird);
					WantRotation.Pitch += 90.f;
					WantRotation.Roll = 0.f;
				}

				WantPosition = ChaseStartLocation;
				RotationAccel = FMath::Max(Bomb.ChaseTargetDelay - ActiveDuration, 0.f);
			}

			WantPosition += WantRotation.RightVector * FMath::MakePulsatingValue(ActiveDuration, 3.f, 0.5f) * 10.f;
			WantPosition += WantRotation.UpVector * FMath::MakePulsatingValue(ActiveDuration, 3.f, 0.5f) * 10.f;

			AccelRotation.AccelerateTo(WantRotation, RotationAccel, DeltaTime);
			Bomb.VisualRoot.RelativeRotation = FRotator(AccelRotation.Value.Pitch, 0.f, 0.f);

			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"FlyingBombChase");
			FrameMove.ApplyDelta(WantPosition - Bomb.ActorLocation);
			FrameMove.SetRotation(FRotator(0.f, AccelRotation.Value.Yaw, 0.f).Quaternion());
			FrameMove.OverrideCollisionProfile(n"BlockAll");
			MoveComp.Move(FrameMove);

			if (HasControl() && MoveComp.ForwardHit.bBlockingHit)
			{
				Owner.SetCapabilityActionState(n"Explode", EHazeActionState::Active);

				auto HitActor = MoveComp.ForwardHit.Actor;
				auto HitPlayer = Cast<AHazePlayerCharacter>(HitActor);
				auto HitBird = Cast<AClockworkBird>(HitActor);
				if (HitBird != nullptr)
					HitActor = HitBird.ActivePlayer;

				Owner.SetCapabilityAttributeObject(n"HitObject", HitActor);
			}

			CrumbComp.SetCustomCrumbRotation(Bomb.VisualRoot.RelativeRotation);
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"FlyingBombChase");

			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);
			Bomb.VisualRoot.SetRelativeRotation(ConsumedParams.CustomCrumbRotator);
			MoveComp.Move(FrameMove);
		}
	}
};
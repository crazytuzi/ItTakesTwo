
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunBezierCurveAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Attack;

	FTransform BeginTransform = FTransform::Identity;
	FTransform VictimTransform = FTransform::Identity;
	FQuat SwarmToVictimQuat = FQuat::Identity;
	float AttackStartedTimeStamp = 0.f;
	float DistanceToPlayerAtStart = 0.f;
	float LerpAlpha = 0.f;
	float LerpAlphaSpeed = 0.f;

	int32 NumAttacksPerformedTotal = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_PostTimeWindow(Settings.HitAndRun.Attack.TimeSpentAttacking_MIN))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);

		if (DeactivationParams.IsStale())
		{
			NumAttacksPerformedTotal = 0;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.HitAndRun.Attack.AnimSettingsDataAsset,
			this,
			Settings.HitAndRun.Attack.TimeSpentAttacking_MIN
		);

		BehaviourComp.NotifyStateChanged();
		AttackStartedTimeStamp = Time::GetGameTimeSeconds();

		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);

		BeginTransform = SwarmActor.GetActorTransform();
		DistanceToPlayerAtStart = VictimComp.DistanceToVictim();
		VictimTransform = VictimComp.PlayerVictim.GetActorTransform();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);

		// Translate current Swarm velocity -> Fraction -> LerpSpeed.
		float DeltaMoveFromSpeed = MoveComp.PhysicsVelocity.Size();
		DeltaMoveFromSpeed *= SwarmActor.GetActorDeltaSeconds();
		LerpAlphaSpeed = FMath::Clamp(DeltaMoveFromSpeed / DistanceToPlayerAtStart, 0.f, 1.f);
		LerpAlpha = 0.f;
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		// Only keep track of the victims transform for a certain amount of time.  
		const float TimeSinceAttackStarted = Time::GetGameTimeSince(AttackStartedTimeStamp);
		if (TimeSinceAttackStarted < Settings.HitAndRun.Attack.KeepTrackOfVictimDuration)
		{
			VictimTransform = VictimComp.GetVictimCenterTransform();
			SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);
		}

		UpdateBezierAttack(DeltaSeconds);

		if (LerpAlpha == 1.f)
			OnAttackCompleted();

		BehaviourComp.FinalizeBehaviour();
 	}

	void OnAttackCompleted() 
	{
		++NumAttacksPerformedTotal;

		if (NumAttacksPerformedTotal >= Settings.HitAndRun.Attack.NumTotalAttacks)
		{
			PrioritizeState(ESwarmBehaviourState::CirclePlayer);
			NumAttacksPerformedTotal = 0;
		}
		else 
		{
			PrioritizeState(ESwarmBehaviourState::TelegraphBetween);
		}
	}

	void UpdateBezierAttack(const float Dt)
	{
		const float TimeSinceAttackStarted = Time::GetGameTimeSince(AttackStartedTimeStamp);
		const float AttackDuration = 2.5f;
		LerpAlpha = FMath::Clamp(TimeSinceAttackStarted / AttackDuration, 0.f, 1.f);
 		LerpAlpha = FMath::Pow(LerpAlpha, 0.7f);
// 		LerpAlpha = FMath::Pow(LerpAlpha, 2.f);

// 		LerpAlpha += LerpAlphaSpeed * Dt;
// 		LerpAlpha += Settings.HitAndRun.Attack.Acceleration * Dt * Dt * 0.5f;
// 		LerpAlphaSpeed += Settings.HitAndRun.Attack.Acceleration * Dt;
// 		LerpAlpha = FMath::Min(1.f, LerpAlpha);

		const FVector ToVictim = (VictimTransform.GetLocation() - BeginTransform.GetLocation());
		const FVector DirToVictimConstrained = ToVictim.VectorPlaneProject(
			VictimComp.PlayerVictim.GetActorUpVector()
		).GetSafeNormal();

		FVector DesiredEndLocation = VictimTransform.GetLocation();
		DesiredEndLocation += (DirToVictimConstrained * DistanceToPlayerAtStart * 1.0f);
		const FVector SP = BeginTransform.GetLocation();
		const FVector HalfDelta = (SP - VictimTransform.GetLocation()) * 0.5f;
		const FVector CP1 = VictimTransform.GetLocation() + HalfDelta;
 		const FVector PlayerZOffset = FVector(0.f, 0.f, 0.f);
 		const FVector CP2 = VictimTransform.GetLocation() + PlayerZOffset;
		const FVector EP = DesiredEndLocation;
		const FVector PointOnBezierSpline = Math::GetPointOnCubicBezierCurve(
			SP,
			CP1,
			CP2,
			EP,
			LerpAlpha
		);

		FTransform DesiredEndTransform = FTransform(
			SwarmActor.MovementComp.GetFacingRotationTowardsLocation(PointOnBezierSpline),
			PointOnBezierSpline
		);

// 		// Make the swarm roll when it attacks
// 		FQuat DesiredQuat = DesiredEndTransform.GetRotation();
// 		DesiredQuat	*= FQuat(FVector::ForwardVector, Roller * DEG_TO_RAD);
// 		DesiredEndTransform.SetRotation(DesiredQuat);

		MoveComp.InterpolateToTargetLocation(
			DesiredEndTransform.GetLocation(),
			BIG_NUMBER,
			true,
			Dt
		);

		MoveComp.InterpolateToTargetRotation(
			DesiredEndTransform.GetRotation(),
			3.f,
			true,
			Dt
		);

		FVector DebugOneStart = BeginTransform.GetLocation();
		FVector DebugOneEnd = VictimTransform.GetLocation();
		System::DrawDebugLine(DebugOneStart, DebugOneEnd, FLinearColor::Red, Thickness = 0.f);

		FVector DebugTwoStart = VictimTransform.GetLocation();
		FVector DebugTwoEnd = DesiredEndLocation;
		System::DrawDebugLine(DebugTwoStart, DebugTwoEnd, FLinearColor::Blue, Thickness = 0.f);

		System::DrawDebugPoint(PointOnBezierSpline, 10.f, FLinearColor::Red, 0.1f);
 		System::DrawDebugPoint(SwarmActor.GetActorLocation(), 4.f, FLinearColor::Yellow, 10.f);
	}

}




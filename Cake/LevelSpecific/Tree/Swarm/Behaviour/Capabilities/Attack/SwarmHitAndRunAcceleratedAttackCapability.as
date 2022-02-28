
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunAcceleratedAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Attack;

	FTransform VictimTransform = FTransform::Identity;
	FVector AttackVelocity = FVector::ZeroVector;
	FQuat SwarmToVictimQuat = FQuat::Identity;
	int32 NumAttacksPerformedTotal = 0;
	float AttackStartedTimeStamp = 0.f;

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
			NumAttacksPerformedTotal = 0;
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

		AttackVelocity = MoveComp.TranslationVelocity;
		VictimTransform = VictimComp.PlayerVictim.GetActorTransform();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float Dt)
 	{
		// Only keep track of the victims transform for a certain amount of time.  
		const float TimeSinceAttackStarted = Time::GetGameTimeSince(AttackStartedTimeStamp);
		if (TimeSinceAttackStarted < Settings.HitAndRun.Attack.KeepTrackOfVictimDuration)
		{
			VictimTransform = VictimComp.PlayerVictim.GetActorTransform();
		}

		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);

		const FVector ToVictimNormalized = SwarmToVictimQuat.Vector();
		const float ToVictimDOTUp = ToVictimNormalized.DotProduct(FVector::UpVector);

		Print("ToVictimDOtUp" + ToVictimDOTUp);

		FVector AttackAcceleration = ToVictimNormalized;
		AttackAcceleration += (FVector::UpVector * FMath::Pow(ToVictimDOTUp,3.f) * 3.f);
		AttackAcceleration.Normalize();
		AttackAcceleration *= 1.2f;

		FVector DeltaMove = AttackVelocity * Dt + AttackAcceleration * 0.5f * Dt * Dt;

		AttackVelocity += AttackAcceleration * Dt;

		// Make the swarm roll when it attacks
// 		SwarmToVictimQuat *= FQuat(FVector::ForwardVector, Roller * DEG_TO_RAD);
// 		DeltaMove = DeltaMove.GetClampedToMaxSize(100.f);

		MoveComp.DesiredSwarmActorTransform.AddToTranslation(DeltaMove);
		MoveComp.InterpolateToTargetRotation(SwarmToVictimQuat, 3.f, true, Dt);

		// Temp hardcoded.

		FVector DStart = SwarmActor.GetActorLocation();
		FVector DEnd = SwarmActor.GetActorLocation() + ToVictimNormalized * 1000.f;
		System::DrawDebugArrow(DStart, DEnd, 100.f, FLinearColor::Red, 0.f, 10.f);

		const float SwarmVelocityDOTToVictim = MoveComp.TranslationVelocity.DotProduct(ToVictimNormalized);

		if (TimeSinceAttackStarted > Settings.HitAndRun.Attack.TimeSpentAttacking_MAX)
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

}




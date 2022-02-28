
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunCirclePlayerCapability: USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::CirclePlayer;

	float PrevAngDeg = 0.f;
	FVector PlayerSwarmDirection = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
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

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.HitAndRun.CirclePlayer.AnimSettingsDataAsset,
			this,
			Settings.HitAndRun.CirclePlayer.TimeSpentCircling_MIN
		);

		BehaviourComp.NotifyStateChanged();

		MoveComp.InitMoveAlongSpline();
		StartQuat = MoveComp.DesiredSwarmActorTransform.GetRotation();
 	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

	FQuat StartQuat = FQuat::Identity;

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const float MaxTime = Settings.HitAndRun.CirclePlayer.TimeSpentCircling_MAX;
		const float MinTime = Settings.HitAndRun.CirclePlayer.TimeSpentCircling_MIN;

		// Get to the spline first
		FVector SplinePos = MoveComp.SplineSystemPos.GetWorldLocation();

		TArray<FHitResult> Hits;
		MoveComp.RayTraceMulti(
			SplinePos + (FVector::UpVector * 1000),
			SplinePos - (FVector::UpVector * 5000),
			Hits,
			ETraceTypeQuery::WaterTrace
		);

		if(Hits.Num() != 0)
		{
			SplinePos = Hits.Last().ImpactPoint;

			// Assuming Swarm width radius, 
			// because it is clipping the water.
			SplinePos += FVector::UpVector * 1000.f;
		}

		const FVector SwarmPos = SwarmActor.GetActorLocation();
		const float DistToSplinePosSQ = SplinePos.DistSquared(SwarmPos);
		if (BehaviourComp.GetStateDuration() < MinTime && DistToSplinePosSQ > 1000.f)
		{
			MoveComp.SpringToTargetWithTime(
				SplinePos,
				MinTime - BehaviourComp.GetStateDuration(),
				DeltaSeconds
			);

			// System::DrawDebugPoint(SplinePos, 4.f, FLinearColor::Blue, 1.5f); 

			MoveComp.SlerpToTargetRotation(
				StartQuat,
				MoveComp.SplineSystemPos.GetWorldOrientation(),
				BehaviourComp.GetStateDuration() / MinTime
			);
		}
		// then pursue along spline 
		else
		{
			// MoveComp.LerpAlongSpline(
			// 	Settings.HitAndRun.CirclePlayer.InterpStepSize,
			// 	DeltaSeconds
			// );

			bool bReachedEnd = !MoveComp.SplineSystemPos.Move(Settings.HitAndRun.CirclePlayer.InterpStepSize * DeltaSeconds);
			if(bReachedEnd && MoveComp.SplineSystemPos.Spline.IsClosedLoop())
			{
				MoveComp.SplineSystemPos.Move(-MoveComp.SplineSystemPos.Spline.GetSplineLength());
				bReachedEnd = !MoveComp.SplineSystemPos.Move(Settings.HitAndRun.CirclePlayer.InterpStepSize * DeltaSeconds);
			}

			FVector TargetPos = MoveComp.SplineSystemPos.GetWorldLocation();

			Hits.Reset();
			MoveComp.RayTraceMulti(
				TargetPos + (FVector::UpVector * 1000),
				TargetPos - (FVector::UpVector * 5000),
				Hits,
				ETraceTypeQuery::WaterTrace
			);

			if(Hits.Num() != 0)
				TargetPos = Hits.Last().ImpactPoint;

			// Assuming Swarm width radius, 
			// because it is clipping the water.
			TargetPos += FVector::UpVector * 1000.f;

			MoveComp.SpringToTargetLocation(TargetPos, 30.f, 0.6f, DeltaSeconds);
			// MoveComp.DesiredSwarmActorTransform.SetLocation(TargetPos);
			MoveComp.InterpolateToTargetRotation(
				MoveComp.SplineSystemPos.GetWorldOrientation(),
				3.f,
				false,
				DeltaSeconds 
			);

			// System::DrawDebugPoint(MoveComp.DesiredSwarmActorTransform.GetLocation(), 4.f, FLinearColor::Yellow, 1.5f); 
			// Print("" + Hits.Last().GetActor());

		}

		// Proceed to next state once we've circled long enough
		if (BehaviourComp.GetStateDuration() > MaxTime)
			RequestNextState();
		
		// Or if player has started shooting the swarm. 
		if (BehaviourComp.HasExplodedSinceStateChanged_PostTimeWindow(MinTime))
			RequestNextState();

		BehaviourComp.FinalizeBehaviour();
	}

	void RequestNextState() 
	{
		// TEMP Until we figure out how to manage ATTACK and ULTIMATES in same sheet
// 		if (BehaviourComp.IsUltimateOnCooldown(Settings.HitAndRun.AttackUltimate.Cooldown))
			PrioritizeState(ESwarmBehaviourState::TelegraphInitial);
// 		else 
// 			PrioritizeState(ESwarmBehaviourState::AttackUltimate);
	}
}


































import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Components.MovementComponent;

class USwarmHitAndRunCatmullRomAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Attack;

	FQuat SwarmToVictimQuat = FQuat::Identity;
	FVector VictimLocation = FVector::ZeroVector;

	FVector RelativeToSplineOffset_SwarmPos = FVector::ZeroVector;
	FVector RelativeToSplineOffset_Victim = FVector::ZeroVector;
	FVector RelativeToSplineOffset_Start = FVector::ZeroVector;
	FVector RelativeToSplineOffset_End= FVector::ZeroVector;

	float LerpAlpha = 0.f;

	int32 NumAttacksPerformedTotal = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.IsVictimGrounded() == false)
			return EHazeNetworkActivation::DontActivate;

 		if(MoveComp.GetSplineToFollow() == nullptr)
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

 		if(MoveComp.GetSplineToFollow() == nullptr)
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
			Settings.HitAndRun.Attack.AnimBlendInTime
		);

		BehaviourComp.NotifyStateChanged();
		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);

		InitMovement();
		bImpulseApplied = false;
	}

	void UpdateSwarmToVictimQuat() 
	{
		// Calc swarm rotation to be looking at victim, but constrained to world XY
		FQuat DummySwing;
		MoveComp.GetFacingRotationTowardsLocation(VictimLocation).ToSwingTwist(
			FVector::UpVector,
//			VictimComp.GetVictimGroundNormal(),
			DummySwing,
			SwarmToVictimQuat	
		);
	}

	void InitMovement() 
	{
		VictimLocation = VictimComp.GetLastValidGroundLocation();
		UpdateSwarmToVictimQuat();

		// Calculate relative offsets because we are chasing a moving vehicle.
		const FVector SwarmPos = MoveComp.DesiredSwarmActorTransform.GetLocation();
		const FVector SplineWorldLocation = MoveComp.GetSplineToFollowLocation();

		// StartLocation
		FVector StartLocationOnSpline = MoveComp.GetSplineToFollow().FindLocationClosestToWorldLocation(
			SwarmPos,
			ESplineCoordinateSpace::World
		);
		StartLocationOnSpline.Z = SwarmPos.Z;
		RelativeToSplineOffset_Start = StartLocationOnSpline - SplineWorldLocation;

		// EndLocation
		FVector EndLocationOnSpline = MoveComp.GetSplineToFollow().FindLocationClosestToWorldLocation(
			SplineWorldLocation + (VictimLocation - SwarmPos).GetSafeNormal() * RelativeToSplineOffset_Start.Size(),
			ESplineCoordinateSpace::World
		);

		EndLocationOnSpline.Z = VictimLocation.Z;
		EndLocationOnSpline.Z += 500.f;
		EndLocationOnSpline.Z += 500.f;

		RelativeToSplineOffset_End = EndLocationOnSpline - SplineWorldLocation;
		RelativeToSplineOffset_SwarmPos = SwarmPos - SplineWorldLocation;
	}


	void UpdateMovement(const float DeltaSeconds)
	{
		// The boat and the spline will be moving. This will be our reference point. 
		const FVector SplineWorldLocation = MoveComp.GetSplineToFollowLocation();
		const FVector SwarmPos = MoveComp.DesiredSwarmActorTransform.GetLocation();

		// We keep the transform relative to the spline because player is "riding" the spline. 
		if (BehaviourComp.GetStateDuration() < Settings.HitAndRun.Attack.KeepTrackOfVictimDuration)
		{
			const FVector VictimLoc = VictimComp.GetLastValidGroundLocation();
			RelativeToSplineOffset_Victim = VictimLoc - SplineWorldLocation;
		}

		VictimLocation = SplineWorldLocation + RelativeToSplineOffset_Victim;
		UpdateSwarmToVictimQuat();

		// Make the swarm look at the player
//		MoveComp.InterpolateToTargetRotation(SwarmToVictimQuat, 1.5f, true, DeltaSeconds);
		MoveComp.InterpolateToTargetRotation(SwarmToVictimQuat, 3.f, false, DeltaSeconds);

		// Update alpha used for the spline lerping (and to know when we are done)
		const float Duration = Settings.HitAndRun.Attack.TimeSpentAttacking_MAX;
		LerpAlpha = FMath::Clamp(BehaviourComp.GetStateDuration() / Duration, 0.f, 1.f);

		FVector StartLocation = SplineWorldLocation + RelativeToSplineOffset_Start;
		FVector EndLocation = SplineWorldLocation + RelativeToSplineOffset_End;
		FVector SwarmStartLocation = SplineWorldLocation + RelativeToSplineOffset_SwarmPos;

		// compensating for water surface. @TODO: linetrace instead
		EndLocation.Z = VictimLocation.Z;
		EndLocation.Z += 500.f;
		EndLocation.Z += 500.f;

		// System::DrawDebugPoint(EndLocation, 4.f, FLinearColor::Red, 1.5f); 

//		FVector StartLocation = MoveComp.GetSplineToFollow().FindLocationClosestToWorldLocation(
//			SplineWorldLocation + RelativeToSplineOffset_Start,
//			ESplineCoordinateSpace::World
//		);
//		StartLocation.Z = SwarmPos.Z;
//		FVector EndLocation = MoveComp.GetSplineToFollow().FindLocationClosestToWorldLocation(
//			SplineWorldLocation + RelativeToSplineOffset_End,
//			ESplineCoordinateSpace::World
//		);
//		EndLocation.Z = VictimLocation.Z + 1000.f;

		const FVector VictimLookingDir = VictimComp.GetVictimLookingDirectionConstrainedToXY();
//		FVector HandleStart = StartLocation - (VictimLookingDir * RelativeToSplineOffset_Start.Size());
//		FVector HandleEnd = EndLocation + (VictimLookingDir * RelativeToSplineOffset_End.Size());

//		FVector HandleStart = StartLocation - VictimLookingDir;
		FVector HandleStart = SwarmStartLocation - VictimLookingDir;
		FVector HandleEnd = EndLocation + VictimLookingDir;

		TArray<FVector> SplinePoints;
		SplinePoints.Add(SwarmStartLocation);

		// this is only really needed if the spline is rotating with the boat.
//		SplinePoints.Add(StartLocation);

//		FVector IntermediateLocation_Start = VictimLocation + (StartLocation - VictimLocation)*0.5f;
//		IntermediateLocation_Start.Z = VictimLocation.Z;
//		SplinePoints.Add(IntermediateLocation_Start);

		SplinePoints.Add(VictimLocation);
		SplinePoints.Add(EndLocation);

		const FVector TargetLocation = Math::GetLocationOnCRSpline(
			HandleStart,
			SplinePoints,
			HandleEnd,
			LerpAlpha, 
			Damping = 0.2f
		);

		TArray<FHitResult> Hits;
		const FVector DeltaTrace = FVector::UpVector * 5000.f;
		MoveComp.RayTraceMulti(
			TargetLocation + (FVector::UpVector * 1000),
			TargetLocation - (FVector::UpVector * 5000),
			Hits,
			ETraceTypeQuery::WaterTrace
		);

		if(Hits.Num() != 0)
		{
			const FVector TraceTargetLocation = Hits.Last().ImpactPoint;
			MoveComp.SpringToTargetLocation(TraceTargetLocation, 30.f, 0.6f, DeltaSeconds);
			// System::DrawDebugPoint(TraceTargetLocation, 4.f, FLinearColor::Yellow, 1.5f); 
			// Print("" + Hits.Last().GetActor());
		}
		else
		{
			MoveComp.DesiredSwarmActorTransform.SetLocation(TargetLocation);
		}

	}

	bool bImpulseApplied = false;

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		 UpdateMovement(DeltaSeconds);

		if(LerpAlpha == 1.f)
			OnAttackCompleted();

		BehaviourComp.FinalizeBehaviour();

//		for(const FVector P : SplinePoints)
//			System::DrawDebugPoint(P, 4.f, FLinearColor::Green, 0.f); 

//		System::DrawDebugPoint( HandleEnd, 4.f, FLinearColor::White, 0.f); 
//		System::DrawDebugPoint( HandleStart, 4.f, FLinearColor::Black, 0.f); 
//		System::DrawDebugPoint( EndLocation, 4.f, FLinearColor::Red, 0.f); 
//		System::DrawDebugPoint( StartLocation, 4.f, FLinearColor::Blue, 0.f); 
//		System::DrawDebugPoint( SwarmStartLocation, 4.f, FLinearColor::Blue, 0.f); 
//		System::DrawDebugPoint( TargetLocation, 4.f, FLinearColor::Yellow, 1.5f); 
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

			// We'll have to reset in case this is the only capability we have.
			InitMovement();
			BehaviourComp.NotifyStateChanged();
		}
	}

}


























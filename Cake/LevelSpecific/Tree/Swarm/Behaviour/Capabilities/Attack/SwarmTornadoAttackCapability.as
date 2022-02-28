

import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmTornadoAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Attack;

	FQuat SwarmToVictimQuat = FQuat::Identity;
	FVector VictimLocation = FVector::ZeroVector;

	FVector VictimOffsetFromSpline = FVector::ZeroVector;
	FVector StartOffsetFromVictim = FVector::ZeroVector;
	FVector EndOffsetFromVictim= FVector::ZeroVector;

	float LerpAlpha = 0.f;

	int32 NumAttacksPerformedTotal = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
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

		if(BehaviourComp.HasExplodedSinceStateChanged_PostTimeWindow(Settings.Tornado.Attack.TimeSpentAttacking_MIN))
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
			Settings.Tornado.Attack.AnimSettingsDataAsset,
			this,
			Settings.Tornado.Attack.TimeSpentAttacking_MIN
		);

		BehaviourComp.NotifyStateChanged();
		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);

		InitMovement();
	}

	void InitMovement() 
	{
		VictimLocation = VictimComp.GetVictimCenterTransform().GetLocation();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsLocation(VictimLocation);

		// Calculate offsets based on player location due to player being on a vehicle
		StartOffsetFromVictim = MoveComp.DesiredSwarmActorTransform.GetLocation() - VictimLocation;
		FVector EndLocation = MoveComp.GetSplineToFollow().FindLocationClosestToWorldLocation(
			VictimLocation + (SwarmToVictimQuat.Vector() * StartOffsetFromVictim.Size()),
			ESplineCoordinateSpace::World
		);
		EndOffsetFromVictim = EndLocation - VictimLocation;
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		// We keep the transform relative to the spline because player is "riding" the spline. 
		if (BehaviourComp.GetStateDuration() < Settings.Tornado.Attack.KeepTrackOfVictimDuration)
		{
			const FVector VictimLoc = VictimComp.GetVictimCenterTransform().GetLocation();
			const FVector SplineLoc = MoveComp.GetSplineToFollowTransform().GetLocation();
			VictimOffsetFromSpline = VictimLoc - SplineLoc;
		}
		VictimLocation = MoveComp.GetSplineToFollowLocation() + VictimOffsetFromSpline;
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsLocation(VictimLocation);

		const float Duration = Settings.Tornado.Attack.TimeSpentAttacking_MAX;
		LerpAlpha = FMath::Clamp(BehaviourComp.GetStateDuration() / Duration, 0.f, 1.f);

		UpdateCatmullRomAttack(DeltaSeconds);

		if(LerpAlpha == 1.f)
			OnAttackCompleted();

		BehaviourComp.FinalizeBehaviour();
 	}

	void UpdateCatmullRomAttack(const float Dt)
	{
		const FVector VictimLookingDir = VictimComp.GetVictimLookingDirection();

		FVector StartLocation = VictimLocation + StartOffsetFromVictim;
		FVector EndLocation = VictimLocation + EndOffsetFromVictim;
		EndLocation += FVector(0.f, 0.f, 1000.f);

		FVector HandleStart = StartLocation - (VictimLookingDir * StartOffsetFromVictim.Size());
		FVector HandleEnd = EndLocation + (VictimLookingDir * EndOffsetFromVictim.Size());

		TArray<FVector> SplinePoints;
		SplinePoints.Add(StartLocation);
		SplinePoints.Add(VictimLocation);
		SplinePoints.Add(EndLocation);

		const FVector TargetLocation = Math::GetLocationOnCRSpline(
			HandleStart,
			SplinePoints,
			HandleEnd,
			LerpAlpha, 
			Damping = 0.2f
		);

// 		System::DrawDebugPoint(
// 			TargetLocation,
// 			10.f,
// 			FLinearColor::Yellow,
// 			1.5f
// 		);

		MoveComp.DesiredSwarmActorTransform.SetLocation(TargetLocation);
// 		MoveComp.SpringToTarget(TargetLocation, 30.f, 0.4f, Dt);
		MoveComp.InterpolateToTargetRotation(SwarmToVictimQuat, 1.5f, true, Dt);
	}

	void OnAttackCompleted() 
	{
		++NumAttacksPerformedTotal;

		if (NumAttacksPerformedTotal >= Settings.Tornado.Attack.NumTotalAttacks)
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



























import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunAirplaneAttackUltimateCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::AttackUltimate;

	FVector StartOffsetFromPlayer = FVector::ZeroVector;
	FRotator PlayerLookingRotator = FRotator::ZeroRotator;
	FVector PlayerLocation = FVector::ZeroVector;

	float PlayerDistanceAlongSpline = 0.f;

	float LerpAlpha = 0.f;
	float LerpSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if (VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(BehaviourComp.IsUltimateOnCooldown(Settings.HitAndRun.AttackUltimate.Cooldown))
			return EHazeNetworkActivation::DontActivate;

//		if(!MoveComp.HasSecondarySplineToFollow())
//			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (BehaviourComp.HasExplodedSinceStateChanged_PostTimeWindow(Settings.HitAndRun.AttackUltimate.TimeSpentAttacking_MIN))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.IsUltimateOnCooldown(Settings.HitAndRun.AttackUltimate.Cooldown))
			return EHazeNetworkDeactivation::DeactivateLocal;

//		if(!MoveComp.HasSecondarySplineToFollow())
//			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.HitAndRun.AttackUltimate.AnimSettingsDataAsset,
			this,
			Settings.HitAndRun.AttackUltimate.TimeSpentAttacking_MIN
		);

		LerpAlpha = 0.f;
		LerpSpeed = 0.f;

		BehaviourComp.NotifyStateChanged();
		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);

		PlayerLocation = VictimComp.GetVictimCenterTransform().GetLocation();
		PlayerLookingRotator = VictimComp.GetVictimLookingRotatorYAWOnly();

 		StartOffsetFromPlayer = MoveComp.DesiredSwarmActorTransform.GetLocation() - PlayerLocation;

// 		auto SecondarySpline = MoveComp.GetSecondarySplineToFollow();
// 		FVector Dummy;
// 		SecondarySpline.FindDistanceAlongSplineAtWorldLocation(
// 			PlayerLocation,
// 			Dummy,
// 			PlayerDistanceAlongSpline
// 		);

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		LerpAlpha += LerpSpeed * DeltaSeconds;
		LerpAlpha = FMath::Fmod(LerpAlpha, 1.f);

// 		float Duration = Settings.HitAndRun.AttackUltimate.TimeSpentAttacking_MAX;
// 		LerpAlpha = FMath::Fmod(BehaviourComp.GetStateDuration(), Duration) / Duration;
// 		LerpAlpha = (FMath::Sin(BehaviourComp.GetStateDuration() * PI / Duration) + 1) * 0.5f;

		PlayerLocation = VictimComp.GetVictimCenterTransform().GetLocation();
		PlayerLookingRotator = VictimComp.GetVictimLookingRotatorYAWOnly();

		HitAndRunAttack(DeltaSeconds);
// 		AirstripRoundaboutAttack(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void HitAndRunAttack(const float DeltaSeconds) 
	{
		// This will always be relative to player location
		FVector P1_SwarmStartPos = PlayerLocation + StartOffsetFromPlayer;

		const FVector FromStartToPlayerNormalized = (PlayerLocation - P1_SwarmStartPos).GetSafeNormal();

		// Half way between player and start location. 
		// We can use this to bend the curve at a location and control speed.
		FVector P2_HalfWay = P1_SwarmStartPos + (PlayerLocation - P1_SwarmStartPos) * 0.5f;
		P2_HalfWay += FVector(0.f, 0.f, -500.f);

		// This is the player location but with an additional Z offset.
		FVector P3_PlayerPosWithZOffset = PlayerLocation + FVector(0.f, 0.f, 100.f);

		// Behind the player, relative to camera. 
		FVector P4_BehindPlayer = PlayerLocation;
		P4_BehindPlayer += FromStartToPlayerNormalized * 5000.f;
		P4_BehindPlayer += PlayerLookingRotator.RotateVector(FVector(0.f, 0.f, 4000.f));

		FVector P5_CloserToTheSpline = P4_BehindPlayer;
		P5_CloserToTheSpline += PlayerLookingRotator.RotateVector(FVector(500.f, 0.f, 2000.f));

		const float BaseSpeed = 0.1f;

		TArray<FSwarmCRSplinePoint> SplinePoints;
		SplinePoints.Add(FSwarmCRSplinePoint(P1_SwarmStartPos, BaseSpeed * 1.0f));
 		SplinePoints.Add(FSwarmCRSplinePoint(P2_HalfWay, BaseSpeed * 1.0f));
		SplinePoints.Add(FSwarmCRSplinePoint(P3_PlayerPosWithZOffset, BaseSpeed * 1.0f));
		SplinePoints.Add(FSwarmCRSplinePoint(P4_BehindPlayer, BaseSpeed  * 1.0f));
		SplinePoints.Add(FSwarmCRSplinePoint(P5_CloserToTheSpline, BaseSpeed  * 1.0f));
		SplinePoints.Add(FSwarmCRSplinePoint(P1_SwarmStartPos, BaseSpeed * 0.05f));

		// This will make the spline loop
		FVector HandleStart = P4_BehindPlayer;
		FVector HandleEnd = P1_SwarmStartPos;

		FSwarmCRSplinePoint TargetSplinePoint = MoveComp.GetLocationOnCRSplineWithCustomSpeed(
			HandleStart,
			SplinePoints,
			HandleEnd,
			LerpAlpha,
			Damping = 0.f		 // Ranges between 0 to 1. 
		);

		// Update Speed and Location
		FVector TargetLocation = TargetSplinePoint.Location;
		LerpSpeed = TargetSplinePoint.Speed;

		MoveComp.DesiredSwarmActorTransform = FTransform(
			MoveComp.GetFacingRotationTowardsLocation(TargetLocation),
			TargetLocation
		);

		TArray<FVector> Points;
		for (const FSwarmCRSplinePoint& CRSplinePoint : SplinePoints)
			Points.Add(CRSplinePoint.Location);

		if (MoveComp.HasPassedCRSplinePoint(P5_CloserToTheSpline, Points, LerpAlpha))
		{
			SwarmActor.PropagateAttackUltimatePerformed();
			PrioritizeState(ESwarmBehaviourState::CirclePlayer);
		}

// 		System::DrawDebugPoint(TargetLocation, 5.f, FLinearColor::Green, Duration = 1.f);
	}

	void AirstripRoundaboutAttack(const float DeltaSeconds) 
	{
		FVector OffsetAirstripStart = FVector(10000.f, 0.f, 1000.f);
		FVector OffsetAirstripEnd = FVector(-3000.f, 0.f, 2500.f);

		FVector SwarmStartLocation = PlayerLocation;
		SwarmStartLocation += StartOffsetFromPlayer;

		//auto SecondarySpline = MoveComp.GetSecondarySpline();
		auto SecondarySpline = MoveComp.GetSplineToFollow();
		FVector AirStripStart = SecondarySpline.GetLocationAtDistanceAlongSpline(
			PlayerDistanceAlongSpline + 5000.f,
			ESplineCoordinateSpace::World
			);

		FVector AirStripEnd  = PlayerLocation;
		AirStripEnd += PlayerLookingRotator.RotateVector(OffsetAirstripEnd);
		AirStripEnd.Z += PlayerLocation.Z;

		TArray<FSwarmCRSplinePoint> SplinePoints;

		const float BaseSpeed = 0.05f;

		FVector HandleStart = AirStripEnd;
		SplinePoints.Add(FSwarmCRSplinePoint(SwarmStartLocation, BaseSpeed));
		SplinePoints.Add(FSwarmCRSplinePoint(AirStripStart, BaseSpeed * 0.5f));

		FVector Mid = AirStripStart + (PlayerLocation - AirStripStart)* 0.5f;
		Mid += FVector(0.f, 0.f, 500.f);

	// 		SplinePoints.Add(FSwarmCRSplinePoint(Mid, BaseSpeed*0.5f));
		const FVector PlayerLocationWithOffset = PlayerLocation + FVector(0.f, 0.f, 100.f);
		SplinePoints.Add(FSwarmCRSplinePoint(PlayerLocationWithOffset, BaseSpeed * 1.f));
		SplinePoints.Add(FSwarmCRSplinePoint(AirStripEnd, BaseSpeed * 2.f));
		SplinePoints.Add(FSwarmCRSplinePoint(SwarmStartLocation, BaseSpeed));
		FVector HandleEnd = AirStripStart;

	//		FVector TargetLocation = Math::GetLocationOnCRSpline(
		FSwarmCRSplinePoint TargetSplinePoint = MoveComp.GetLocationOnCRSplineWithCustomSpeed(
			HandleStart,
			SplinePoints,
			HandleEnd,
			LerpAlpha,
			Damping = 0.f		 // Ranges between 0 to 1. 
		);

		FVector TargetLocation = TargetSplinePoint.Location;
		LerpSpeed = TargetSplinePoint.Speed;

		MoveComp.DesiredSwarmActorTransform = FTransform(
			MoveComp.GetFacingRotationTowardsLocation(TargetLocation),
			TargetLocation
		);

		TArray<FVector> Points;
		for (const FSwarmCRSplinePoint& CRSplinePoint : SplinePoints)
			Points.Add(CRSplinePoint.Location);

		if (MoveComp.HasPassedCRSplinePoint(AirStripEnd, Points, LerpAlpha))
		{
			SwarmActor.PropagateAttackUltimatePerformed();
			PrioritizeState(ESwarmBehaviourState::CirclePlayer);
		}

		System::DrawDebugPoint(TargetLocation, 5.f, FLinearColor::Green, Duration = 1.f);
	}

}





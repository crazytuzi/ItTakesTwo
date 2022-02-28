
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunTelegraphBetweenAttacksCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphBetween;

	FQuat StartQuat = FQuat::Identity;
	FQuat SwarmToVictimQuat = FQuat::Identity;
	FVector StartOffsetFromVictim = FVector::ZeroVector;
	FVector VictimLocation = FVector::ZeroVector;

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

//		if(!HasEnoughParticlesForAnimation(Settings.HitAndRun.TelegraphBetween.AnimSettingsDataAsset))
//			return EHazeNetworkActivation::DontActivate;

		if(Settings.HitAndRun.TelegraphBetween.TelegraphingTime <= 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

 		if(MoveComp.GetSplineToFollow() == nullptr)
 			return EHazeNetworkDeactivation::DeactivateLocal;

//		if(!HasEnoughParticlesForAnimation(Settings.HitAndRun.TelegraphBetween.AnimSettingsDataAsset))
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
			Settings.HitAndRun.TelegraphBetween.AnimSettingsDataAsset,
			this,
			Settings.HitAndRun.TelegraphBetween.TelegraphingTime
		);

		BehaviourComp.NotifyStateChanged();

		AHazePlayerCharacter ClosestPlayerOverride = VictimComp.PlayerVictim;
		if (Settings.HitAndRun.TelegraphBetween.bSwitchPlayerVictimBetweenAttacks)
		{
			auto May = Game::GetMay();
			auto Cody = Game::GetCody();
			ClosestPlayerOverride = VictimComp.PlayerVictim == May ? Cody : May;

			UHazeBaseMovementComponent VictimMoveComp = UHazeBaseMovementComponent::Get(ClosestPlayerOverride);
			if(VictimMoveComp.IsGrounded() == false)
			{
				ClosestPlayerOverride = ClosestPlayerOverride.GetOtherPlayer();
				VictimMoveComp = UHazeBaseMovementComponent::Get(ClosestPlayerOverride);
				if(VictimMoveComp.IsGrounded() == false)
				{
					ClosestPlayerOverride = nullptr;
				}
			}

		}

		VictimComp.OverrideClosestPlayer(ClosestPlayerOverride, this);

		InitMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		if (BehaviourComp.GetStateDuration() > Settings.HitAndRun.TelegraphBetween.TelegraphingTime)
			PrioritizeState(ESwarmBehaviourState::Attack);

		UpdateMovement(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void InitMovement() 
	{
		StartQuat = MoveComp.DesiredSwarmActorTransform.GetRotation();
 		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsActor(VictimComp.PlayerVictim);
		VictimLocation = VictimComp.GetLastValidGroundLocation();

		FVector PredictedSwarmLocation = MoveComp.DesiredSwarmActorTransform.GetLocation();
		PredictedSwarmLocation += (MoveComp.TranslationVelocity * (1.f / 30.f));

		const UHazeSplineComponent Spline = MoveComp.GetSplineToFollow();
		FTransform DesiredTransform = Spline.GetTransformAtDistanceAlongSpline(
			Spline.GetDistanceAlongSplineAtWorldLocation(PredictedSwarmLocation),
			ESplineCoordinateSpace::World,
			bUseScale = false
		);

		// Look towards the player
		DesiredTransform.SetRotation(SwarmToVictimQuat);

		// apply offset (which is constrained to the XY plane)
		FQuat SwingDummy, Twist;
		SwarmToVictimQuat.ToSwingTwist(FVector::UpVector, SwingDummy, Twist);
		FVector DesiredTelegraphOffset = Twist.RotateVector(Settings.HitAndRun.TelegraphBetween.TelegraphingOffset);
		DesiredTransform.AddToTranslation(DesiredTelegraphOffset);

		// Save the location as an offset, because we want 
		// to stay relative to the victim while the victim is moving
		StartOffsetFromVictim = DesiredTransform.GetLocation() - VictimLocation;
	}

	void UpdateMovement(const float DeltaSeconds) 
	{
		VictimLocation = VictimComp.GetVictimCenterTransform().GetLocation();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsLocation(VictimLocation);

		float LerpAlpha = 1.f;
		const float TimeToTelegraph = Settings.HitAndRun.TelegraphBetween.TelegraphingTime;
		if (TimeToTelegraph > 0)
			LerpAlpha = FMath::Clamp(BehaviourComp.GetStateDuration() / TimeToTelegraph, 0.f, 1.f);

 		MoveComp.SlerpToTargetRotation(StartQuat, SwarmToVictimQuat, LerpAlpha);
		const FVector DesiredTargetLocation = VictimLocation + StartOffsetFromVictim;

		TArray<FHitResult> Hits;
		const FVector DeltaTrace = FVector::UpVector * 5000.f;
		MoveComp.RayTraceMulti(
			DesiredTargetLocation + (FVector::UpVector * 1000),
			DesiredTargetLocation - (FVector::UpVector * 5000),
			Hits,
			ETraceTypeQuery::WaterTrace
		);

		if(Hits.Num() != 0)
		{
			FVector TraceTargetLocation = Hits.Last().ImpactPoint;
			// MoveComp.SpringToTargetLocation(TraceTargetLocation, 15.f, 0.6f, DeltaSeconds);

			// Assuming Swarm width radius, 
			// because it is clipping the water.
			// TraceTargetLocation += FVector::UpVector * 1000.f;

			MoveComp.SpringToTargetWithTime(
				TraceTargetLocation,
				Settings.HitAndRun.TelegraphBetween.TelegraphingTime,
				DeltaSeconds
			);
			// System::DrawDebugPoint(TraceTargetLocation, 4.f, FLinearColor::Yellow, 1.5f); 
			// Print("" + Hits.Last().GetActor());
		}
		else
		{
 			MoveComp.LerpToTargetLocation(DesiredTargetLocation, LerpAlpha);
		}

//  		System::DrawDebugPoint(
//  			DesiredTransform.GetLocation(),
// 			100.f, 
// 			Duration = 10.f
//  		);
	}

}












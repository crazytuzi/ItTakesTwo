
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHammerPursueMiddleCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::PursueMiddle;

	/* Arena middle transform + Desired offset */ 
	FTransform DesiredTransform = FTransform::Identity;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.PursueMiddle.AnimSettingsDataAsset,
			this
		);

		BehaviourComp.NotifyStateChanged();

		CalculateAndUpdateDesiredTransform();
 	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (BehaviourComp.GetStateDuration() > Settings.Hammer.PursueMiddle.TimeToReachMiddle)
		{
			PrioritizeState(ESwarmBehaviourState::Gentleman);
		}
		else if (VictimComp.PlayerVictim != nullptr && VictimComp.HasVictimBeenClaimedByAnyone())
		{
			PrioritizeState(ESwarmBehaviourState::PursueSpline);
		}

// 		if(IsCloseEnoughToMiddle())
// 			PrioritizeState(ESwarmBehaviourState::TelegraphInitial);

		CalculateAndUpdateDesiredTransform();

		AccelerateToMiddle(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void CalculateAndUpdateDesiredTransform()
	{
		DesiredTransform = MoveComp.ArenaMiddleActor.GetActorTransform();

		// Add the desired offset relative to the ArenaMiddleActors YAW rotation.
		FQuat Swing, Twist;
		DesiredTransform.GetRotation().ToSwingTwist(FVector::UpVector, Swing, Twist);
		FVector RotatedOffset = Twist.RotateVector(Settings.Hammer.PursueMiddle.OffsetFromMiddle);
		DesiredTransform.AddToTranslation(RotatedOffset);

// 		System::DrawDebugPoint(DesiredTransform.GetLocation(), 10.f, PointColor = FLinearColor::Blue);
	}

	void AccelerateToMiddle(const float Dt)
	{
		MoveComp.SpringToTargetWithTime(
			DesiredTransform.GetLocation(),
			Settings.Hammer.PursueMiddle.TimeToReachMiddle,
			Dt
		);

// 		MoveComp.SpringToTarget(
// 			DesiredTransform.GetLocation(),
// 			5.f,
// 			1.0f,
// 			Dt
// 		);

		// System::DrawDebugPoint(
		// 	DesiredTransform.GetLocation(),
		// 	10.f,
		// 	PointColor = FLinearColor::Blue,
		// 	Duration = 0.f
		// );

	}

//	bool IsCloseEnoughToMiddle() const
//	{
//		const FVector Middle = MoveComp.ArenaMiddleActor.GetActorLocation();
//
//		FVector Center, Extent;
//		SwarmActor.SkelMeshComp.GetSwarmCenterAndExtents(Center, Extent);
//
//		// support for multiple meshes.. temp?
//		Center = SwarmActor.GetSwarmCenterLocation();
//
//		const float DistBetween = (Middle - Center).Size();
//		const float Threshold = Extent.Size() + Settings.Hammer.PursueMiddle.CloseEnoughRadius;
//
//		return DistBetween <= Threshold;
//	}

}
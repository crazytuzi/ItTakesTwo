import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmSlideIdleCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Idle;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.HasSplineToFollow())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Slide.Idle.AnimSettingsDataAsset,
			this
		);

		BehaviourComp.NotifyStateChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		if (MoveComp.HasSplineToFollow())
			PrioritizeState(ESwarmBehaviourState::PursueSpline);

		FQuat Rot = MoveComp.GetFacingRotationTowardsActor(VictimComp.PlayerVictim);

		FQuat Swing;	
		FQuat Twist;	
		Rot.ToSwingTwist(FVector::UpVector, Swing, Twist); 

//  		MoveComp.SwarmTransform.SetRotation(Twist);
		MoveComp.DesiredSwarmActorTransform.SetRotation(Rot);

		BehaviourComp.FinalizeBehaviour();
 	}
}

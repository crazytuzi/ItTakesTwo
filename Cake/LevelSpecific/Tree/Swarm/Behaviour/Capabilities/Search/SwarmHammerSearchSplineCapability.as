 
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
 
 class USwarmHammerSearchSplineCapability : USwarmBehaviourCapability
 {
	default AssignedState = ESwarmBehaviourState::Search;
 
 	UFUNCTION(BlueprintOverride)
 	EHazeNetworkActivation ShouldActivate() const
 	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

 		if (!MoveComp.HasSplineToFollow())
 			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
 	}
 
 	UFUNCTION(BlueprintOverride)
 	EHazeNetworkDeactivation ShouldDeactivate() const
 	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

 		if (!MoveComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateLocal;

 		return EHazeNetworkDeactivation::DontDeactivate;
 	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.Search.AnimSettingsDataAsset,
			this
			,2.f // procedural animation need more time
		);

		BehaviourComp.NotifyStateChanged();
		MoveComp.InitMoveAlongSpline();
 	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		// only use the scaled version after a certain time to ensure 
		// that swarm doesn't charge to the ground after doing the "recover"
		MoveComp.MoveAlongSplineScaled(Settings.Hammer.Search.InterpStepSize, DeltaSeconds);

		// Request transition to Pursue if we've found a player 
		if (SwarmActor.VictimComp.PlayerVictim != nullptr)
			PrioritizeState(ESwarmBehaviourState::PursueSpline);

		BehaviourComp.FinalizeBehaviour();
	}

 }








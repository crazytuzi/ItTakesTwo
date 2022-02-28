 
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
 
 class USwarmHitAndRunPursuePlayerCapability : USwarmBehaviourCapability
 {
	default AssignedState = ESwarmBehaviourState::PursuePlayer;
 
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

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

 		return EHazeNetworkDeactivation::DontDeactivate;
 	}

 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.HitAndRun.PursuePlayer.AnimSettingsDataAsset,
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
		MoveComp.SteerToTarget(
			VictimComp.GetLastValidGroundLocation(),
			DeltaSeconds,
			Settings.HitAndRun.PursuePlayer.MaxSpeed,
			Settings.HitAndRun.PursuePlayer.MaxAcceleration
		);

//		MoveComp.SpringToTargetLocation(VictimComp.GetLastValidGroundLocation(), 10.f, 1.0f,  DeltaSeconds);
//		MoveComp.SpringToTargetWithTime(VictimComp.GetLastValidGroundLocation(), 2.f, DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();

		// Request transition to Circle player if we're close enough 
		float DistThresholdSQ = Settings.HitAndRun.PursuePlayer.CloseEnoughToPlayerRadius;
		if (VictimComp.DistanceToVictimSQ() < FMath::Square(DistThresholdSQ))
		{
			PrioritizeState(ESwarmBehaviourState::CirclePlayer);
		}

		// System::DrawDebugSphere(
		// 	VictimComp.GetLastValidGroundLocation(),
		// 	Settings.HitAndRun.PursuePlayer.CloseEnoughToPlayerRadius
		// );

	}

 }








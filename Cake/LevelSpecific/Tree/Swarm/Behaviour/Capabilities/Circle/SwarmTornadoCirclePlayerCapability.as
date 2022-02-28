

import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmTornadoCirclePlayerCapability: USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::CirclePlayer;

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
			Settings.Tornado.CirclePlayer.AnimSettingsDataAsset,
			this,
			Settings.Tornado.CirclePlayer.TimeSpentCircling_MIN
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
		// Pursue along spline 
		MoveComp.MoveAlongSpline(Settings.Tornado.CirclePlayer.InterpStepSize, DeltaSeconds);

		// Proceed to next state once we've circled long enough
		const float MaxTime = Settings.Tornado.CirclePlayer.TimeSpentCircling_MAX;
		if (BehaviourComp.GetStateDuration() > MaxTime)
			RequestNextState();
		
		// Or if player has started shooting the swarm. 
		const float MinTime = Settings.Tornado.CirclePlayer.TimeSpentCircling_MIN;
		if (BehaviourComp.HasExplodedSinceStateChanged_PostTimeWindow(MinTime))
			RequestNextState();

		BehaviourComp.FinalizeBehaviour();
	}

	void RequestNextState() 
	{
		// TEMP Until we figure out how to manage ATTACK and ULTIMATES in same sheet
// 		if (BehaviourComp.IsUltimateOnCooldown(Settings.Tornado.AttackUltimate.Cooldown))
			PrioritizeState(ESwarmBehaviourState::TelegraphInitial);
// 		else 
// 			PrioritizeState(ESwarmBehaviourState::AttackUltimate);
	}
}

































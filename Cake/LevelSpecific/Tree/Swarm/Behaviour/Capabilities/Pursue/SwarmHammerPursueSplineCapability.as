
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHammerPursueSplineCapability: USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::PursueSpline;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
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

 		if (!SwarmActor.MovementComp.HasSplineToFollow())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
 
 	UFUNCTION(BlueprintOverride)
 	void OnActivated(FCapabilityActivationParams ActivationParams)
 	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.PursueSpline.AnimSettingsDataAsset,
			this
			,0.f
		);

		TimeSpentInPursuitThreshold = FMath::LerpStable(
			Settings.Hammer.PursueSpline.TimeSpentInPursuit,
			Settings.Hammer.PursueSpline.TimeSpentInPursuit * FMath::RandRange(0.f, 1.f),
			Settings.Hammer.PursueSpline.TimeRandomizedFraction
		);


		BehaviourComp.NotifyStateChanged();
		MoveComp.InitMoveAlongSpline();
 	}

	float TimeSpentInPursuitThreshold = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// until its HammerTime!  
		const float StateDuration = BehaviourComp.GetStateDuration();
		if (StateDuration > Settings.Hammer.PursueSpline.TimeSpentInPursuit)
		{
			if(VictimComp.HasVictimBeenClaimedByAnyone() == false)
			{
				PrioritizeState(ESwarmBehaviourState::PursueMiddle);
			}
			else if(VictimComp.GetOtherVictim() != nullptr && !VictimComp.HasOtherVictimBeenClaimedByAnyone())
			{
				if (!VictimComp.IsUsingSharedGentlemanBehaviour())
					VictimComp.ResetGentlemanForPlayer(VictimComp.CurrentVictim);

				VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim.OtherPlayer, this);
			}
		}

		// Pursue along spline 
		MoveComp.MoveAlongSplineScaled(Settings.Hammer.PursueSpline.InterpStepSize, DeltaSeconds);

//		PrintToScreen("TimeSpentPursing: " + BehaviourComp.GetStateDuration());
//		PrintToScreen("TimeSpentPursing Threshold: " + TimeSpentInPursuitThreshold);

		BehaviourComp.FinalizeBehaviour();
	}



}

































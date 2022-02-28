
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Swarm.Encounters.Hammer.SwarmHammerManager;

class USwarmHammerRecoverCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Recover;

	/* Arena middle transform + Desired offset */ 
	FTransform DesiredTransform = FTransform::Identity;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(MoveComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MoveComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	ASwarmHammerManager Manager = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Manager = Cast<ASwarmHammerManager>(MoveComp.ArenaMiddleActor);

		// Player took way to long to kill the first swarm. 
		// this swarm goes high into the air when that happens and
		// tells the manager to release more swarms
		if (Manager != nullptr && HasControl())
			Manager.NetCallForSwarmBackup();

		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.Recover.AnimSettingsDataAsset,
			this,
			Settings.Hammer.Recover.BlendInTime
		);

		BehaviourComp.NotifyStateChanged();

		DesiredTransform = MoveComp.ArenaMiddleActor.GetActorTransform();

		// We want to apply the delta translation away from the victim.
		// but if we don't have a Victim anymore we'll just offset it
		// in the swarms current direction.
		FQuat DeltaTranslationDirectionQuat = FQuat::Identity;
		if (SwarmActor.VictimComp.PlayerVictim != nullptr)
			DeltaTranslationDirectionQuat = GetQuatAwayFromVictim();
		else
			DeltaTranslationDirectionQuat = DesiredTransform.GetRotation();

		FQuat Swing, Twist;
		DesiredTransform.GetRotation().ToSwingTwist(FVector::UpVector, Swing, Twist);
		FVector RotatedOffset = Twist.RotateVector(Settings.Hammer.Recover.RestingOffset);
		DesiredTransform.AddToTranslation(RotatedOffset);

		// look towards the middle from the new offseted location
		FVector ToMiddle = Twist.RotateVector(-Settings.Hammer.Recover.RestingOffset);
		FQuat TowardsMiddleQuat = FQuat(ToMiddle.ToOrientationRotator());
		DesiredTransform.SetRotation(TowardsMiddleQuat);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		// Request Idle if we've recovered enough
		const float TimeSpentInState = SwarmActor.BehaviourComp.GetStateDuration();
		if (TimeSpentInState > Settings.Hammer.Recover.TimeSpentRecovering)
		{
			PrioritizeState(ESwarmBehaviourState::Idle);

			// @TODO remove this when if you are testing the hammer
			// if(VictimComp.CurrentVictim != nullptr)
			// 	VictimComp.ClearPlayerVictim();
		}

		// rotate towards victim (if we have a victim) while swarm recovers
		if (SwarmActor.VictimComp.PlayerVictim != nullptr)
			DesiredTransform.SetRotation(GetQuatTowardsVictim());

		// interpolate towards desired recover transform 
		SwarmActor.MovementComp.DesiredSwarmActorTransform = Math::InterpolateLocationAndRotationTo(
			SwarmActor.GetActorTransform(),
			DesiredTransform,
			DeltaSeconds,
 			Settings.Hammer.Recover.InterpolationSpeed_Swarm,
 			Settings.Hammer.Recover.bInterpolateSwarmWithConstantSpeed
		);

		BehaviourComp.FinalizeBehaviour();
 	}

	FQuat GetQuatTowardsVictim() const 
	{
		return SwarmActor.MovementComp.GetFacingRotationTowardsActor(
			SwarmActor.VictimComp.PlayerVictim
		);
	}

	FQuat GetQuatAwayFromVictim() const
	{
		const FVector SwarmLocation = Owner.GetActorLocation();
		const FVector VictimLocation = SwarmActor.VictimComp.PlayerVictim.GetActorLocation();
		const FVector AwayFromVictim = SwarmLocation - VictimLocation;
  		const FQuat NewQuat = Math::MakeQuatFromX(AwayFromVictim);
		return NewQuat;
	}

}

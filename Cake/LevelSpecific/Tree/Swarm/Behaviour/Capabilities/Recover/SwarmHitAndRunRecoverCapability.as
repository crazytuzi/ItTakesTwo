
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHitAndRunRecoverCapability : USwarmBehaviourCapability
{

 	default AssignedState = ESwarmBehaviourState::Recover;
// 
// 	/* Arena middle transform + Desired offset */ 
// 	FTransform DesiredTransform = FTransform::Identity;
// 
// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (BehaviourComp.HasBehaviourBeenFinalized())
// 			return EHazeNetworkActivation::DontActivate;
// 
// 		if(MoveComp.ArenaMiddleActor == nullptr)
// 			return EHazeNetworkActivation::DontActivate;
// 
// 		return EHazeNetworkActivation::ActivateLocal;
// 	}
// 
// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if (BehaviourComp.HasBehaviourBeenFinalized())
// 			return EHazeNetworkDeactivation::DeactivateLocal;
// 
// 		if(MoveComp.ArenaMiddleActor == nullptr)
// 			return EHazeNetworkDeactivation::DeactivateLocal;
// 
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}
// 
// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		SkelMeshComp.PushSwarmAnimSettings(
// 			Settings.HitAndRun.Recover.AnimSettingsDataAsset,
// 			this
// 		);
// 
// 		BehaviourComp.NotifyStateChanged();
// 
// 		DesiredTransform = MoveComp.ArenaMiddleActor.GetActorTransform();
// 
// 		// We want to apply the delta translation away from the victim.
// 		// but if we don't have a Victim anymore we'll just offset it
// 		// in the swarms current direction.
// 		FQuat DeltaTranslationDirectionQuat = FQuat::Identity;
// 		if (SwarmActor.VictimComp.PlayerVictim != nullptr)
// 			DeltaTranslationDirectionQuat = GetQuatAwayFromVictim();
// 		else
// 			DeltaTranslationDirectionQuat = DesiredTransform.GetRotation();
// 
// 		FQuat Swing, Twist;
// 		DesiredTransform.GetRotation().ToSwingTwist(FVector::UpVector, Swing, Twist);
// 		FVector RotatedOffset = Twist.RotateVector(Settings.HitAndRun.Recover.RestingOffset);
// 		DesiredTransform.AddToTranslation(RotatedOffset);
// 
// 		// look towards the middle from the new offseted location
// 		FVector ToMiddle = Twist.RotateVector(-Settings.HitAndRun.Recover.RestingOffset);
// 		FQuat TowardsMiddleQuat = FQuat(ToMiddle.ToOrientationRotator());
// 		DesiredTransform.SetRotation(TowardsMiddleQuat);
// 	}
// 
// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{
// 		SkelMeshComp.RemoveSwarmAnimSettings(this);
// 	}
// 
//  	UFUNCTION(BlueprintOverride)
//  	void TickActive(float DeltaSeconds)
//  	{
// 		// Request Idle if we've recovered enough
// 		const float TimeSpentInState = SwarmActor.BehaviourComp.GetStateDuration();
// 		if (TimeSpentInState > Settings.HitAndRun.Recover.TimeSpentRecovering)
// 		{
// 			PrioritizeState(ESwarmBehaviourState::Idle);
// 			VictimComp.PlayerVictim = nullptr;
// 		}
// 
// 		// rotate towards victim (if we have a victim) while swarm recovers
// 		if (SwarmActor.VictimComp.PlayerVictim != nullptr)
// 			DesiredTransform.SetRotation(GetQuatTowardsVictim());
// 
// 		// interpolate towards desired recover transform 
// 		SwarmActor.MovementComp.SwarmTransform = Math::InterpolateLocationAndRotationTo(
// 			SwarmActor.GetActorTransform(),
// 			DesiredTransform,
// 			DeltaSeconds,
//  			Settings.HitAndRun.Recover.InterpolationSpeed_Swarm,
//  			Settings.HitAndRun.Recover.bInterpolateSwarmWithConstantSpeed
// 		);
// 
// 		BehaviourComp.FinalizeBehaviour();
//  	}
// 
// 	FQuat GetQuatTowardsVictim() const 
// 	{
// 		return SwarmActor.MovementComp.GetFacingRotationTowardsActor(
// 			SwarmActor.VictimComp.PlayerVictim
// 		);
// 	}
// 
// 	FQuat GetQuatAwayFromVictim() const
// 	{
// 		const FVector SwarmLocation = Owner.GetActorLocation();
// 		const FVector VictimLocation = SwarmActor.VictimComp.PlayerVictim.GetActorLocation();
// 		const FVector AwayFromVictim = SwarmLocation - VictimLocation;
//   		const FQuat NewQuat = Math::MakeQuatFromX(AwayFromVictim);
// 		return NewQuat;
// 	}
// 
}



import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackPerformed;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackStarted;

class USwarmSwordAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Attack;

	FQuat SwarmToVictimQuat = FQuat::Identity;
	FTransform VictimTransform = FTransform::Identity;

	FHazeAnimNotifyDelegate OnNotifyExecuted_AttackPerformed;
	FHazeAnimNotifyDelegate OnNotifyExecuted_AttackStarted;

	int32 NumAttacksPerformedConsecutively = 0;
	int32 NumAttacksPerformedTotal = 0;
	float AttackStartedTimeStamp = 0.f;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.Sword.Attack.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	bool ShouldPlayRightSwordSlash() const
	{
		FVector VictimToQueen = MoveComp.ArenaMiddleActor.GetActorLocation();
		VictimToQueen -= VictimComp.CurrentVictim.GetActorLocation();
		return VictimToQueen.DotProduct(FVector::RightVector) < 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// (because we don't remove it OnDeactivated anymore)
		SwarmActor.StopSwarmAnimationByInstigator(this);

		if(ShouldPlayRightSwordSlash())
			SwarmActor.PlaySwarmAnimation(Settings.Sword.Attack.AnimSettingsDataAsset, this);
		else
			SwarmActor.PlaySwarmAnimation(Settings.Sword.Attack.AnimSettingsDataAsset_LeftSlash, this);

		BehaviourComp.NotifyStateChanged();

		VictimTransform = VictimComp.PlayerVictim.GetActorTransform();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);

		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);

		BindAttackNotifyDelegate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnbindAttackNotifyDelegate();

		if (DeactivationParams.IsStale())
		{
			NumAttacksPerformedConsecutively = 0;
			NumAttacksPerformedTotal = 0;
		}

		// removing this animation causes a snap when switching to hands in queen p3.
		// I believe it is because the AnimNotifySettings modifiers gets purged 
		// and the animation gets stuck in limbo in a few seconds 
		// before transitioning to hand animations.
		// (we remove the animation stacks by this capability OnActivated instead)
//		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

	const FVector OffsetFromFloor = FVector::UpVector * 100.f;

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		// Only keep track of the victims transform for a certain amount of time.  
		// ~2.9 is a good value. We don't want the swarm following the player after the slash
		const float TimeSinceAttackStarted = Time::GetGameTimeSince(AttackStartedTimeStamp);
		if (TimeSinceAttackStarted < Settings.Sword.Attack.KeepTrackOfVictimDuration)
		{
			VictimTransform = VictimComp.PlayerVictim.GetActorTransform();
			VictimTransform.SetLocation(VictimComp.GetLastValidGroundLocation());
			VictimTransform.AddToTranslation(OffsetFromFloor);
			SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);
		}

		// Swarm To Victim Quat projected on plane that the player is standing on.
		FQuat DummySwing, SwarmToVictimQuat_Twist;
		SwarmToVictimQuat.ToSwingTwist(
//			VictimComp.GetVictimGroundNormal(),
			FVector::UpVector,
			DummySwing,
			SwarmToVictimQuat_Twist
		);

		// the offset will be relative to vector between SwarmAndVictim because 
		// that will ensure that the swarm starts the attack where he is currently at
 		const FVector AlignOffset = SwarmToVictimQuat_Twist.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			VictimTransform.GetLocation() - AlignOffset 
		);

		MoveComp.SpringToTargetLocation(
			DesiredTransform.GetLocation(),
			Settings.Sword.Attack.SpringToLocationStiffness,
			Settings.Sword.Attack.SpringToLocationDamping,
			DeltaSeconds	
		);

		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			Settings.Sword.Attack.RotationLerpSpeed,
			Settings.Sword.Attack.bConstantLerpSpeed,
			DeltaSeconds	
		);

		// System::DrawDebugSphere(DesiredTransform.GetLocation(), LineColor = FLinearColor::Green);
		// System::DrawDebugSphere(MoveComp.DesiredSwarmActorTransform.GetLocation(), LineColor = FLinearColor::Red);
		// System::DrawDebugSphere(VictimTransform.GetLocation(), LineColor = FLinearColor::Yellow);

		BehaviourComp.FinalizeBehaviour();

 	}

	UFUNCTION()
	void HandleNotify_AttackStarted(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		AttackStartedTimeStamp = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void HandleNotify_AttackPerformed(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		++NumAttacksPerformedTotal;
		++NumAttacksPerformedConsecutively;

		if (NumAttacksPerformedTotal >= Settings.Sword.Attack.NumTotalAttacks)
		{
			// we go to idle because we want to reset entirely
			PrioritizeState(ESwarmBehaviourState::Idle);
			// PrioritizeState(ESwarmBehaviourState::TelegraphInitial);
// 			SkelMeshComp.RemoveSwarmAnimSettings(this);
			NumAttacksPerformedTotal = 0;
			NumAttacksPerformedConsecutively = 0;
		}
		else if (NumAttacksPerformedConsecutively >= Settings.Sword.Attack.NumConsecutiveAttacks)
		{
 			PrioritizeState(ESwarmBehaviourState::TelegraphBetween);
			NumAttacksPerformedConsecutively = 0;
		}
	}

	void BindAttackNotifyDelegate()
	{
		// Attack Start
		OnNotifyExecuted_AttackStarted.BindUFunction(this, n"HandleNotify_AttackStarted");
		SwarmActor.BindAnimNotifyDelegate(
			UAnimNotify_SwarmAttackStarted::StaticClass(),
			OnNotifyExecuted_AttackStarted
		);

		// Attack Performed 
		OnNotifyExecuted_AttackPerformed.BindUFunction(this, n"HandleNotify_AttackPerformed");
		SwarmActor.BindAnimNotifyDelegate(
			UAnimNotify_SwarmAttackPerformed::StaticClass(),
			OnNotifyExecuted_AttackPerformed
		);
	}

	void UnbindAttackNotifyDelegate()
	{
		// Attack Started 
		SwarmActor.UnbindAnimNotifyDelegate(
			UAnimNotify_SwarmAttackStarted::StaticClass(),
			OnNotifyExecuted_AttackStarted
		);

		// Attack Performed 
		SwarmActor.UnbindAnimNotifyDelegate(
			UAnimNotify_SwarmAttackPerformed::StaticClass(),
			OnNotifyExecuted_AttackPerformed
		);
	}

}





import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackPerformed;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackStarted;

class USwarmHammerAttackCapability : USwarmBehaviourCapability
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

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
			return EHazeNetworkActivation::DontActivate;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkActivation::DontActivate;

		// Victim, States and Claims are already synced. No need to activeFromControl atm.
		// return EHazeNetworkActivation::ActivateFromControl;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.Hammer.Attack.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.Attack.AnimSettingsDataAsset,
			this
		);

		// should always reset upon entering
		NumAttacksPerformedConsecutively = 0;

		BehaviourComp.NotifyStateChanged();

		VictimTransform = VictimComp.GetLastValidGroundTransform();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);

		VictimComp.OverrideClosestPlayer(VictimComp.PlayerVictim, this);

		BindAttackNotifyDelegate();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnbindAttackNotifyDelegate();

		if (DeactivationParams.IsStale())
			NumAttacksPerformedTotal = 0;

		if (NumAttacksPerformedTotal >= Settings.Hammer.Attack.NumTotalAttacks)
		{
			NumAttacksPerformedTotal = 0;
			NumAttacksPerformedConsecutively = 0;
		}

		SwarmActor.UnclaimBothPlayers(ESwarmBehaviourState::Attack);
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		UpdateMovement(DeltaSeconds);
		BehaviourComp.FinalizeBehaviour();
//		UpdateBehaviourDebug();
 	}

	UFUNCTION()
	void HandleNotify_AttackStarted(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		AttackStartedTimeStamp = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void HandleNotify_AttackPerformed(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMesh, UAnimNotify AnimNotify)
	{
		// if (HasControl() == false)
		// 	return;
		// NetHandleAttackPerformed();

		HandleAttackPerformed();
	}

	UFUNCTION(NetFunction)
	void NetHandleAttackPerformed()
	{
		HandleAttackPerformed();
	}

	void HandleAttackPerformed()
	{
		++NumAttacksPerformedTotal;
		++NumAttacksPerformedConsecutively;

		if(IsBlocked() || !IsActive())
		{
			NumAttacksPerformedTotal = 0;
			NumAttacksPerformedConsecutively = 0;
			return;
		}

		// proceed to recover state once we are done with all attacks
		if (NumAttacksPerformedTotal >= Settings.Hammer.Attack.NumTotalAttacks)
		{
			NumAttacksPerformedTotal = 0;
			NumAttacksPerformedConsecutively = 0;
			PrioritizeState(ESwarmBehaviourState::Recover);
		}
		else if (NumAttacksPerformedConsecutively >= Settings.Hammer.Attack.NumConsecutiveAttacks)
		// else if (VictimComp.CurrentVictim.HasControl() && NumAttacksPerformedConsecutively >= Settings.Hammer.Attack.NumConsecutiveAttacks)
		{
			const bool bAliveAndGrounded = VictimComp.IsVictimAliveAndGrounded();
			const bool bTelegraphIsClaimable = SwarmActor.IsVictimClaimable(ESwarmBehaviourState::TelegraphBetween);
			if(bAliveAndGrounded && bTelegraphIsClaimable)
			{
				SwarmActor.ClaimVictim(ESwarmBehaviourState::TelegraphBetween, 1);
				PrioritizeState(ESwarmBehaviourState::TelegraphBetween);
				// NetSwitchToTelegraphBetween();
			}
		}
		else if (!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
		{
			// We might lose our victim claim mid-attack, due to sharedGentlemaning activating 
			// when players are close to each other. Fallback to a previous state when this happens.
			// (we do it here because we do not want to cancel the attack immediately when it happens)
			PrioritizeState(ESwarmBehaviourState::PursueMiddle);
			// NetFallbackToPreviousState();
		}
		else 
		// else if(VictimComp.CurrentVictim.OtherPlayer.HasControl())
		{
			// alternate victim, every attack, if they are close enough to each other
			const float DistBetweenPlayers_SQ = Game::GetDistanceSquaredBetweenPlayers();
			const float DistThreshold_SQ = FMath::Square(Settings.Hammer.Attack.AlternateVictimDistanceBetweenPlayers);
			const bool bOtherVictimIsClaimable = SwarmActor.IsOtherVictimClaimable(ESwarmBehaviourState::Attack);
			if(DistBetweenPlayers_SQ <= DistThreshold_SQ && bOtherVictimIsClaimable)
			{
				SwarmActor.ClaimOtherVictim(ESwarmBehaviourState::Attack, 1);
				VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim.OtherPlayer, this);
				// NetSwitchPlayerVictim();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSwitchToTelegraphBetween()
	{
		SwarmActor.ClaimVictim(ESwarmBehaviourState::TelegraphBetween, 1);
		PrioritizeState(ESwarmBehaviourState::TelegraphBetween);
	}

	UFUNCTION(NetFunction)
	void NetFallbackToPreviousState()
	{
		PrioritizeState(ESwarmBehaviourState::PursueMiddle);
	}

	UFUNCTION(NetFunction)
	void NetSwitchPlayerVictim()
	{
		SwarmActor.ClaimOtherVictim(ESwarmBehaviourState::Attack, 1);
		VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim.OtherPlayer, this);
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

	void UpdateMovement(const float DeltaSeconds)
	{
		// Only keep track of the victims transform for a certain amount of time.  
		const float TimeSinceAttackStarted = Time::GetGameTimeSince(AttackStartedTimeStamp);
		if (TimeSinceAttackStarted < Settings.Hammer.Attack.KeepTrackOfVictimDuration)
		{
			VictimTransform = VictimComp.GetLastValidGroundTransform();

		}

		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);

		// zero the pitch if the swarm happens to be penetrating the ground.
		if(SwarmToVictimQuat.Vector().DotProduct(FVector::UpVector) > 0.f)
		{
			// (the ground normal is not realiable. Its bumpy. Don't use it)
			FQuat DummySwing, SwarmToVictimQuat_Twist;
			SwarmToVictimQuat.ToSwingTwist(
				FVector::UpVector,
				DummySwing,
				SwarmToVictimQuat_Twist
			);
			SwarmToVictimQuat = SwarmToVictimQuat_Twist;
		}

		//////////////////////////////////////////////////////////////////////////
		// Attack is relative to swarm and Victim. Ignores ArenaMiddleActor.
 		FVector AlignOffset = SwarmToVictimQuat.RotateVector(
			SkelMeshComp.GetAlignBoneLocalLocation()
		);

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			VictimTransform.GetLocation() - AlignOffset 
		);

		MoveComp.InterpolateToTarget(
			DesiredTransform,
			Settings.Hammer.Attack.LerpSpeed,
			Settings.Hammer.Attack.bConstantLerpSpeed,
			DeltaSeconds
		);

		//////////////////////////////////////////////////////////////////////////
		// DEBUG
		// System::DrawDebugArrow(
		// 	SwarmActor.GetActorLocation(),
		// 	SwarmActor.GetActorLocation() + SwarmToVictimQuat.Vector() * 1000.f,
		// 	1000.f,
		// 	FLinearColor::Yellow,
		// 	0.f, 
		// 	10.f
		// );

		// System::DrawDebugPoint(
		// 	VictimTransform.GetLocation(),
		// 	10.f,
		// 	PointColor = FLinearColor::Green,
		// 	Duration = 0.f
		// );

		// System::DrawDebugPoint(
		// 	DesiredTransform.GetLocation(),
		// 	10.f,
		// 	PointColor = FLinearColor::Blue,
		// 	Duration = 0.f
		// );

  		// FVector AlignLocation = SwarmActor.SkelMeshComp.GetSocketLocation(n"Align");
		// System::DrawDebugPoint(
		// 	AlignLocation,
		// 	10.f,
		// 	PointColor = FLinearColor::Yellow,
		// 	Duration = 0.f
		// );
		//////////////////////////////////////////////////////////////////////////

	}

	void UpdateBehaviourDebug()
	{
		// FVector PlayerCenter = Game::GetCody().GetActorLocation() + Game::GetMay().GetActorLocation();
		// PlayerCenter *= 0.5f;
		// PlayerCenter += FVector::UpVector*5.f;
		// System::DrawDebugCircle(
		// 	PlayerCenter,
		// 	 Settings.Hammer.Attack.AlternateVictimDistanceBetweenPlayers * 0.5f,
		// 	  32,
		// 	   FLinearColor::Red,
		// 	   0.f,
		// 	   10.f,
		// 		  FVector::ForwardVector,
		// 		   FVector::RightVector
		// 		   );
		// System::DrawDebugCircle(
		// 	PlayerCenter,
		// 	Game::GetDistanceBetweenPlayers()*0.5f,
		// 	  32,
		// 	   FLinearColor::Green,
		// 	   0.f,
		// 	   10.f,
		// 		  FVector::ForwardVector,
		// 		   FVector::RightVector
		// 		   );
		// PrintToScreen("DistanceBetweenPlayers: " + Game::GetDistanceBetweenPlayers(), 0.f);

//		bool bVictimClaimed = VictimComp.HasVictimBeenClaimed();
//		bool bOtherVictimClaimed = VictimComp.HasOtherVictimBeenClaimed();
//		PrintToScreen("Victim Claimed: " + bVictimClaimed, 0.f, bVictimClaimed ? FLinearColor::Red : FLinearColor::Green);
//		PrintToScreen("Other Victim Claimed: " + bOtherVictimClaimed, 0.f, bOtherVictimClaimed ? FLinearColor::Red : FLinearColor::Green);
//		PrintToScreen("Victim: : " + VictimComp.CurrentVictim.GetName(), 0.f, FLinearColor::Purple);
//		PrintToScreen(Owner.GetName() + " " + GetSwarmCapabilityTag(AssignedState) + " Victim: " + VictimComp.CurrentVictim);
	}

}




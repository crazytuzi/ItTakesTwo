
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackPerformed;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmAttackStarted;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

class USwarmSoloHandSmashAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Attack;

    AQueenActor Queen = nullptr;

	FQuat SwarmToVictimQuat = FQuat::Identity;
	FTransform VictimTransform = FTransform::Identity;
	int32 NumAttacksPerformedConsecutively = 0;
	int32 NumAttacksPerformedTotal = 0;
	float AttackStartedTimeStamp = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Super::Setup(SetupParams);
        Queen = Cast<AQueenActor>(MoveComp.ArenaMiddleActor);
        ensure(Queen != nullptr);
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
			return EHazeNetworkActivation::DontActivate;

		if(!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkActivation::DontActivate;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		// if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.SoloHandSmash.Attack.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.SoloHandSmash.Attack.AnimSettingsDataAsset,
			this
		);

		// don't automatically switch player during attack...
		VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim, this);

		PlayFoghornVOBankEvent(Queen.FoghornBank, n"FoghornDBBossFightSecondPhaseHandWaspQueen", Queen);
		
		BehaviourComp.NotifyStateChanged();

		VictimTransform = VictimComp.GetLastValidGroundTransform();
		SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);

		AttackStartedTimeStamp = Time::GetGameTimeSeconds();
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

		// (victim might be dead)
		if(VictimComp.CurrentVictim != nullptr)
			SwarmActor.UnclaimVictim(ESwarmBehaviourState::Attack);

		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

	UFUNCTION()
	void HandleAttackPerformed()
	{
		++NumAttacksPerformedTotal;
		++NumAttacksPerformedConsecutively;

//		Print("NumAttacksPerformedConsecutively: " + NumAttacksPerformedConsecutively, Duration = 1.f);
//		Print("NumAttacksPerformedTotal: " + NumAttacksPerformedTotal, Duration = 1.f);

		if(!VictimComp.IsVictimAliveAndGrounded() || VictimComp.IsVictimGrinding())
		{
			// PrintToScreenScaled("Prio to Idle!", Duration = 3.f);
 			PrioritizeState(ESwarmBehaviourState::Idle);
			NumAttacksPerformedConsecutively = 0;
			NumAttacksPerformedTotal = 0;
		}
		else if (NumAttacksPerformedTotal >= Settings.SoloHandSmash.Attack.NumTotalAttacks)
		{
//			Print("Going to Telegraph Init", 1.f, FLinearColor::Red);
			// PrioritizeState(ESwarmBehaviourState::TelegraphInitial);

//			SwarmActor.ClaimVictim(ESwarmBehaviourState::Gentleman, 99);
//			if(VictimComp.CurrentVictim != nullptr)
//				SwarmActor.UnclaimVictim(ESwarmBehaviourState::Attack);

 			PrioritizeState(ESwarmBehaviourState::Gentleman);
			NumAttacksPerformedConsecutively = 0;
			NumAttacksPerformedTotal = 0;
		}
		else if (NumAttacksPerformedConsecutively >= Settings.SoloHandSmash.Attack.NumConsecutiveAttacks)
		{
//			Print("Going to Telegraph between", 1.f, FLinearColor::Yellow);
			SwarmActor.ClaimVictim(ESwarmBehaviourState::TelegraphBetween, 4);
 			PrioritizeState(ESwarmBehaviourState::TelegraphBetween);
			NumAttacksPerformedConsecutively = 0;
		}


	}

 	UFUNCTION(BlueprintOverride)
 	void TickActive(float DeltaSeconds)
 	{
		// Only keep track of the victims transform for a certain amount of time.  
		// NOTE: important that we use TimeSinceAttackedStarted instead of GetStateDuration()
		// because we want to reset that timer in case we do consecutive attacks. 
		const float TimeSinceStarted = Time::GetGameTimeSince(AttackStartedTimeStamp);
		if (TimeSinceStarted < Settings.SoloHandSmash.Attack.KeepTrackOfVictimDuration)
		{
			VictimTransform = VictimComp.GetLastValidGroundTransform();
			SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);
		}

		// The ground normal is to unrealiable in queen lvl
		const FVector GroundNormal = FVector::UpVector;
		// FVector GroundNormal = VictimComp.GetVictimGroundNormal();

		// SwarmToVictimQuat_TWIST== SwarmToVictimQuat constrained to rotate around 
		// the plane normal axis which the player is standing on.
		FQuat DummySwing, SwarmToVictimQuat_TWIST;
		SwarmToVictimQuat.ToSwingTwist(
			GroundNormal,
			DummySwing,
			SwarmToVictimQuat_TWIST	
		);

		// The offset will be relative to the vector between the swarm and the victim
		// but the vector will be projected on the ground plane that the player is standing on.
 		const FVector AlignOffset = SwarmToVictimQuat_TWIST.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat_TWIST,
			VictimTransform.GetLocation() - AlignOffset
		);

		MoveComp.SpringToTargetLocation(
			DesiredTransform.GetLocation(),
			Settings.SoloHandSmash.Attack.SpringToLocationStiffness,
			Settings.SoloHandSmash.Attack.SpringToLocationDamping,
			DeltaSeconds	
		);

		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			Settings.SoloHandSmash.Attack.RotationLerpSpeed,
			Settings.SoloHandSmash.Attack.bConstantLerpSpeed,
			DeltaSeconds	
		);


		BehaviourComp.FinalizeBehaviour();

		/////////////////////////////////////////////////////////////////////////////////////
		// DEBUG

		// PrintToScreen(Owner.GetName() + " " + GetSwarmCapabilityTag(AssignedState) + " Victim: " + VictimComp.CurrentVictim);

		// System::DrawDebugSphere(
		// 	MoveComp.DesiredSwarmActorTransform.GetLocation(),
		// 	 100.f, 8.f,
		// 	 FLinearColor::Red
		// 	 , 0.f
		// );

		// System::DrawDebugArrow(
		// 	SwarmActor.GetActorLocation(),
		// 	SwarmActor.GetActorLocation() + SwarmToVictimQuat.Vector() * 1000.f,
		// 	1000.f,
		// 	FLinearColor::Yellow,
		// 	0.f, 
		// 	10.f
		// );

		// System::DrawDebugArrow(
		// 	VictimTransform.GetLocation(),
		// 	VictimTransform.GetLocation() + GroundNormal * 1000.f,
		// 	1000.f,
		// 	FLinearColor::Green,
		// 	0.f, 
		// 	10.f
		// );

 	}

	FHazeAnimNotifyDelegate OnNotifyExecuted_AttackPerformed;
	FHazeAnimNotifyDelegate OnNotifyExecuted_AttackStarted;

	UFUNCTION()
	void HandleNotify_AttackStarted(
		AHazeActor Actor,
		UHazeSkeletalMeshComponentBase SkelMesh,
		UAnimNotify AnimNotify
	)
	{
		// note to self: we need to this in order to reset timers for consecutive attacks. 
		AttackStartedTimeStamp = Time::GetGameTimeSeconds();
	}

	UFUNCTION()
	void HandleNotify_AttackPerformed(
		AHazeActor Actor,
		UHazeSkeletalMeshComponentBase SkelMesh,
		UAnimNotify AnimNotify
	)
	{
		HandleAttackPerformed();
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




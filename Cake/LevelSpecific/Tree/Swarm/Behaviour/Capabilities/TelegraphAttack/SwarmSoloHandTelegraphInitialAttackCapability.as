
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

class USwarmSoloHandSmashTelegraphInitialAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphInitial;

    AQueenActor Queen = nullptr;

	FTransform StartTransform = FTransform::Identity;

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

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphInitial))
			return EHazeNetworkActivation::DontActivate;

		if (!VictimComp.IsVictimAliveAndGrounded())
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

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.SoloHandSmash.TelegraphInitial.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphInitial))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
            Settings.SoloHandSmash.TelegraphInitial.AnimSettingsDataAsset,
			this,
            Settings.SoloHandSmash.TelegraphInitial.TelegraphingTime
		);

		// makes sure that we stay on this player while the capability is active
		VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim, this);

		BehaviourComp.NotifyStateChanged();

		StartTransform = MoveComp.DesiredSwarmActorTransform;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);

		// (victim might be dead)
		if(VictimComp.CurrentVictim != nullptr)
			SwarmActor.UnclaimVictim(ESwarmBehaviourState::TelegraphInitial);

		VictimComp.RemoveClosestPlayerOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		// Request attack once we've telegraphed long enough.
		if (BehaviourComp.GetStateDuration() >= Settings.SoloHandSmash.TelegraphInitial.TelegraphingTime)
		{
			// if we don't do this check it'll just rotate the entire
			// wheel until it comes back to this state again 
			if (SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
				PrioritizeState(ESwarmBehaviourState::Attack);
			else
				SwarmActor.ClaimVictim(ESwarmBehaviourState::Attack, 1);
		}

		UpdateMovement(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void UpdateMovement(const float DeltaSeconds)
	{
		const FTransform VictimTransform = VictimComp.GetLastValidGroundTransform();
		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsActor(VictimComp.PlayerVictim);

		const FVector MiddleCOM = MoveComp.GetArenaMiddleCOM();
		const FVector TowardsTarget = VictimComp.GetVictimCenterTransform().GetLocation() - MiddleCOM;
		const FQuat QueenToVictimQuat = Math::MakeQuatFromX(TowardsTarget);

		FQuat DummySwing, SwarmToVictimQuat_Twist, QueenToVictimQuat_Twist;

		// The ground normal is to unrealiable in queen lvl
		const FVector GroundNormal = FVector::UpVector;
		// const FVector GroundNormal = VictimComp.GetVictimGroundNormal();

		// Swarm To Victim Quat projected on plane that the player is standing on.
		SwarmToVictimQuat.ToSwingTwist(
			GroundNormal,
			DummySwing,
			SwarmToVictimQuat_Twist
		);

		// Queen to victim quat projected on the plane that the player is standing on 
		QueenToVictimQuat.ToSwingTwist(
			GroundNormal,
			DummySwing,
			QueenToVictimQuat_Twist
		);

		// System::DrawDebugLine(
		// 	VictimTransform.GetLocation(),
		// 	VictimTransform.GetLocation() - QueenToVictimQuat_Twist.Vector()*10000.f,
		// 	FLinearColor::Yellow,
		// 	0.f,
		// 	6.f
		// );

		CalculateDesiredQuatWhileGentlemaning(QueenToVictimQuat_Twist);

//		System::DrawDebugLine(
//			VictimTransform.GetLocation(),
//			VictimTransform.GetLocation() - QueenToVictimQuat_Twist.Vector()*10000.f
//		);

		// The offset will be relative to the vector between the Queen and the victim
		// but the vector will be projected on the ground plane that the player is standing on.
 		const FVector AlignOffset = QueenToVictimQuat_Twist.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
		const FVector ExtraOffset = QueenToVictimQuat_Twist.RotateVector(
			Settings.SoloHandSmash.TelegraphInitial.TelegraphOffset
		);

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			VictimTransform.GetLocation() - AlignOffset + ExtraOffset
		);

		MoveComp.SpringToTargetWithTime(
			DesiredTransform.GetLocation(),
			Settings.SoloHandSmash.TelegraphInitial.TelegraphingTime,
			DeltaSeconds
		);

		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			Settings.SoloHandSmash.TelegraphInitial.RotateTowardsPlayerSpeed,
			Settings.SoloHandSmash.TelegraphInitial.bInterpConstantSpeed,
			DeltaSeconds	
		);

//		System::DrawDebugSphere(
//		MoveComp.DesiredSwarmActorTransform.GetLocation(),
//		100.f, 8.f,
//		FLinearColor::Blue
//		, 0.f
//		);

	}

}












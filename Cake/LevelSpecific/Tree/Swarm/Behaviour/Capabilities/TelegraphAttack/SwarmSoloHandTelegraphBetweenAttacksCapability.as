
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

class USwarmSoloHandSmashTelegraphBetweenAttacksCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphBetween;

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

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphBetween))
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

		if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphBetween))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.SoloHandSmash.TelegraphBetween.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.SoloHandSmash.TelegraphBetween.AnimSettingsDataAsset,
			this,
			Settings.SoloHandSmash.TelegraphBetween.BlendInTime
		);

		StartTransform = MoveComp.DesiredSwarmActorTransform;

		BehaviourComp.NotifyStateChanged();

		AHazePlayerCharacter ClosestPlayerOverride = VictimComp.PlayerVictim;

		if(ClosestPlayerOverride == nullptr)
			ClosestPlayerOverride = VictimComp.FindClosestLivingPlayerWithinRange();

		if (Settings.SoloHandSmash.TelegraphBetween.bSwitchPlayerVictimBetweenAttacks)
		{
			if(VictimComp.IsPlayerAliveAndGrounded(ClosestPlayerOverride.OtherPlayer))
			{
				ClosestPlayerOverride = ClosestPlayerOverride.OtherPlayer;
			}
		}

		VictimComp.OverrideClosestPlayer(ClosestPlayerOverride, this);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);

		// (victim might be dead)
		if(VictimComp.CurrentVictim != nullptr)
			SwarmActor.UnclaimVictim(ESwarmBehaviourState::TelegraphBetween);

		VictimComp.RemoveClosestPlayerOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		if (BehaviourComp.GetStateDuration() > Settings.SoloHandSmash.TelegraphBetween.TimeBetweenAttacks)
		{
			// if we don't do this check it'll just rotate the entire state wheel
			// and potentially trigger an unwanted capbility
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
 		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);
		const FVector QueenLocation = MoveComp.GetArenaMiddleCOM();
		const FVector QueenToVictim = VictimTransform.GetLocation() - QueenLocation;

		const FQuat QueenToVictimQuat = Math::MakeQuatFromX(QueenToVictim);

		// The ground normal is to unrealiable in queen lvl
		const FVector GroundNormal = FVector::UpVector;
		// FVector GroundNormal = VictimComp.GetVictimGroundNormal();

		// Queen to victim quat projected on the plane that the player is standing on 
		FQuat DummySwing, QueenToVictimQuat_Twist;
		QueenToVictimQuat.ToSwingTwist(
			GroundNormal,
			DummySwing,
			QueenToVictimQuat_Twist
		);

		CalculateDesiredQuatWhileGentlemaning(QueenToVictimQuat_Twist);

		// The offset will be relative to the vector between the Queen and the victim
 		const FVector AlignOffset = QueenToVictimQuat_Twist.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
		const FVector ExtraOffset = QueenToVictimQuat_Twist.RotateVector(
			Settings.SoloHandSmash.TelegraphBetween.TelegraphOffset
		);

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			QueenLocation + QueenToVictim - AlignOffset + ExtraOffset 
		);

		MoveComp.SpringToTargetWithTime(
			DesiredTransform.GetLocation(),
			Settings.SoloHandSmash.TelegraphBetween.TimeBetweenAttacks,
			DeltaSeconds	
		);

 		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			Settings.SoloHandSmash.TelegraphBetween.RotateTowardsPlayerSpeed,
			Settings.SoloHandSmash.TelegraphBetween.bInterpConstantSpeed,
			DeltaSeconds
		);

		// System::DrawDebugSphere(
		// 	MoveComp.DesiredSwarmActorTransform.GetLocation(),
		// 	 100.f, 8.f,
		// 	 FLinearColor::Green
		// 	 , 1.f
		// );

	}
}
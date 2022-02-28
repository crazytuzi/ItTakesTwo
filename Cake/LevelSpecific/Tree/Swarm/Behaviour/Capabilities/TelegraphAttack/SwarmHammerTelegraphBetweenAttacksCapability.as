
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmHammerTelegraphBetweenAttacksCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphBetween;

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

		// Victim, States and Claims are already synced. No need to activeFromControl atm.
		return EHazeNetworkActivation::ActivateLocal;
		// return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		// Need to merge override with claiming
		// if(!SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphBetween))
		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.Hammer.TelegraphBetween.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Hammer.TelegraphBetween.AnimSettingsDataAsset,
			this,
			Settings.Hammer.TelegraphBetween.TimeBetweenAttacks
		);

		BehaviourComp.NotifyStateChanged();

		AHazePlayerCharacter ClosestPlayerOverride = VictimComp.PlayerVictim;

		// if(ClosestPlayerOverride == nullptr)
		// 	ClosestPlayerOverride = VictimComp.FindClosestLivingPlayerWithinRange();

		// if (Settings.Hammer.TelegraphBetween.bSwitchPlayerVictimBetweenAttacks)
		// {
		// 	// if(VictimComp.IsValidTarget(ClosestPlayerOverride.OtherPlayer))
		// 	if(CanSwapToTarget(ClosestPlayerOverride.OtherPlayer))
		// 	{
		// 		ClosestPlayerOverride = ClosestPlayerOverride.OtherPlayer;
		// 	}
		// }

		// if(!SwarmActor.VictimComp.IsUsingSharedGentlemanBehaviour())
		// 	SwarmActor.VictimComp.ClearClaimsForPlayer(ClosestPlayerOverride.OtherPlayer);

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

	bool CanSwapToTarget(AHazePlayerCharacter InPlayer) const
	{
		if(!VictimComp.IsPlayerAliveAndGrounded(InPlayer))
			return false;

		if(!SwarmActor.IsClaimable(ESwarmBehaviourState::Attack, InPlayer))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		const float TimeElapsed = BehaviourComp.GetStateDuration();
		if (TimeElapsed > Settings.Hammer.TelegraphBetween.TimeBetweenAttacks)
		{
			// if we don't do this check it'll just rotate the entire state wheel
			// and potentially trigger an unwanted capbility
			if (SwarmActor.IsClaimingVictim(ESwarmBehaviourState::Attack))
			{
				PrioritizeState(ESwarmBehaviourState::Attack);
			}
			else if(SwarmActor.IsVictimClaimable(ESwarmBehaviourState::Attack))
			{
				SwarmActor.ClaimVictim(ESwarmBehaviourState::Attack, 1);
			}
			else if(SwarmActor.IsOtherVictimClaimable(ESwarmBehaviourState::Attack) && VictimComp.IsOtherVictimAliveAndGrounded())
			{
				SwarmActor.ClaimOtherVictim(ESwarmBehaviourState::Attack, 1);
				VictimComp.OverrideClosestPlayer(VictimComp.CurrentVictim.OtherPlayer, this);
			}
			else
			{
				PrioritizeState(ESwarmBehaviourState::PursueMiddle);
			}
		}

		UpdateMovement(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void UpdateMovement(const float DeltaSeconds)
	{
		const FTransform DesiredTransform = CalculateDesiredTransform();

		if(Settings.Hammer.TelegraphBetween.MoveWithConstantLerpSpeed != -1.f)
		{
			MoveComp.InterpolateToTarget(
				DesiredTransform,
				Settings.Hammer.TelegraphBetween.MoveWithConstantLerpSpeed,
				true,
				DeltaSeconds
			);

			// MoveComp.InterpolateToTargetRotation(
			// 	DesiredTransform.GetRotation(),
			// 	Settings.Hammer.TelegraphBetween.RotateTowardsPlayerSpeed,
			// 	Settings.Hammer.TelegraphBetween.bInterpConstantSpeed,
			// 	DeltaSeconds
			// );
		}
		else
		{
			MoveComp.SpringToTargetWithTime(
				DesiredTransform.GetLocation(),
				Settings.Hammer.TelegraphBetween.TimeBetweenAttacks,
				DeltaSeconds	
			);

			MoveComp.InterpolateToTargetRotation(
				DesiredTransform.GetRotation(),
				Settings.Hammer.TelegraphBetween.RotateTowardsPlayerSpeed,
				Settings.Hammer.TelegraphBetween.bInterpConstantSpeed,
				DeltaSeconds
			);
		}
	}

	FTransform CalculateDesiredTransform() const
	{
		const FTransform VictimTransform = VictimComp.GetLastValidGroundTransform();
 		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);
		const FVector ArenaPos = MoveComp.ArenaMiddleActor.GetActorLocation();
		const FVector ArenaToVictim = VictimTransform.GetLocation() - ArenaPos;

		const FQuat ArenaToVictimQuat = ArenaToVictim.ToOrientationQuat();

		// Ground normal can be bumpy and give us almost horizontal normals sometimes.
		const FVector GroundNormal = FVector::UpVector;
		//const FVector GroundNormal = VictimComp.GetVictimGroundNormal();

		// Arena to victim quat projected on the plane that the player is standing on 
		FQuat DummySwing, ArenaToVictimQuat_Twist;
		ArenaToVictimQuat.ToSwingTwist(
			GroundNormal,
			DummySwing,
			ArenaToVictimQuat_Twist
		);

		CalculateDesiredQuatWhileGentlemaning(ArenaToVictimQuat_Twist);

		// The offset will be relative to the vector between the arena and the victim
 		const FVector AlignOffset = ArenaToVictimQuat_Twist.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
		const FVector ExtraOffset = ArenaToVictimQuat_Twist.RotateVector(
			Settings.Hammer.TelegraphBetween.AdditionalOffset
		);

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			ArenaPos + ArenaToVictim - AlignOffset + ExtraOffset 
		);

		return DesiredTransform;
	}

	FTransform CalculateDesiredTransform_OLD() const
	{
		const FTransform VictimTransform = VictimComp.GetLastValidGroundTransform();
 		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);

		//////////////////////////////////////////////////////////////////////////
		// Stay in arena center and face the player.
// 		FTransform DesiredTransform = MoveComp.ArenaMiddleActor.GetActorTransform();
// 		DesiredTransform.SetRotation(SwarmToVictimQuat);

		//////////////////////////////////////////////////////////////////////////
		// Attack is relative to swarm and Victim. Ignores ArenaMiddleActor.
//  		const FVector AlignOffset = SwarmToVictimQuat.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
// 		const FTransform DesiredTransform = FTransform(
// 			SwarmToVictimQuat,
// 			VictimTransform.GetLocation() - AlignOffset 
// 		);

		//////////////////////////////////////////////////////////////////////////
		// Attack is relative to ArenaMiddle and Victim. 
		const FVector ArenaMiddle = MoveComp.ArenaMiddleActor.GetActorLocation();
		const FVector ArenaMiddleToVictim = VictimTransform.GetLocation() - ArenaMiddle;
		const FQuat ArenaMiddleToVictimQuat = Math::MakeQuatFromX(ArenaMiddleToVictim);
 		const FVector AlignOffset = ArenaMiddleToVictimQuat.RotateVector(SkelMeshComp.GetAlignBoneLocalLocation());
		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			ArenaMiddle + ArenaMiddleToVictim - AlignOffset 
		);

//   		FVector AlignLocation = SwarmActor.SkelMeshComp.GetSocketLocation(n"Align");
// 		System::DrawDebugPoint(
// 			AlignLocation,
// 			10.f,
// 			PointColor = FLinearColor::Yellow,
// 			Duration = 0.f
// 		);

		return DesiredTransform;
	}

}












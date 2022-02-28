
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;
import Cake.LevelSpecific.Tree.Queen.QueenActor;

class USwarmSoloHandSmashGentlemanCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::Gentleman;

	float TimeStampVictimUpdate = 0.f;
    AQueenActor Queen = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
            Settings.SoloHandSmash.Gentleman.AnimSettingsDataAsset,
			this,
			2.f
		);

		AHazePlayerCharacter NewVictim = VictimComp.PlayerVictim;

		if (NewVictim == nullptr)
			NewVictim = VictimComp.FindClosestLivingPlayerWithinRange();
		else if(ShouldSwapVictim(NewVictim))
			NewVictim = VictimComp.PlayerVictim.OtherPlayer;

		// might be null if both players are dead?
		if(NewVictim != nullptr)
			RequestPlayerVictim(NewVictim);

		BehaviourComp.NotifyStateChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		if (VictimComp.PlayerVictim == nullptr)
		{
			// Player target died while we were gentlemaning
			RequestPlayerVictim(VictimComp.FindClosestLivingPlayerWithinRange());
		}
		else if (IsPlayerAttackable(VictimComp.PlayerVictim))
		{
			// Need to claim a telegraphing slot before attempting to telegraph an attack to the player
			if (SwarmActor.IsClaimingVictim(ESwarmBehaviourState::TelegraphInitial))
			{
				// we got the claim. We'll request a behaviour switch to telegraph
				PrioritizeState(ESwarmBehaviourState::TelegraphInitial);
			}
			else
			{
				// try to claim a telegraphing slot for our current player victim
				SwarmActor.ClaimVictim(ESwarmBehaviourState::TelegraphInitial, 4);
			}
		}
		else if (ShouldSwapVictim(VictimComp.PlayerVictim) && IsPlayerAttackable(VictimComp.PlayerVictim.OtherPlayer))
		{
			// our player victim started grinding while we were gentlemaning.
			// Switch to the other player (as long as they aren't grinding as well)
			RequestPlayerVictim(VictimComp.PlayerVictim.OtherPlayer);
		}

		// the gentleman movement is relative to the player position - so we need a victim for this
		if (VictimComp.PlayerVictim != nullptr)
			UpdateMovement(DeltaSeconds);

		BehaviourComp.FinalizeBehaviour();
	}

	void RequestPlayerVictim(AHazePlayerCharacter InNewOverride)
	{
		if (InNewOverride == nullptr)
			return;

		VictimComp.OverrideClosestPlayer(InNewOverride, this);
		TimeStampVictimUpdate = Time::GetGameTimeSeconds();
	}

	bool ShouldSwapVictim(AHazePlayerCharacter InCurrentVictim) const
	{
		if(!VictimComp.IsPlayerAliveAndGrounded(InCurrentVictim.OtherPlayer))
			return false;
		
		// if the current victim is grinding then we switch to the other no matter what 
		// (even if the other guy is doing the same)
		if(VictimComp.IsPlayerGrinding(InCurrentVictim))
			return true;

		const float TimeSinceVictimUpdate = Time::GetGameTimeSince(TimeStampVictimUpdate);
		if(TimeSinceVictimUpdate > 3.f)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Super::Setup(SetupParams);
        Queen = Cast<AQueenActor>(MoveComp.ArenaMiddleActor);
        ensure(Queen != nullptr);
    }

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ensure(SwarmActor != nullptr);
		// ensure(SwarmActor.VictimComp.PlayerVictim != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;
		
		if(!IsAtleastOnePlayerAttackable())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	void UpdateMovement(const float DeltaSeconds)
	{
		const FTransform VictimTransform = VictimComp.PlayerVictim.GetActorTransform();
		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsActor(VictimComp.PlayerVictim);

		const FVector MiddleActorLocation = MoveComp.GetArenaMiddleCOM();
		const FVector TowardsTarget = VictimComp.GetVictimCenterTransform().GetLocation() - MiddleActorLocation;
		const FQuat QueenToVictimQuat = Math::MakeQuatFromX(TowardsTarget);

		FQuat DummySwing, SwarmToVictimQuat_Twist, QueenToVictimQuat_Twist;

		// Swarm To Victim Quat projected on plane that the player is standing on.
		SwarmToVictimQuat.ToSwingTwist(
			VictimComp.GetVictimGroundNormal(),
			DummySwing,
			SwarmToVictimQuat_Twist
		);

		// The ground normal is to unrealiable in queen lvl
		const FVector GroundNormal = FVector::UpVector;
		// const FVector GroundNormal = VictimComp.GetVictimGroundNormal();

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

		// System::DrawDebugLine(
		// 	VictimTransform.GetLocation(),
		// 	VictimTransform.GetLocation() - QueenToVictimQuat_Twist.Vector()*10000.f
		// );

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

	}


}












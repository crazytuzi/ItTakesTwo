
import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmSwordTelegraphInitialAttackCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphInitial;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BehaviourComp.HasBehaviourBeenFinalized())
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
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

		if(SwarmActor.MovementComp.ArenaMiddleActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.Sword.TelegraphInitial.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Sword.TelegraphInitial.AnimSettingsDataAsset,
			this,
			Settings.Sword.TelegraphInitial.TelegraphingTime
		);

		AHazePlayerCharacter ClosestPlayerOverride = VictimComp.PlayerVictim;
		if (Settings.Sword.TelegraphBetween.bSwitchPlayerVictimBetweenAttacks)
		{
			auto May = Game::GetMay();
			auto Cody = Game::GetCody();
			ClosestPlayerOverride = VictimComp.PlayerVictim == May ? Cody : May;

			const bool bOnPlatform = VictimComp.IsPlayerAliveAndGrounded(ClosestPlayerOverride); 
			const bool bGrinding = VictimComp.IsPlayerGrinding(ClosestPlayerOverride); 
			if(!bOnPlatform || bGrinding )
				ClosestPlayerOverride = ClosestPlayerOverride.OtherPlayer;
		}
		VictimComp.OverrideClosestPlayer(ClosestPlayerOverride, this);

		BehaviourComp.NotifyStateChanged();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwarmActor.StopSwarmAnimationByInstigator(this);
		VictimComp.RemoveClosestPlayerOverride(this);
	}

	const FVector OffsetFromFloor = FVector::UpVector * 100.f;

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaSeconds)
	{
		// Request attack once we've telegraphed long enough.
		if (BehaviourComp.GetStateDuration() > Settings.Sword.TelegraphInitial.TelegraphingTime)
			PrioritizeState(ESwarmBehaviourState::Attack);

		FTransform VictimTransform = VictimComp.PlayerVictim.GetActorTransform();

		VictimTransform.AddToTranslation(OffsetFromFloor);

		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsActor(VictimComp.PlayerVictim);
		const FQuat QueenToVictimQuat = CalcQueenToVictimQuat();

		FQuat DummySwing, SwarmToVictimQuat_Twist, QueenToVictimQuat_Twist;

		// Swarm To Victim Quat projected on plane that the player is standing on.
		SwarmToVictimQuat.ToSwingTwist(
//			VictimComp.GetVictimGroundNormal(),
			FVector::UpVector,
			DummySwing,
			SwarmToVictimQuat_Twist
		);

		// Queen to victim quat projected on the plane that the player is standing on 
		QueenToVictimQuat.ToSwingTwist(
//			VictimComp.GetVictimGroundNormal(),
			FVector::UpVector,
			DummySwing,
			QueenToVictimQuat_Twist
		);

		// The offset will be relative to the vector between the Queen and the victim
		// because we need the swarm to position himself in front of the player.
		FVector TotalOffset = -SkelMeshComp.GetAlignBoneLocalLocation(); 
		TotalOffset += Settings.Sword.TelegraphInitial.TelegraphOffset;

		// FVector VictimToQueen = MoveComp.ArenaMiddleActor.GetActorLocation();
		// VictimToQueen -= VictimComp.CurrentVictim.GetActorLocation();
		// VictimToQueen.Normalize();
		// float Amount = FMath::Abs(VictimToQueen.DotProduct(FVector::RightVector));
		// Amount *= 800.f;
		// Amount *= ShouldPlayRightSwordSlash() ? 1.f : -1.f;
		// PrintToScreen("Amount: " + Amount);
		// TotalOffset += FVector(0.f, Amount, 0.f);

		TotalOffset += FVector(0.f, ShouldPlayRightSwordSlash() ? 108.f : -108.f, 0.f);
		// TotalOffset += FVector(0.f, ShouldPlayRightSwordSlash() ? 450.f : -450.f, 0.f);
		TotalOffset = QueenToVictimQuat_Twist.RotateVector(TotalOffset);

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			VictimTransform.GetLocation() + TotalOffset
		);

		MoveComp.SpringToTargetWithTime(
			DesiredTransform.GetLocation(),
			Settings.Sword.TelegraphInitial.TelegraphingTime,
			DeltaSeconds
		);

		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			Settings.Sword.TelegraphInitial.RotateTowardsPlayerSpeed,
			Settings.Sword.TelegraphInitial.bInterpConstantSpeed,
			DeltaSeconds	
		);

		// System::DrawDebugSphere(DesiredTransform.GetLocation(), LineColor = FLinearColor::Green);
		// System::DrawDebugSphere(MoveComp.DesiredSwarmActorTransform.GetLocation(), LineColor = FLinearColor::Blue);
		// System::DrawDebugSphere(VictimTransform.GetLocation(), LineColor = FLinearColor::Yellow);

		BehaviourComp.FinalizeBehaviour();
	}

	bool ShouldPlayRightSwordSlash() const
	{
		FVector VictimToQueen = MoveComp.ArenaMiddleActor.GetActorLocation();
		VictimToQueen -= VictimComp.CurrentVictim.GetActorLocation();
		return VictimToQueen.DotProduct(FVector::RightVector) < 0.f;
	}

	FQuat CalcQueenToVictimQuat() const
	{
		const FVector MiddleActorLocation = MoveComp.GetArenaMiddleCOM();
//		const FVector MiddleActorLocation = MoveComp.ArenaMiddleActor.GetActorLocation();
		const FVector TowardsTarget = VictimComp.GetVictimCenterTransform().GetLocation() - MiddleActorLocation;
  		const FQuat NewQuat = Math::MakeQuatFromX(TowardsTarget);
		return NewQuat;
	}

}













import Cake.LevelSpecific.Tree.Swarm.Behaviour.Capabilities.SwarmBehaviourCapability;

class USwarmSwordTelegraphBetweenAttacksCapability : USwarmBehaviourCapability
{
	default AssignedState = ESwarmBehaviourState::TelegraphBetween;

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

		if(VictimComp.PlayerVictim == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(BehaviourComp.HasExplodedSinceStateChanged_WithinTimeWindow(Settings.Sword.TelegraphBetween.AbortAttackWithinTimeWindow))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!VictimComp.IsVictimAliveAndGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(VictimComp.IsVictimGrinding())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Sword.TelegraphBetween.AnimSettingsDataAsset,
			this,
			Settings.Sword.TelegraphBetween.TimeBetweenAttacks
		);

		BehaviourComp.NotifyStateChanged();

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
		if (BehaviourComp.GetStateDuration() > Settings.Sword.TelegraphBetween.TimeBetweenAttacks)
			PrioritizeState(ESwarmBehaviourState::Attack);

		const FTransform DesiredTransform = CalculateDesiredTransform();

		MoveComp.SpringToTargetWithTime(
			DesiredTransform.GetLocation(),
			Settings.Sword.TelegraphBetween.TimeBetweenAttacks,
			DeltaSeconds	
		);

		MoveComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			Settings.Sword.TelegraphBetween.RotateTowardsPlayerSpeed,
			Settings.Sword.TelegraphBetween.bInterpConstantSpeed,
			DeltaSeconds
		);

		// System::DrawDebugSphere(DesiredTransform.GetLocation(), LineColor = FLinearColor::Green);
		// System::DrawDebugSphere(MoveComp.DesiredSwarmActorTransform.GetLocation(), LineColor = FLinearColor::Purple);

		BehaviourComp.FinalizeBehaviour();
	}

	FTransform CalculateDesiredTransform() const 
	{
		FTransform VictimTransform = VictimComp.PlayerVictim.GetActorTransform();

		VictimTransform.AddToTranslation(OffsetFromFloor);

 		const FQuat SwarmToVictimQuat = MoveComp.GetFacingRotationTowardsTransform(VictimTransform);
		const FVector QueenLocation = MoveComp.GetArenaMiddleCOM();
		const FVector QueenToVictim = VictimTransform.GetLocation() - QueenLocation;
		const FQuat QueenToVictimQuat = Math::MakeQuatFromX(QueenToVictim);

		// Queen to victim quat projected on the plane that the player is standing on 
		FQuat DummySwing, QueenToVictimQuat_Twist;
		QueenToVictimQuat.ToSwingTwist(
			FVector::UpVector,
			DummySwing,
			QueenToVictimQuat_Twist
		);

		// The offset will be relative to the vector between the Queen and the victim
		// because we need the swarm to position himself in front of the player.
		FVector TotalOffset = -SkelMeshComp.GetAlignBoneLocalLocation(); 
		TotalOffset += Settings.Sword.TelegraphInitial.TelegraphOffset;
		TotalOffset += FVector(0.f, ShouldPlayRightSwordSlash() ? 108.f : -108.f, 0.f);
		// TotalOffset += FVector(0.f, ShouldPlayRightSwordSlash() ? 450.f : -450.f, 0.f);
		TotalOffset = QueenToVictimQuat_Twist.RotateVector(TotalOffset);

		const FTransform DesiredTransform = FTransform(
			SwarmToVictimQuat,
			VictimTransform.GetLocation() + TotalOffset
		);

		// System::DrawDebugSphere(VictimTransform.GetLocation(), LineColor = FLinearColor::Yellow);

		return DesiredTransform;
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












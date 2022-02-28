import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledPlayerExitCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledPlayerExit);

	default TickGroupOrder = 102;
	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"Boatsled";

	UAnimSequence ExitAnimation;

	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MovementComponent;

	UBoatsledComponent BoatsledComponent;
	UBoatsledComponent OtherPlayerBoatsledComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
		OtherPlayerBoatsledComponent = UBoatsledComponent::GetOrCreate(PlayerOwner.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerCanExitBoatsled())
			return EHazeNetworkActivation::DontActivate;

		if(!WasActionStopped(ActionNames::Cancel))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControlWithValidation;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ValidationParams) const
	{
		return PlayerCanExitBoatsled();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Stop interacting with boatsled
		BoatsledComponent.SetStateLocal(EBoatsledState::None);

		// Choose character-dependant animation
		ExitAnimation = BoatsledComponent.Boatsled.GetExitAnimation(PlayerOwner);

		// Detach from sled and clear locomotion asset
		PlayerOwner.DetachRootComponentFromParent();
		PlayerOwner.ClearLocomotionAssetByInstigator(BoatsledComponent);

		// Play slot animation with root motion
		PlayerOwner.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), ExitAnimation, BlendTime = 0.f);

		// Clear mesh rotation
		PlayerOwner.MeshOffsetComponent.ResetRotationWithTime(ExitAnimation.PlayLength);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MovementComponent.MakeFrameMovement(BoatsledTags::BoatsledPlayerExit);
		MoveData.OverrideGroundedState(EHazeGroundedState::Grounded);

		if(PlayerOwner.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData LocomotionRequest;
			LocomotionRequest.AnimationTag = n"Movement";
			PlayerOwner.RequestLocomotion(LocomotionRequest);
		}

		FHazeLocomotionTransform RootMotion;
		PlayerOwner.RequestRootMotion(DeltaTime, RootMotion);
		MoveData.ApplyRootMotion(RootMotion);

		MovementComponent.Move(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerOwner.IsPlayingAnimAsSlotAnimation(ExitAnimation))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Stahp that animation
		PlayerOwner.StopAllSlotAnimations(0.f);
	
		// Consume cancel button
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		// Cancel sledding
		BoatsledComponent.StopSledding(false);

		// Cleanup
		ExitAnimation = nullptr;
	}

	bool PlayerCanExitBoatsled() const
	{
		if(!BoatsledComponent.IsWaitingForOtherPlayer())
			return false;

		if(OtherPlayerBoatsledComponent.IsWaitingForOtherPlayer())
			return false;

		if(OtherPlayerBoatsledComponent.IsPlayerEnteringBoatsled())
			return false;

		if(OtherPlayerBoatsledComponent.GetBoatsledState() > EBoatsledState::WaitingForOtherPlayer)
			return false;

		return true;
	}
}
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Rice.Math.MathStatics;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;

// Used by the player that is carrying the other player
class UMagneticPlayerAttractionPerchMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionPerchMovementCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 91;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UHazeCrumbComponent CrumbComponent;

	UMagneticPlayerComponent MagneticPlayerComponent;
	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;
	UMagneticPlayerAttractionComponent OtherPlayerMagneticPlayerAttraction;
	UHazePlayerLocomotionReplicationComponent PlayerLocomotionReplicationComponent;

	UWindWalkComponent WindWalkComponent;

	// Used to update animation param
	FVector PreviousPlayerForward;
	bool bHasBlockedCapabilities = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);

		MagneticPlayerComponent = UMagneticPlayerComponent::Get(Owner);
		OtherPlayerMagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(Owner);
		PlayerLocomotionReplicationComponent = UHazePlayerLocomotionReplicationComponent::Get(Owner);

		WindWalkComponent = UWindWalkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!OtherPlayerMagneticPlayerAttraction.bIsPiggybacking)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	// Local activation
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		MagneticPlayerAttraction.bIsCarryingPlayer = true;

		PreviousPlayerForward = PlayerOwner.ActorForwardVector;

		// Apply constrained movement settings
		PlayerOwner.ApplySettings(OtherPlayerMagneticPlayerAttraction.PerchedMovementSettings, this);

		// Add locomotion asset and start replicating locomotion requests to piggyback player
		PlayerOwner.AddLocomotionAsset(OtherPlayerMagneticPlayerAttraction.PlayerAttractionPerchAnimationDataAsset.CarryStateMachine, this, 200);
		PlayerLocomotionReplicationComponent.StartRelayAs(EHazePlayerLocomotionReplicationRole::Master);

		// Leave activation crumb
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnActivated"), FHazeDelegateCrumbParams());
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnActivated(const FHazeDelegateCrumbData& CrumbData)
	{
		if(CrumbData.IsStale())
			return;

		bHasBlockedCapabilities = true;
		PlayerOwner.BlockCapabilities(n"AirJump", this);
		PlayerOwner.BlockCapabilities(n"LongJump", this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::Dash, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::Crouch, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::Sprint, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::WallRun, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::Sliding, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::WallSlide, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::GroundPound, this);
		PlayerOwner.BlockCapabilities(MovementSystemTags::WallSlideJump, this);

		PlayerOwner.BlockCapabilities(FMagneticTags::MagneticPlayerAttractionMasterCapability, this);
		PlayerOwner.BlockCapabilities(FMagneticTags::MagneticPlayerAttractionBullshitNetworkChargeCapability, this);

		PlayerOwner.BlockCapabilities(FMagneticTags::PlayerMagnetAnimationCapability, this);
	}

	// Request totem strafe in case player is actuating other magnet
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!PlayerIsActivatingStrafeMagnet())
			return;

		// Don't allow jumping when player is actuating magnet
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		FVector PlayerToMagnet = (MagneticPlayerComponent.ActivatedMagnet.WorldLocation - PlayerOwner.ActorLocation).GetSafeNormal();
		FVector ConstrainedPlayerToMagnet = PlayerToMagnet.ConstrainToPlane(PlayerOwner.MovementWorldUp).GetSafeNormal();

		RequestLocomotion();
		UpdateAnimationParams(PlayerToMagnet, ConstrainedPlayerToMagnet);

		PlayerOwner.MovementComponent.SetTargetFacingDirection(ConstrainedPlayerToMagnet, PlayerOwner.MovementComponent.RotationSpeed);
		PreviousPlayerForward = PlayerOwner.ActorForwardVector;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!OtherPlayerMagneticPlayerAttraction.bIsPiggybacking)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	// Local deactivation
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagneticPlayerAttraction.bIsCarryingPlayer = false;

		// Clear all settings
		PlayerOwner.ClearSettingsByInstigator(this);

		// Remove locomotion asset and stop replicating requests to piggybacking player
		PlayerOwner.ClearLocomotionAssetByInstigator(this);
		PlayerLocomotionReplicationComponent.StopRelay();

		// Leave deactivation crumb
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_OnDeactivated"), FHazeDelegateCrumbParams());
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_OnDeactivated(const FHazeDelegateCrumbData& CrumbData)
	{
		if(!bHasBlockedCapabilities)
			return;

		bHasBlockedCapabilities = false;
		PlayerOwner.UnblockCapabilities(n"AirJump", this);
		PlayerOwner.UnblockCapabilities(n"LongJump", this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::Dash, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::Crouch, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::Sprint, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::WallRun, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::Sliding, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		PlayerOwner.UnblockCapabilities(MovementSystemTags::WallSlideJump, this);

		PlayerOwner.UnblockCapabilities(FMagneticTags::MagneticPlayerAttractionMasterCapability, this);
		PlayerOwner.UnblockCapabilities(FMagneticTags::MagneticPlayerAttractionBullshitNetworkChargeCapability, this);

		PlayerOwner.UnblockCapabilities(FMagneticTags::PlayerMagnetAnimationCapability, this);
	}

	bool PlayerIsActivatingStrafeMagnet() const
	{
		if(MagneticPlayerComponent.ActivatedMagnet == nullptr)
			return false;

		if(!MagneticPlayerComponent.ActivatedMagnet.IsA(UMagneticComponent::StaticClass()))
			return false;

		if(!Cast<UMagneticComponent>(MagneticPlayerComponent.ActivatedMagnet).bUseGenericMagnetAnimation)
			return false;

		return true;
	}

	void RequestLocomotion()
	{
		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = WindWalkComponent.bIsWindWalking ? n"WindWalk" : n"MagnetStrafeTotem";
		LocomotionData.WantedWorldTargetDirection = PlayerOwner.MovementComponent.ActualVelocity;
		LocomotionData.WantedVelocity = PlayerOwner.MovementComponent.ActualVelocity;
		PlayerOwner.RequestLocomotion(LocomotionData);
	}

	void UpdateAnimationParams(const FVector& PlayerToMagnet, const FVector& ConstrainedPlayerToMagnet)
	{
		// Update magnet angle value
		float MagnetAngle = GetAngleBetweenVectorsAroundAxis(PlayerToMagnet, ConstrainedPlayerToMagnet, PlayerOwner.MovementWorldUp.CrossProduct(ConstrainedPlayerToMagnet).GetSafeNormal());
		PlayerOwner.SetAnimFloatParam(n"MagnetAngle", MagnetAngle);

		// Update magnet rotation speed value
		float MagnetYawAngle = -GetAngleBetweenVectorsAroundAxis(ConstrainedPlayerToMagnet, PreviousPlayerForward, PlayerOwner.MovementWorldUp);
		PlayerOwner.SetAnimFloatParam(n"MagnetRotationSpeed", MagnetYawAngle);
	}
}
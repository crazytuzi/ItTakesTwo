import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

// Used by the player that is perching on top
class UMagneticPlayerAttractionPerchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionPerchCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 92;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;

	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;
	UMagneticPlayerAttractionComponent OtherPlayerMagneticAttraction;

	UHazePlayerLocomotionReplicationComponent PlayerLocomotionReplicationComponent;

	UHazeMovementComponent OtherPlayerMovementComponent;

	USceneComponent ComponentOfInterest;

	FHazeCameraClampSettings CameraClamps;
	default CameraClamps.bUseClampYawLeft = true;
	default CameraClamps.bUseClampYawRight = true;

	const float CameraBlendTime = 2.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::GetOrCreate(Owner);
		PlayerLocomotionReplicationComponent = UHazePlayerLocomotionReplicationComponent::Get(Owner);
		OtherPlayerMagneticAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner);

		// Create scene component and place in front of player to use as a point of interest
		ComponentOfInterest = USceneComponent::GetOrCreate(Owner, n"MagneticPlayerAttractionPerchPOI");
		ComponentOfInterest.SetRelativeLocation(FVector(1000.f, 0.f, 200.f));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Perching)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.IsPerchingOnObstacle() || MagneticPlayerAttractionComponent.AttractionLaunchType == EMagneticPlayerAttractionLaunchType::SingleLaunchFail)
			return EHazeNetworkActivation::DontActivate;

		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(FMagneticTags::MagneticEffect, this);
		PlayerOwner.BlockCapabilities(FMagneticTags::MagneticPlayerAttractionBullshitNetworkChargeCapability, this);
		PlayerOwner.BlockCapabilities(FMagneticTags::PlayerMagnetAnimationCapability, this);

		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		OtherPlayerMovementComponent = UHazeMovementComponent::Get(PlayerOwner.OtherPlayer);

		MagneticPlayerAttraction.bIsPiggybacking = true;

		// Play camera shake
		PlayerOwner.PlayCameraShake(MagneticPlayerAttraction.PerchCameraShakeClass, 1.f);

		// Playe rumble effect
		PlayerOwner.PlayForceFeedback(MagneticPlayerAttraction.PerchForceFeedback, false, false, FMagneticTags::MagneticPlayerAttractionPerchCapability);

		// Clear previous locmotion magnet asset and add the piggyback one
		PlayerOwner.ClearLocomotionAssetByInstigator(MagneticPlayerAttraction);
		PlayerOwner.AddLocomotionAsset(MagneticPlayerAttraction.PlayerAttractionPerchAnimationDataAsset.PiggybackStateMachine, this);

		// Attach player mesh to other player's totem bone
		PlayerOwner.Mesh.AttachTo(PlayerOwner.OtherPlayer.Mesh, n"Totem", EAttachLocation::SnapToTarget, false);

		// Fire blueprint event
		FVector PerchLocation = PlayerOwner.OtherPlayer.Mesh.GetSocketLocation(n"Totem");
		MagneticPlayerAttraction.OnMagneticPlayerPerchingStartedEvent.Broadcast(PlayerOwner, PerchLocation);
		OtherPlayerMagneticAttraction.OnMagneticPlayerPerchingStartedEvent.Broadcast(PlayerOwner, PerchLocation);

		// Initialize locomotion request replication as slave
		// (replicate the movement request of the other player that is carrying us)
		PlayerLocomotionReplicationComponent.StartRelayAs(EHazePlayerLocomotionReplicationRole::Slave);

		// Place player's actor where other player's actor
		PlayerOwner.SmoothSetLocationAndRotation(PlayerOwner.OtherPlayer.ActorLocation, PlayerOwner.OtherPlayer.ActorRotation);

		// Bring camera closer
		PlayerOwner.ApplyIdealDistance(600, CameraBlendTime, this);
		PlayerOwner.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, 200.f), CameraBlendTime, this);

		// Apply point of interest
		FHazePointOfInterest PointOfInterest;
		PointOfInterest.Duration = -1.f;
		PointOfInterest.Clamps = CameraClamps;
		PointOfInterest.Blend = CameraBlendTime;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::Object;
		PointOfInterest.FocusTarget.Component = ComponentOfInterest;
		PlayerOwner.ApplyClampedPointOfInterest(PointOfInterest, this);

		// Fire perch event
		UMagneticPlayerComponent::Get(Owner).PlayerMagnet.OnMPAPerchStarted.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		// Replicate other player's movement on this player's ghost actor
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(FMagneticTags::MagneticPlayerAttractionPerchCapability);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);

		FVector MoveDelta = PlayerOwner.OtherPlayer.Mesh.GetSocketLocation(n"Totem") - PlayerOwner.ActorLocation;
		MoveData.ApplyDelta(MoveDelta);
		MoveData.SetRotation(PlayerOwner.OtherPlayer.ActorRotation.Quaternion());

		MoveComp.Move(MoveData);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::Perching)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(FMagneticTags::MagneticEffect, this);
		PlayerOwner.UnblockCapabilities(FMagneticTags::MagneticPlayerAttractionBullshitNetworkChargeCapability, this);
		PlayerOwner.UnblockCapabilities(FMagneticTags::PlayerMagnetAnimationCapability, this);

		MagneticPlayerAttraction.bIsPiggybacking = false;

		// Clear camera stuff
		PlayerOwner.ClearIdealDistanceByInstigator(this);
		PlayerOwner.ClearCameraOffsetOwnerSpaceByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(this);

		// Clear asset and reset animation data component
		PlayerOwner.ClearLocomotionAssetByInstigator(this);
		AnimationDataComponent.Reset();

		// Detach player mesh from other player and reattach to its mesh offset component
		PlayerOwner.Mesh.DetachFromComponent(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		PlayerOwner.Mesh.AttachToComponent(PlayerOwner.MeshOffsetComponent);

		// Stop locomotion replication
		PlayerLocomotionReplicationComponent.StopRelay();

		// Fire blueprint event
		FVector PerchLocation = PlayerOwner.OtherPlayer.Mesh.GetSocketLocation(n"Totem");
		MagneticPlayerAttraction.OnMagneticPlayerPerchingEndedEvent.Broadcast(PlayerOwner, PerchLocation);
		OtherPlayerMagneticAttraction.OnMagneticPlayerPerchingEndedEvent.Broadcast(PlayerOwner, PerchLocation);
	}
}
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;

class UMagneticPlayerAttractionSingleLaunchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionSingleLaunchCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent PlayerMagnet;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;

	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;
	UNiagaraComponent TrailEffect;

	FVector InitialLaunchDirection;

	const float LaunchDuration = 0.4f;
	const float MinLaunchSpeed = 3000.f;

	float LaunchSpeed;
	float InitialDistanceToPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnet = UMagneticPlayerComponent::Get(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Launching)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.AttractionLaunchType != EMagneticPlayerAttractionLaunchType::SingleLaunch)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);

		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);

		InitialDistanceToPlayer = PlayerOwner.GetActorLocation().Distance(PlayerOwner.OtherPlayer.GetActorLocation());
		InitialLaunchDirection = GetAttributeVector(n"PlayerToOtherPlayer");

		LaunchSpeed = FMath::Max(MinLaunchSpeed, InitialDistanceToPlayer / LaunchDuration);

		AnimationDataComponent.bIsLaunching = true;

		FocusCameraOnOtherPlayer();

		// Spawn vfx trail
		TrailEffect = Niagara::SpawnSystemAttached(MagneticPlayerAttraction.TrailEffect, PlayerOwner.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		// Fire launch event
		PlayerMagnet.PlayerMagnet.OnMPALaunch.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement() || MagneticPlayerAttraction.bLaunchingIsDone)
			return;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagneticPlayerAttractionSingleLaunch");
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

		FVector PlayerToOtherPlayer = PlayerOwner.OtherPlayer.Mesh.GetSocketLocation(n"Totem") - PlayerOwner.GetActorLocation();
		FVector LaunchDirection = PlayerToOtherPlayer.GetSafeNormal();

		// Update launch progress
		float Travelled = 1.f - Math::Saturate(PlayerToOtherPlayer.Size() / InitialDistanceToPlayer);
		PlayerMagnet.PlayerMagnet.MagnetLaunchProgress = Travelled;

		// Slow down remote side if it has reached player
		FVector DeltaMove = LaunchDirection * LaunchSpeed * DeltaTime;
		if(!HasControl() && PlayerReachedOtherPlayer())
			DeltaMove = PlayerToOtherPlayer * DeltaTime * 10.f;

		MoveData.ApplyDelta(DeltaMove);
		MoveData.SetRotation(LaunchDirection.ToOrientationQuat());

		MoveCharacter(MoveData, n"MagnetAttract");

		// Rotate mesh offset to match direction
		PlayerOwner.MeshOffsetComponent.OffsetRotationWithTime(LaunchDirection.Rotation(), 0.1f);

		// Handle force feedback and camera shake
		MagneticPlayerAttraction.PlayLaunchCameraShakeAndForceFeedback(PlayerOwner, Travelled * 0.5f);

		if(HasControl() && PlayerReachedOtherPlayer())
			MagneticPlayerAttraction.bLaunchingIsDone = true;
	}

	UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::Launching)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);

		// Start moving toward attachment point
		FVector NextPlayerLocation = PlayerOwner.OtherPlayer.Mesh.GetSocketLocation(n"Totem");
		PlayerOwner.SmoothSetLocationAndRotation(NextPlayerLocation, PlayerOwner.OtherPlayer.ActorForwardVector.Rotation());

		// Reset rotation offset
		PlayerOwner.MeshOffsetComponent.ResetRotationWithTime(0.f);

		MoveComp.SetVelocity(MoveComp.GetVelocity() * 0.2f);

		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(this);

		// Clear locomotion stuff if we left the system
		if(MagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::Inactive)
		{
			PlayerOwner.ClearLocomotionAssetByInstigator(MagneticPlayerAttraction);
			AnimationDataComponent.Reset();
		}

		TrailEffect.Deactivate();

		MagneticPlayerAttraction.bLaunchingIsDone = true;

		MagneticPlayerAttraction = nullptr;
	}

	void FocusCameraOnOtherPlayer()
	{
		FHazePointOfInterest PointOfInterest;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::Object;
		PointOfInterest.FocusTarget.Actor = PlayerOwner.OtherPlayer;
		PointOfInterest.Blend = LaunchDuration;

		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);
		PlayerOwner.ApplyCameraSettings(MagneticPlayerAttraction.SingleLaunchCameraSettings, FHazeCameraBlendSettings(LaunchDuration), this);
	}

	bool PlayerReachedOtherPlayer() const
	{
		if(PlayerOwner.GetActorLocation().Distance(PlayerOwner.OtherPlayer.GetActorCenterLocation()) < 200.f)
			return true;

		// Player flew past other player
		FVector PlayerToOtherPlayer = (PlayerOwner.OtherPlayer.Mesh.GetSocketLocation(n"Totem") - PlayerOwner.ActorLocation).GetSafeNormal();
		if(InitialLaunchDirection.DotProduct(PlayerToOtherPlayer) < 0.f)
			return true;

		return false;
	}
}

import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

class UMagneticPlayerAttractionSingleLaunchFailAndPerchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionSingleLaunchFailCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent PlayerMagnet;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;

	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;
	UMagneticPlayerAttractionComponent OtherPlayerMagneticPlayerAttraction;

	UNiagaraComponent TrailEffect;

	FVector LaunchDirection;
	FVector TargetLocation;

	const FRotator LocalAnimationRotationCompensation = FRotator(90.f, 0.f, 0.f);

	const float LaunchDuration = 0.4f;
	const float MinLaunchSpeed = 3000.f;

	float LaunchSpeed;
	float InitialDistanceToObstacle;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnet = UMagneticPlayerComponent::Get(Owner);
		OtherPlayerMagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Launching && MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Perching)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.AttractionLaunchType != EMagneticPlayerAttractionLaunchType::SingleLaunchFail)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.BreakableObstacle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);

		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		TargetLocation = MagneticPlayerAttraction.BreakableObstaclePerchPointLocation;

		InitialDistanceToObstacle = PlayerOwner.ActorLocation.Distance(TargetLocation);
		LaunchDirection = (TargetLocation - PlayerOwner.ActorLocation).GetSafeNormal();
		LaunchSpeed = FMath::Max(MinLaunchSpeed, InitialDistanceToObstacle / LaunchDuration);

		AnimationDataComponent.bIsLaunching = true;

		MagneticPlayerAttraction.BreakableObstacle.OnBrokenEvent.AddUFunction(this, n"OnObstacleBroken");

		FocusCameraOnOtherPlayer();

		// VFX engage!
		TrailEffect = Niagara::SpawnSystemAttached(MagneticPlayerAttraction.TrailEffect, PlayerOwner.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		// Fire launch event
		PlayerMagnet.PlayerMagnet.OnMPALaunch.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagneticPlayerAttractionSingleLaunchFail");
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

		// Update launch progress
		const float DistanceToTarget = PlayerOwner.ActorLocation.Distance(TargetLocation);
		const float Travelled = 1.f - Math::Saturate(DistanceToTarget / InitialDistanceToObstacle);
		PlayerMagnet.PlayerMagnet.MagnetLaunchProgress = Travelled;

		// Launch towards obstacle
		if(!MagneticPlayerAttraction.bIsPerchingOnObstacle)
		{
			const FVector MoveDelta = LaunchDirection * LaunchSpeed * DeltaTime;
			const FVector NextLocation = PlayerOwner.ActorLocation + MoveDelta;
			const FVector NextLocationToTarget = (TargetLocation - NextLocation).GetSafeNormal();

			const bool bWillFlyPastTarget = NextLocationToTarget.DotProduct(LaunchDirection) <= 0.f;

			// Are we there yet?
			if(TargetLocation.Distance(NextLocation) < 100.f || bWillFlyPastTarget)
				PerchOnObstacle();
			else
				MoveData.ApplyDelta(MoveDelta);

			MoveData.SetRotation(LaunchDirection.ToOrientationQuat());

			// Play launch rumble and camera shake
			MagneticPlayerAttraction.PlayLaunchCameraShakeAndForceFeedback(PlayerOwner, 0.25f);
		}
		else
		{
			// Move towards perch point and clamp since we don't want no weird shit, no siree
			FVector DeltaMove = (TargetLocation - PlayerOwner.ActorLocation) * DistanceToTarget;
			DeltaMove = DeltaMove.GetClampedToMaxSize(1000.f);
			MoveData.ApplyDelta(DeltaMove * DeltaTime);
			MoveData.SetRotation((-MagneticPlayerAttraction.BreakableObstaclePerchPointNormal).ToOrientationQuat());

			// Check if other player is smashin'
			if(OtherPlayerMagneticPlayerAttraction.IsPerchingOnObstacle() && HasControl())
			{
				MagneticPlayerAttraction.NetSetIsReadyToSmashBreakable(true);
			}
		}

		// Can I haz moevment
		MoveCharacter(MoveData, n"MagnetAttract");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::Inactive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::LeavingPerch)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::DoubleLaunchStun)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);

		// Move player downwards to compensate for animation's rotation and location offset
		FVector Binormal = MagneticPlayerAttraction.BreakableObstaclePerchPointNormal.CrossProduct(PlayerOwner.ActorUpVector).GetSafeNormal();
		Binormal = MagneticPlayerAttraction.BreakableObstaclePerchPointNormal.CrossProduct(Binormal);
		PlayerOwner.SmoothSetLocationAndRotation(PlayerOwner.ActorLocation + Binormal * 120.f, PlayerOwner.ActorRotation);

		// Remove roation offset
		PlayerOwner.MeshOffsetComponent.ResetRotationWithTime();

		// Clean camera stuff
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(this);

		TrailEffect.Deactivate();

		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		MagneticPlayerAttraction.bIsPerchingOnObstacle = false;
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

	void PerchOnObstacle()
	{
		// Match animation rotation with obstacle's
		PlayerOwner.MeshOffsetComponent.OffsetRotationWithTime((-MagneticPlayerAttraction.BreakableObstaclePerchPointNormal).Rotation() + LocalAnimationRotationCompensation);

		MagneticPlayerAttraction.bIsPerchingOnObstacle = true;
		MagneticPlayerAttraction.bLaunchingIsDone = true;

		// Update animation state
		AnimationDataComponent.bIsLaunching = false;
		AnimationDataComponent.bIsEnteringPerch = true;

		// Play camera shake and rumble
		PlayerOwner.PlayCameraShake(MagneticPlayerAttraction.PerchCameraShakeClass, 1.f);
		PlayerOwner.PlayForceFeedback(MagneticPlayerAttraction.PerchForceFeedback, false, false, FMagneticTags::MagneticPlayerAttractionSingleLaunchFailCapability);

		// Play audio trigger when touching obstacle
		if(!OtherPlayerMagneticPlayerAttraction.IsPerchingOnObstacle())
			MagneticPlayerAttraction.BreakableObstacle.PerchHit();

		// Fire perch event
		PlayerMagnet.PlayerMagnet.OnMagnetPerchStarted.Broadcast();
	}

	UFUNCTION()
	void OnObstacleBroken(UBreakableComponent BreakableComponent)
	{
		MagneticPlayerAttraction.bIsPerchingOnObstacle = false;
	}
}
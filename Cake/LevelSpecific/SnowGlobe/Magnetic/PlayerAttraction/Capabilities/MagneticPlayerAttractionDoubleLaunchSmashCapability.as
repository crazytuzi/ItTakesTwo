import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

class UMagneticPlayerAttractionDoubleLaunchSmashCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionDoubleLaunchSmashCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent PlayerMagnet;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;

	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;

	UNiagaraComponent TrailEffect;
	UNiagaraComponent MeetCollisionEffect;

	AMagneticPlayerAttractionBreakableObstacle BreakableObstacle;

	FVector LaunchDirection;
	FVector LaunchTarget;

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
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Launching)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.AttractionLaunchType != EMagneticPlayerAttractionLaunchType::DoubleLaunchSmash)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.bLaunchingIsDone)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.BreakableObstacle == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		BreakableObstacle = MagneticPlayerAttraction.BreakableObstacle;
		LaunchTarget = MagneticPlayerAttraction.BreakableObstaclePerchPointLocation;

		InitialDistanceToObstacle = PlayerOwner.ActorLocation.Distance(LaunchTarget);
		LaunchDirection = (LaunchTarget - PlayerOwner.ActorLocation).GetSafeNormal();

		LaunchSpeed = FMath::Min(InitialDistanceToObstacle / LaunchDuration, 6000.f);

		AnimationDataComponent.bIsLaunching = true;

		FocusCameraOnOtherPlayer();
		TrailEffect = Niagara::SpawnSystemAttached(MagneticPlayerAttraction.TrailEffect, PlayerOwner.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		// Fire launch event
		PlayerMagnet.PlayerMagnet.OnMPALaunch.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement() || MagneticPlayerAttraction.bLaunchingIsDone)
			return;

		if(!ensure(InitialDistanceToObstacle != 0.f))
			return;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagneticPlayerAttractionDoubleLaunchSmash");
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

		// Update launch progress
		float DistanceToTarget = PlayerOwner.ActorLocation.Distance(LaunchTarget);
		float Travelled = 1.f - Math::Saturate(DistanceToTarget / InitialDistanceToObstacle);
		PlayerMagnet.PlayerMagnet.MagnetLaunchProgress = Travelled;

		FVector MoveDelta = LaunchDirection * LaunchSpeed * MagneticPlayerAttraction.LaunchSpeedCurve.GetFloatValue(Travelled) * DeltaTime;
		FVector NextLocation = PlayerOwner.ActorLocation + MoveDelta;
		FVector NextLocationToMeetingPoint = (LaunchTarget - NextLocation).GetSafeNormal();

		const bool bWillFlyPastTarget = NextLocationToMeetingPoint.DotProduct(LaunchDirection) <= 0.f;

		if(LaunchTarget.Distance(NextLocation) < 100.f || bWillFlyPastTarget)
		{
			MoveData.ApplyDelta(FVector::ZeroVector);
			MagneticPlayerAttraction.bLaunchingIsDone = true;
		}
		else
		{
			MoveData.ApplyDelta(MoveDelta);
		}

		MoveData.SetRotation(LaunchDirection.ToOrientationQuat());
		MoveData.ApplyTargetRotationDelta();

		MoveCharacter(MoveData, n"MagnetAttract");

		// Handle force beedback and camera shake
		float ForceFeedbackValue = Math::Saturate(BreakableObstacle.GetDistanceTo(PlayerOwner) / InitialDistanceToObstacle) * 0.5f;
		MagneticPlayerAttraction.PlayLaunchCameraShakeAndForceFeedback(PlayerOwner, ForceFeedbackValue);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// Failsafe in case we miss
		if(PlayerOwner.ActorForwardVector.DotProduct((LaunchTarget - PlayerOwner.ActorLocation).GetSafeNormal()) < 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MagneticPlayerAttraction.bLaunchingIsDone)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BreakableObstacle.Break(PlayerOwner.MovementWorldUp);

		PlayerOwner.SmoothSetLocationAndRotation(LaunchTarget, LaunchDirection.Rotation());

		MoveComp.SetVelocity(FVector::ZeroVector);
		PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.ClearCameraOffsetByInstigator(this);
		PlayerOwner.ClearPivotOffsetByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(this);

		TrailEffect.Deactivate();

		// Spawn sweet ass particles
		FVector PlayerToOtherPlayer = (PlayerOwner.OtherPlayer.ActorLocation - PlayerOwner.ActorLocation).GetSafeNormal();
		FRotator ParticleRotation = PlayerToOtherPlayer.CrossProduct(PlayerOwner.MovementWorldUp).Rotation();
		MagneticPlayerAttraction.OnBothPlayersAttractedEvent.Broadcast(FMath::Lerp(PlayerOwner.ActorLocation, PlayerOwner.OtherPlayer.ActorLocation, 0.5f), ParticleRotation, true);

		// Clear vars
		MagneticPlayerAttraction.BreakableObstacle = nullptr;
		MagneticPlayerAttraction.bLaunchingIsDone = true;
		MagneticPlayerAttraction = nullptr;
	}

	void FocusCameraOnOtherPlayer()
	{
		FHazePointOfInterest PointOfInterest;
		PointOfInterest.FocusTarget.Type = EHazeFocusTargetType::Object;
		PointOfInterest.FocusTarget.Actor = PlayerOwner.OtherPlayer;
		PointOfInterest.Blend = 0.5f;

		PlayerOwner.ApplyPointOfInterest(PointOfInterest, this);

		FHazeCameraBlendSettings CameraBlend = FHazeCameraBlendSettings(1.f);
		PlayerOwner.ApplyCameraSettings(MagneticPlayerAttraction.DoubleLaunchCameraSettings, CameraBlend, this);
		PlayerOwner.ApplyCameraOffsetOwnerSpace(MagneticPlayerAttraction.DoubleLaunchCameraSettings.SpringArmSettings.CameraOffsetOwnerSpace * (!PlayerOwner.IsCody() ? FVector::OneVector : FVector(1.f, -1.f, 1.f)), CameraBlend, this);
		PlayerOwner.ApplyPivotOffset(MagneticPlayerAttraction.DoubleLaunchCameraSettings.SpringArmSettings.PivotOffset * (PlayerOwner.IsCody() ? FVector::OneVector : FVector(1.f, -1.f, 1.f)), CameraBlend, this);
	}
}

import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UMagneticPlayerAttractionDoubleLaunchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionDoubleLaunchCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent PlayerMagnet;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;

	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;

	UNiagaraComponent TrailEffect;
	UNiagaraComponent MeetCollisionEffect;

	FVector MeetingPoint;
	FVector InitialLaunchDirection;

	const float LaunchSpeed = 6000.f;
	float InitialDistanceToTarget;

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

		if(MagneticPlayerAttractionComponent.AttractionLaunchType != EMagneticPlayerAttractionLaunchType::DoubleLaunch)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.bLaunchingIsDone)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		MeetingPoint = MagneticPlayerAttraction.DoubleLaunchMeetingPoint;

		InitialDistanceToTarget = PlayerOwner.GetActorLocation().Distance(MeetingPoint);
		InitialLaunchDirection = GetAttributeVector(n"PlayerToOtherPlayer");

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

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagneticPlayerAttractionDoubleLaunch");
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

		FVector PlayerToMeetingPoint = MeetingPoint - PlayerOwner.GetActorLocation();
		FVector LaunchDirection = PlayerToMeetingPoint.GetSafeNormal();

		// Update launch progress
		float DistanceToTarget = PlayerOwner.GetActorLocation().Distance(MeetingPoint);
		float Travelled = 1.f - Math::Saturate(DistanceToTarget / InitialDistanceToTarget);
		PlayerMagnet.PlayerMagnet.MagnetLaunchProgress = Travelled;

		FVector DeltaMove = LaunchDirection * LaunchSpeed * MagneticPlayerAttraction.LaunchSpeedCurve.GetFloatValue(Travelled) * DeltaTime;
		if(!HasControl() && PlayerReachedMeetingPoint())
		{
			// If remote side is already there, start playing stun animation
			DeltaMove = PlayerToMeetingPoint * DeltaTime;
			AnimationDataComponent.bBothPlayersColliding = true;
		}

		MoveData.ApplyDelta(DeltaMove);

		MoveData.SetRotation(LaunchDirection.ToOrientationQuat());
		MoveData.ApplyTargetRotationDelta();

		MoveCharacter(MoveData, n"MagnetAttract");

		// Handle force feedback
		float FeedbackValue = PlayerToMeetingPoint.Size() / InitialDistanceToTarget * 0.5f;
		MagneticPlayerAttraction.PlayLaunchCameraShakeAndForceFeedback(PlayerOwner, FeedbackValue);
	}

	UFUNCTION(BlueprintOverride) 
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(HasControl() && PlayerReachedMeetingPoint())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MagneticPlayerAttraction.bLaunchingIsDone)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::Launching)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FVector DeactivationLocation = MeetingPoint - InitialLaunchDirection * MagneticPlayerAttraction.DoubleLaunchFinalDistanceFromPlayer;
		PlayerOwner.SmoothSetLocationAndRotation(DeactivationLocation, InitialLaunchDirection.Rotation());

		MoveComp.SetVelocity(FVector::ZeroVector);
		ConsumeAction(ActionNames::PrimaryLevelAbility);

		PlayerOwner.ClearPointOfInterestByInstigator(this);
		PlayerOwner.ClearPivotOffsetByInstigator(this);
		PlayerOwner.ClearCameraOffsetOwnerSpaceByInstigator(this);
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		AnimationDataComponent.Reset();

		TrailEffect.Deactivate();

		// Spawn sweet ass particles
		FVector PlayerToOtherPlayer = (PlayerOwner.OtherPlayer.ActorLocation - PlayerOwner.ActorLocation).GetSafeNormal();
		FRotator ParticleRotation = PlayerToOtherPlayer.CrossProduct(PlayerOwner.MovementWorldUp).Rotation();
		MagneticPlayerAttraction.OnBothPlayersAttractedEvent.Broadcast(MeetingPoint, ParticleRotation, false);

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
	
	bool PlayerReachedMeetingPoint() const
	{
		if(PlayerOwner.GetActorLocation().Distance(MeetingPoint) < 200.f)
			return true;

		// Player flew past meeting point
		FVector PlayerToMeetingPoint = (MeetingPoint - PlayerOwner.GetActorCenterLocation()).GetSafeNormal();
		if(InitialLaunchDirection.DotProduct(PlayerToMeetingPoint) < 0.f)
			return true;

		return false;
	}
}

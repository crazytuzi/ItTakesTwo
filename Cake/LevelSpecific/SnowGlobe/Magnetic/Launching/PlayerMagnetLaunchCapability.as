
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetPerchAndBoostPlatform;
import Vino.Pickups.PlayerPickupComponent;
import Effects.PostProcess.PostProcessing;

UCLASS(Abstract)
class UPlayerMagnetLaunchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);

	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunch);
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetLaunchCapability);

	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 190;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset LaunchCamSettings;

	UPROPERTY()
	UNiagaraSystem BlueTrailEffect;

	UPROPERTY()
	UNiagaraSystem RedTrailEffect;

	UPROPERTY()
	UCurveFloat LaunchAccelerationCurve;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LaunchCameraShakeClass;
	UCameraShakeBase LaunchCameraShake;

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerComponent MagneticPlayerComponent;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;
	UMagneticPerchAndBoostComponent MagnetPerch;
	UPlayerPickupComponent PickupComponent;

	UPostProcessingComponent PostProcessingComponent;
	UNiagaraComponent TrailEffect;

	float ElapsedTime = 0.f;
	float InitialDistanceToMagnet;

	bool bShouldDisplaySpeedShimmer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		MagneticPlayerComponent = UMagneticPlayerComponent::GetOrCreate(PlayerOwner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::GetOrCreate(Owner);
		PickupComponent = UPlayerPickupComponent::Get(Owner);
		PostProcessingComponent = UPostProcessingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(FMagneticTags::PlayerMagnetLaunchState))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"CurrentMagnet", MagneticPlayerComponent.GetActivatedMagnet());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		// Initialize variables
		MagnetPerch = Cast<UMagneticPerchAndBoostComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
		InitialDistanceToMagnet = MagnetPerch.GetPlayerPerchPoint(PlayerOwner).Distance(PlayerOwner.GetActorLocation());

		// Fancy vfx engage!
		UNiagaraSystem TrailSystem = PlayerOwner.IsCody() ? RedTrailEffect : BlueTrailEffect;
		TrailEffect = Niagara::SpawnSystemAttached(TrailSystem, PlayerOwner.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		// Set abp state
		AnimationDataComponent.bIsLaunching = true;

		// Push camera settings, if required
		if(MagnetPerch.bAffectCamera)
		{
			UHazeCameraComponent MagnetPerchCameraComponent = UHazeCameraComponent::Get(MagnetPerch.Owner);

			// Aaaand let there be magic!
			// use this to follow player on his way to der magnet
			float LaunchTime = FMath::Sqrt(InitialDistanceToMagnet / MagnetPerch.LaunchSpeed) * (FMath::Sqrt(InitialDistanceToMagnet) * 0.05f);

			// Activate magnet camera (and its settings) as we launch towards perch
			PlayerOwner.ApplyCameraSettings(LaunchCamSettings, LaunchTime, this, EHazeCameraPriority::High);
			PlayerOwner.ApplyIdealDistance(LaunchCamSettings.SpringArmSettings.IdealDistance * Cast<AMagnetBasePad>(MagnetPerch.Owner).PerchCameraDistanceMultiplier, LaunchTime, this);
			PlayerOwner.ActivateCamera(MagnetPerchCameraComponent, LaunchTime, MagnetPerch, EHazeCameraPriority::High);
		}

		// Reset launch progress and fire magnet launch event!
		MagneticPlayerComponent.PlayerMagnet.OnLaunch.Broadcast();
		MagneticPlayerComponent.PlayerMagnet.MagnetLaunchProgress = 0.f;

		// Don't show speed shimmer if player is launching towards magnet shot by cannon (ice wall in town)
		bShouldDisplaySpeedShimmer = !Cast<AMagnetBasePad>(MagnetPerch.Owner).GetShotByCannon();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;
		
		FVector LaunchDirection = (MagnetPerch.GetWorldLocation() - PlayerOwner.ActorLocation).GetSafeNormal();
		float CurrentDistanceToPerch = MagnetPerch.GetPlayerPerchPoint(PlayerOwner).Distance(PlayerOwner.ActorLocation);

		// Update launch progress
		float Travelled = Math::Saturate(1.f - (CurrentDistanceToPerch / InitialDistanceToMagnet));

		if(MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagnetLaunch");
			MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
			MoveData.OverrideStepDownHeight(0.f);
			MoveData.OverrideStepUpHeight(0.f);

			MagneticPlayerComponent.PlayerMagnet.MagnetLaunchProgress = Travelled;

			if(HasControl())
			{
				const FVector MoveDelta = LaunchDirection * MagnetPerch.LaunchSpeed * LaunchAccelerationCurve.GetFloatValue(Travelled) * DeltaTime;
				const FVector NextLocation = PlayerOwner.ActorLocation + MoveDelta;
				const FVector NextLocationToMagnet = (MagnetPerch.GetWorldLocation() - NextLocation).GetSafeNormal();

				const bool bWillFlyPastMagnet = NextLocationToMagnet.DotProduct(LaunchDirection) <= 0.f;

				// Set perching state if player is done launching
				if(MagnetPerch.GetPlayerPerchPoint(PlayerOwner).Distance(NextLocation) < 300.f || bWillFlyPastMagnet)
					PlayerOwner.SetCapabilityActionState(FMagneticTags::PlayerMagnetLaunchPerchState, EHazeActionState::ActiveForOneFrame);

				// Accelerate towards magnet
				MoveData.ApplyDelta(MoveDelta);

				// Handle rotation
				MoveComp.SetTargetFacingDirection(LaunchDirection);
				MoveData.ApplyTargetRotationDelta();

				// Cruuumb ahoy!
				CrumbComp.LeaveMovementCrumb();
			}
			else
			{
				FHazeActorReplicationFinalized CrumbData;
				CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
				MoveData.ApplyConsumedCrumbData(CrumbData);
			}

			// Move dammit!
			MoveCharacter(MoveData, n"MagnetAttract");

			// Force them feedbacks
			PlayerOwner.SetFrameForceFeedback(0.5f, 0.05f);
		}

		// Shimmer my speed!
		if(bShouldDisplaySpeedShimmer)
			PostProcessingComponent.SpeedShimmer = Travelled * 5.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(IsActioning(FMagneticTags::PlayerMagnetLaunchPerchState))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();
		PlayerOwner.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
		MagneticPlayerComponent.PlayerMagnet.MagnetLaunchProgress = 0.f;

		if(DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural)
		{
			// Set reference to magnet perch for launch perch capability to use
			PlayerOwner.SetCapabilityAttributeObject(n"MagnetPerch", MagnetPerch);

			// Set abp state
			AnimationDataComponent.bIsLaunching = false;
			AnimationDataComponent.bIsEnteringPerch = true;

			// When proceeding to perch, start rotating beforehand if this is a wall or a slightly angled ground platform
			if(!MagnetPerch.IsCeilingPerch() && !MagnetPerch.IsPerfectGroundPerch())
			{
				FQuat ImpactNormalQuat = Math::MakeQuatFromX(UMeshComponent::Get(MagnetPerch.Owner).GetWorldRotation().Quaternion().GetAxisX());
					FRotator PerchRotation = ImpactNormalQuat.Rotator() + FRotator(90, 0, 180);
				PlayerOwner.MeshOffsetComponent.OffsetRotationWithTime(PerchRotation, 0.1f);
			}
		}
		else
		{
			PlayerOwner.DeactivateCameraByInstigator(MagnetPerch, 0.5f);
			PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
			PlayerOwner.MeshOffsetComponent.ResetRotationWithSpeed();

			PlayerOwner.ClearLocomotionAssetByInstigator(AnimationDataComponent);
			AnimationDataComponent.Reset();
		}

		// Fire event
		MagneticPlayerComponent.PlayerMagnet.OnLaunchDone.Broadcast();

		// Clean vfx
		TrailEffect.Deactivate();
		PostProcessingComponent.SpeedShimmer = 0.f;

		// Cleanup!
		PlayerOwner.StopCameraShake(LaunchCameraShake);
		PlayerOwner.ClearCameraSettingsByInstigator(this);
		PlayerOwner.ClearPointOfInterestByInstigator(MagnetPerch);
		MagneticPlayerComponent.DeactivateMagnetLockon(MagneticPlayerComponent);

		MagnetPerch = nullptr;

		ElapsedTime = 0.f;
		InitialDistanceToMagnet = 0.f;

		bShouldDisplaySpeedShimmer = false;
	}

	void BlockCapabilities()
	{
		PlayerOwner.BlockCapabilities(FMagneticTags::PlayerMagnetLaunchJumpCapability, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::StickInput, this);
	}

	void UnblockCapabilities()
	{
		PlayerOwner.UnblockCapabilities(FMagneticTags::PlayerMagnetLaunchJumpCapability, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::StickInput, this);
	}
}
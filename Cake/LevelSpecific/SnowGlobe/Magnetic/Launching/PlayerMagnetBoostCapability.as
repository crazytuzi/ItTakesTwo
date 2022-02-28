import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Pickups.PlayerPickupComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetBoostAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.MagnetBasePad;
import Vino.Time.ActorTimeDilationStatics;

UCLASS(Abstract)
class UPlayerMagnetBoostCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"LevelSpecific");
	default CapabilityTags.Add(FMagneticTags::PlayerMagnetBoost);
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 190;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ChargeCamSettings;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UNiagaraSystem BlueTrailEffect;

	UPROPERTY()
	UNiagaraSystem RedTrailEffect;
	UNiagaraComponent CurTrailComp;

	UPROPERTY()
	UForceFeedbackEffect LaunchRumble;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent PlayerMagnetComp;
	UPlayerPickupComponent PickupComp;
	UPlayerMagnetBoostAnimationDataComponent AnimationDataComponent;

	AMagnetBasePad MagnetActor;

	bool bIsLaunching = false;
	bool bSlowMotion = false;
	bool bStartSlowMotionCheck = false;

	float BoostDuration = 0.25f;
	float BoostTimer = 0.0f;

	float MaxBoostActivationTime = 2.0f;

	float ElapsedTime = 0.f;
	float MaxChargeDuration = 0.35f;

	FVector BoostDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnetComp = UMagneticPlayerComponent::GetOrCreate(Player);
		PickupComp = UPlayerPickupComponent::GetOrCreate(Player);
		AnimationDataComponent = UPlayerMagnetBoostAnimationDataComponent::GetOrCreate(Owner);

		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		UMagneticPerchAndBoostComponent CurrentTargetedMagnet = Cast<UMagneticPerchAndBoostComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if(CurrentTargetedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(PlayerMagnetComp.HasOppositePolarity(CurrentTargetedMagnet))
		 	return EHazeNetworkActivation::DontActivate;

		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerMagnetComp.MagnetLockonIsActivatedBy(this))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		UMagneticPerchAndBoostComponent CurrentActiveMagnet = Cast<UMagneticPerchAndBoostComponent>(PlayerMagnetComp.GetActivatedMagnet());
		if(PlayerMagnetComp.HasOppositePolarity(CurrentActiveMagnet))
		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!bIsLaunching && !IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bIsLaunching && MoveComp.IsMovingDownwards())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(bIsLaunching && MoveComp.IsGrounded())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(ElapsedTime >= MaxBoostActivationTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"CurrentMagnet", PlayerMagnetComp.GetTargetedMagnet());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BlockCapabilities();

		UMagneticPerchAndBoostComponent ActivatedMagnet = Cast<UMagneticPerchAndBoostComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);
		MagnetActor = Cast<AMagnetBasePad>(ActivatedMagnet.Owner);

		ApplyCameraSpecifics();

		// Add locomotion asset (state starts at 'charging' by default)
		Player.AddLocomotionAsset(ActivatedMagnet.GetLocomotionStateMachineAsset(Player), this);
		AnimationDataComponent.bIsWallMagnet = ActivatedMagnet.IsWallPerch();

		if(ActivatedMagnet.OverrideBoostDirection == FVector::ZeroVector)
			BoostDirection = ActivatedMagnet.Owner.ActorForwardVector;
		else
			BoostDirection = ActivatedMagnet.OverrideBoostDirection;

		// Smooth teleport player to boost point and face it
		FVector BoostPoint = ActivatedMagnet.GetPlayerBoostPoint(Player);

		// Lerp away!
		float PlayerDistanceToMagnet = ActivatedMagnet.WorldLocation.Distance(Player.ActorLocation);
		float LocationLerpSpeed = PlayerDistanceToMagnet * MaxChargeDuration;
		Player.SmoothSetLocationAndRotation(BoostPoint, (ActivatedMagnet.WorldLocation - Player.ActorLocation).Rotation(), LocationLerpSpeed);

		// Rotate player's mesh to match magnet rotation when dealing with wall type
		if(ActivatedMagnet.IsWallPerch())
			Player.MeshOffsetComponent.OffsetRotationWithTime((-ActivatedMagnet.GetMagneticVector()).Rotation());

		// Fire boost charging event and reset charge progress
		PlayerMagnetComp.PlayerMagnet.OnBoostChargeStarted.Broadcast();
		PlayerMagnetComp.PlayerMagnet.MagnetChargeProgress = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		UnblockCapabilities();

		Player.ClearLocomotionAssetByInstigator(this);
		AnimationDataComponent.Reset();

		Player.MeshOffsetComponent.ResetRotationWithTime();

		// Check if player was still charging
		if(ElapsedTime < MaxChargeDuration)
			PlayerMagnetComp.PlayerMagnet.OnBoostChargeCancelled.Broadcast();

		Player.ClearCameraSettingsByInstigator(this);
		Player.StopAllInstancesOfCameraShake(CamShake, true);
		PlayerMagnetComp.DeactivateMagnetLockon(this);

		MagnetActor = nullptr;

		ElapsedTime = 0.0f;
		bIsLaunching = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		ClearActorTimeDilation(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bStartSlowMotionCheck)
			return;

		if(!bSlowMotion && Player.ActualVelocity.Z < 0 && bIsLaunching)
		{	
			if(PlayerCanHaveSlowMotion())
			{
				bSlowMotion = true;
				ModifyActorTimeDilation(Player, 0.55f, this, false);
			}
			else
			{
				bStartSlowMotionCheck = false;
			}
		}

		if(bSlowMotion)
		{
			BoostTimer += DeltaTime;
			if(WasActionStartedDuringTime(n"MagnetController", 0.1f) || !PlayerCanHaveSlowMotion() || WasActionStartedDuringTime(ActionNames::MovementDash, 0.1f) || BoostTimer >= BoostDuration)
			{
				ClearActorTimeDilation(Player, this);

				bSlowMotion = false;
				bStartSlowMotionCheck = false;
				BoostTimer = 0.0f;
			}
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		// Send animation request
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"PlayerMagnetBoost");
		SendMovementAnimationRequest(MoveData, n"MagnetJump", NAME_None);

		// Check if we should launch already
		ElapsedTime += DeltaTime;
		if (ElapsedTime >= MaxChargeDuration)
		{
			if(!bIsLaunching)
				StartLaunch();
			else if(!bStartSlowMotionCheck)
				bStartSlowMotionCheck = true;
		}
		else
		{
			// Update charge progress
			PlayerMagnetComp.PlayerMagnet.MagnetChargeProgress = Math::Saturate(ElapsedTime / MaxChargeDuration);

			if(HasControl())
				MoveData.SetMoveWithComponent(MagnetActor.Platform);
		}

		Player.SetFrameForceFeedback(0.1f, 0.1f);

		// Move player once we launch from base
		if(bIsLaunching)
		{
			if(HasControl())
			{
				// Set airborne state
				MoveData.OverrideStepUpHeight(0.f);
				MoveData.OverrideStepDownHeight(0.f);
				MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

				// Get player input; lessen maneuverability the closer we are to the boost magnet
				FVector InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection).GetSafeNormal();
				float InputForceMultiplier = FMath::Max(0.f, 1.5f - MoveComp.GetVelocity().Z / ActiveMovementSettings.AirControlLerpSpeed);

				// Go go go!
				FVector Velocity = MoveComp.GetVelocity() + (MoveComp.GetGravity() + InputVector * ActiveMovementSettings.AirControlLerpSpeed * InputForceMultiplier) * DeltaTime;
				MoveData.ApplyDelta(Velocity * DeltaTime);
			}

			// Face velocity vector
			MoveComp.SetTargetFacingRotation(MoveComp.GetVelocity().ToOrientationQuat(), ActiveMovementSettings.AirRotationSpeed);
			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			MoveComp.SetTargetFacingDirection((MagnetActor.ActorLocation - Player.ActorLocation).GetSafeNormal(), 10.f);
			MoveData.ApplyTargetRotationDelta();
		}

		if(!HasControl())
			ConsumeCrumb(MoveData, DeltaTime);

		MoveComp.Move(MoveData);
		CrumbComp.LeaveMovementCrumb();
	}

	void ConsumeCrumb(FHazeFrameMovement& MoveData, const float& DeltaTime)
	{
		FHazeActorReplicationFinalized CrumbData;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
		MoveData.ApplyConsumedCrumbData(CrumbData);
	}

	void ApplyCameraSpecifics()
	{
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = MaxChargeDuration;
		Player.ApplyCameraSettings(ChargeCamSettings, MaxChargeDuration, this);
		Player.PlayCameraShake(CamShake, 3.f);
	}

	void StartLaunch()
	{
		UMagneticPerchAndBoostComponent CurrentActiveMagnet = Cast<UMagneticPerchAndBoostComponent>(PlayerMagnetComp.GetActivatedMagnet());

		// Set ABP State
		AnimationDataComponent.bIsJumping = true;

		// Calculate velocity
		FVector LaunchForce;
		if(PickupComp.IsHoldingObject())
			LaunchForce = BoostDirection * CurrentActiveMagnet.CarryingPickupBoostForce;
		else
			LaunchForce = BoostDirection * CurrentActiveMagnet.BoostLaunchForce;

		LaunchForce += Player.ActorGravity / 2 * -1 * (1 - BoostDirection.DotProduct(FVector::UpVector));

		// Add magnet's inherited velocity
		LaunchForce += MagnetActor.Platform.GetPhysicsLinearVelocity();

		MoveComp.SetVelocity(LaunchForce);

		Player.ClearCameraSettingsByInstigator(this);
		Player.PlayForceFeedback(LaunchRumble, false, true, n"Launch");

		UNiagaraSystem TrailEffect = Player.IsCody() ? RedTrailEffect : BlueTrailEffect;
		CurTrailComp = Niagara::SpawnSystemAttached(TrailEffect, Player.Mesh, n"Hips", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
		System::SetTimer(this, n"HideTrail", 1.f, false);

		// Play vfx
		MagnetActor.PlayBoostEffect();

		bIsLaunching = true;

		// Set magnet boost usage
		CurrentActiveMagnet.UsedBoost();

		// Clear action
		ConsumeAction(ActionNames::PrimaryLevelAbility);

		// Clear mesh offset rotation
		Player.MeshOffsetComponent.ResetRotationWithTime(0.f);

		// Fire boost event and reset charge progress
		PlayerMagnetComp.PlayerMagnet.OnBoost.Broadcast();
		PlayerMagnetComp.PlayerMagnet.MagnetChargeProgress = 0.f;
	}

	bool PlayerCanHaveSlowMotion()
	{
		if(MoveComp.IsGrounded() || UPlayerPickupComponent::Get(Player).IsHoldingObject())
			return false;

		return true;
	}

	UFUNCTION()
	void HideTrail()
	{
		CurTrailComp.Deactivate();
	}

	void BlockCapabilities()
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(FMagneticTags::MagneticEffect, this);
	}

	void UnblockCapabilities()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(FMagneticTags::MagneticEffect, this);
	}
}

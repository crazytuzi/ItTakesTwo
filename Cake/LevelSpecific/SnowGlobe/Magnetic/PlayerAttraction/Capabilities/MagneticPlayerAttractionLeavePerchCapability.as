import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;

class UMagneticPlayerAttractionLeavePerchCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionLeavePerchCapability);

	default TickGroup = ECapabilityTickGroups::ActionMovement;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;

	FMovementCharacterJumpHybridData JumpData;
	FVector HorizontalDirection;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::LeavingPerch)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Clean MPA locomotion asset
		PlayerOwner.ClearLocomotionAssetByInstigator(MagneticPlayerAttraction);
		UPlayerMagnetLaunchAnimationDataComponent::Get(Owner).Reset();

		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		HorizontalDirection = GetAttributeVector(FMagneticTags::MagneticPlayerAttractionLeavePerchHorizontalDirection);

		StartJumpWithInheritedVelocity(JumpData, MoveComp.JumpSettings.AirJumpImpulse);

		// Compensate for sudden crumbing by lerping to first crumb
		if(!HasControl())
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(Time::GlobalWorldDeltaSeconds, CrumbData);
			PlayerOwner.SmoothSetLocationAndRotation(CrumbData.Location, CrumbData.Rotation);
		}

		// Fire jump-from-perch event
		UMagneticPlayerComponent::Get(Owner).PlayerMagnet.OnMPAPerchDone.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(FMagneticTags::MagneticPlayerAttractionLeavePerchCapability);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);

		if(HasControl())
		{
			// Use default jump direction if player hasn't provided input
			FVector InputDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			if(!InputDirection.IsNearlyZero())
				HorizontalDirection = InputDirection;

			MoveData.ApplyDelta(GetHorizontalAirDeltaMovement(DeltaTime, HorizontalDirection, MoveComp.HorizontalAirSpeed));
			MoveData.ApplyAndConsumeImpulses();

			FVector VerticalVelocity = JumpData.CalculateJumpVelocity(DeltaTime, false, MoveComp);
			MoveData.ApplyVelocity(VerticalVelocity);

			MoveComp.SetTargetFacingDirection(HorizontalDirection.GetSafeNormal(), UMovementSettings::GetSettings(PlayerOwner).AirRotationSpeed);
			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			MoveData.ApplyConsumedCrumbData(CrumbData);
		}

		MoveCharacter(MoveData, n"DoubleJump");
		CrumbComp.LeaveMovementCrumb();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::LeavingPerch)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}
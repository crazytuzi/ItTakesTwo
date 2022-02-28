import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Launching.AnimationData.PlayerMagnetLaunchAnimationDataComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;

class UMagneticPlayerAttractionBullshitNetworkChargeCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionBullshitNetworkChargeCapability);

	default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = n"LevelSpecific";

	AHazePlayerCharacter PlayerOwner;
	UPlayerMagnetLaunchAnimationDataComponent AnimationDataComponent;
	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;
	UMagneticPlayerAttractionComponent OtherPlayerMagneticPlayerAttraction;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		OtherPlayerMagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(Owner);
		AnimationDataComponent = UPlayerMagnetLaunchAnimationDataComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(!Network::IsNetworked())
			return EHazeNetworkActivation::DontActivate;

		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		// Avoid spamming
		if(WasActionStartedDuringTime(FMagneticTags::MagnetAttractionJustDeactivated, 0.2f))
			return EHazeNetworkActivation::DontActivate;

		if(OtherPlayerMagneticPlayerAttraction.bIsPiggybacking)
			return EHazeNetworkActivation::DontActivate;

		if(OtherPlayerMagneticPlayerAttraction.bChargingIsDone && !OtherPlayerMagneticPlayerAttraction.IsPerchingOnObstacle())
			return EHazeNetworkActivation::DontActivate;

		UMagneticPlayerAttractionComponent MagneticPlayerAttractionComponent = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
		if(MagneticPlayerAttractionComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.AttractionState != EMagneticPlayerAttractionState::Inactive)
			return EHazeNetworkActivation::DontActivate;

		if(!MagneticPlayerAttractionComponent.IsInfluencedBy(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;

		if(MagneticPlayerAttractionComponent.bIsCarryingPlayer)
			return EHazeNetworkActivation::DontActivate;

		// Don't activate MPA if other player is dying-respawning
		if(UPlayerRespawnComponent::Get(PlayerOwner.OtherPlayer).bIsRespawning || UPlayerHealthComponent::Get(PlayerOwner.OtherPlayer).bIsDead)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);

		PlayerOwner.AddLocomotionAsset(MagneticPlayerAttraction.GetAnimationFeature(), MagneticPlayerAttraction);
		AnimationDataComponent.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.CanCalculateMovement())
			return;

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagneticPlayerAttractionCharge");
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);

		float AccelerationMultiplier = FMath::Square(Math::Saturate(ActiveDuration / 1.f));
		MoveData.ApplyDelta(PlayerOwner.ActorUpVector * 50.f * AccelerationMultiplier * DeltaTime);

		// Slowly start lining up before proper charge capability handles it
		MoveComp.SetTargetFacingDirection((PlayerOwner.OtherPlayer.ActorCenterLocation - PlayerOwner.ActorCenterLocation).GetSafeNormal(), 2.f);
		MoveData.ApplyTargetRotationDelta();

		MoveCharacter(MoveData, n"MagnetAttract");

		PlayerOwner.SetFrameForceFeedback(0.025f, 0.025f);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(OtherPlayerMagneticPlayerAttraction.bChargingIsDone && !OtherPlayerMagneticPlayerAttraction.IsPerchingOnObstacle())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(MagneticPlayerAttraction.AttractionState != EMagneticPlayerAttractionState::Inactive)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		// Don't activate MPA if other player is dying-respawning
		if(UPlayerRespawnComponent::Get(PlayerOwner.OtherPlayer).bIsRespawning || UPlayerHealthComponent::Get(PlayerOwner.OtherPlayer).bIsDead)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(MagneticPlayerAttraction.AttractionState == EMagneticPlayerAttractionState::Inactive)
			PlayerOwner.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
	}
}
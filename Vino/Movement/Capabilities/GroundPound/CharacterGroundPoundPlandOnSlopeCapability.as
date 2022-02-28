import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingStatics;
import Vino.Movement.Capabilities.GroundPound.GroundPoundNames;

class UCharacterGroundPoundLandOnSlopeCapability : UCharacterMovementCapability
{
	default RespondToEvent(GroundPoundEventActivation::Falling);

	default CapabilityTags.Add(GroundPoundTags::Land);
	default CapabilityTags.Add(MovementSystemTags::GroundPound);
	default CapabilityTags.Add(MovementSystemTags::SlopeSlide);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 13;
	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPROPERTY()
	UForceFeedbackEffect RumbleEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	AHazePlayerCharacter PlayerOwner;
	UCharacterGroundPoundComponent GroundPoundComp;
	UCharacterSlidingComponent SlidingComp;
	USlidingSettings SlidingSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
		SlidingComp = UCharacterSlidingComponent::Get(Owner);
		SlidingSettings = USlidingSettings::GetSettings(Owner);

		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (GroundPoundComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SlidingComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
        	return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Falling))
        	return EHazeNetworkActivation::DontActivate;			
		
		if (MoveComp.DownHit.Component != nullptr)
			if (!MoveComp.DownHit.Component.HasTag(ComponentTags::Slideable))
				return EHazeNetworkActivation::DontActivate;

		if (SlidingComp.SlidingVolumeCount >= 1)
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if (GetSlopeAngle(MoveComp.DownHit.Normal, MoveComp.WorldUp) < SlidingSettings.GroundPoundSlopeMinimumAngle)
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::MovementSlide))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return GroundPoundComp.IsGroundPounding();
	}

	
	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		SlidingComp.GroundPoundSlidableVelocity = MoveComp.RequestVelocity;

		SetMutuallyExclusive(MovementSystemTags::GroundPound, true);
		SetMutuallyExclusive(MovementSystemTags::GroundPound, false);
		GroundPoundComp.ResetState();
		PlayerOwner.SetCapabilityActionState(n"GroundPoundedSlope", EHazeActionState::Active);
		PlayerOwner.SetCapabilityActionState(MovementActivationEvents::Grounded, EHazeActionState::Active);
		ConsumeAction(MovementActivationEvents::Airbourne);

		if (CameraShake.IsValid())
			PlayerOwner.PlayCameraShake(CameraShake, 2.f);

		if (RumbleEffect != nullptr)
			PlayerOwner.PlayForceFeedback(RumbleEffect, false, false, n"GroundPoundLand");
	}
}

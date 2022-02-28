
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;
import Vino.Movement.Capabilities.GroundPound.GroundPoundNames;

class UCharacterGroundPoundLandOnWaterCapability : UCharacterMovementCapability
{
	default RespondToEvent(GroundPoundEventActivation::Falling);

	default CapabilityTags.Add(GroundPoundTags::LandOnWater);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 190;
	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPROPERTY()
	UForceFeedbackEffect RumbleEffect;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	AHazePlayerCharacter PlayerOwner;
	UCharacterGroundPoundComponent GroundPoundComp;
	USnowGlobeSwimmingComponent SwimComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Owner);

		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (PlayerOwner.IsMay())
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!GroundPoundComp.IsCurrentState(EGroundPoundState::Falling))
        	return EHazeNetworkActivation::DontActivate;

		PrintToScreen("SwimScore: " + SwimComp.SwimmingScore);
		if (SwimComp.SwimmingScore <= 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		//PlayerOwner.PlayCameraShake(CameraShake, 2.f);
		//PlayerOwner.PlayForceFeedback(RumbleEffect, false, false, n"GroundPoundLand");
		GroundPoundComp.ResetState();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}
}

import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UValidationMovementCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"ValidationMovement");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	bool bStartedAirborne = false;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bStartedAirborne = MoveComp.IsAirborne();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ValidationMovement");

		bool bStayWithTrigger = true;
		FName AnimFeature = FeatureName::Movement;

		if (bStartedAirborne)
			AnimFeature = FeatureName::AirMovement;

		// Determine how validation movement works from the trigger we are in
		UHazeTriggerComponent Trigger = Cast<UHazeTriggerComponent>(GetAttributeObject(n"ValidatingTrigger"));
		if (Trigger != nullptr)
		{
			switch (Trigger.MovementMethod)
			{
				case EHazeMovementMethod::JumpTo:
					AnimFeature = FeatureName::AirMovement;
				break;
				case EHazeMovementMethod::Disabled:
					bStayWithTrigger = false;
				break;
			}
		}

		// Make sure the player stays at the spot that we moved to while we are validating
		if (bStayWithTrigger)
		{
			FrameMove.ApplyDeltaWithCustomVelocity(
				(Trigger.MovementDestination.Location - Owner.ActorLocation),
				FVector::ZeroVector
			);
			FrameMove.SetRotation(Trigger.MovementDestination.Rotation);
		}

		// Don't collide with anything while validating
		FrameMove.OverrideCollisionProfile(n"PlayerCharacterOverlapOnly");

		MoveCharacter(FrameMove, AnimFeature);
	};
};
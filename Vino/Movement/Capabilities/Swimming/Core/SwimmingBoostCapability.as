// import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
// import Vino.Movement.Components.MovementComponent;
// import Vino.Trajectory.TrajectoryStatics;
// import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
// import Vino.Movement.Capabilities.Swimming.SnowGlobeStopSwimmingVolume;
// import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

// class USwimmingBoostCapability : UHazeCapability
// {
// 	default CapabilityTags.Add(CapabilityTags::Movement);
// 	default CapabilityTags.Add(MovementSystemTags::Swimming);
// 	default CapabilityTags.Add(SwimmingTags::Underwater);
// 	default CapabilityTags.Add(SwimmingTags::Boost);

// 	default CapabilityDebugCategory = n"Movement Swimming";
	
// 	default TickGroup = ECapabilityTickGroups::ActionMovement;
// 	default TickGroupOrder = 50;

// 	AHazePlayerCharacter Player;
// 	UHazeMovementComponent MoveComp;
// 	USnowGlobeSwimmingComponent SwimComp;

// 	UPROPERTY()
// 	UForceFeedbackEffect BoostForceFeedback;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
// 		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		if (!SwimComp.bIsInWater)
//         	return EHazeNetworkActivation::DontActivate;

// 		if (SwimComp.SwimmingState != ESwimmingState::Slow && SwimComp.SwimmingState != ESwimmingState::Fast)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (DeactiveDuration < SwimmingSettings.BoostCooldown)
// 			return EHazeNetworkActivation::DontActivate;

// 		if (!WasActionStartedDuringTime(ActionNames::MovementDash, 0.2f))
// 			return EHazeNetworkActivation::DontActivate;

// 		if (GetAttributeVector(AttributeVectorNames::MovementDirection).Size() >= 0.1f || IsActioning(ActionNames::MovementJump) || IsActioning(ActionNames::Cancel))
// 			return EHazeNetworkActivation::ActivateLocal;

//         return EHazeNetworkActivation::DontActivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		return EHazeNetworkDeactivation::DeactivateLocal;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{			
// 		ConsumeAction(ActionNames::MovementDash);
// 		SwimComp.bIsBoosting = true;

// 		FVector ImpulseDirection = MoveComp.GetVelocity().GetSafeNormal();
// 		Player.AddImpulse(ImpulseDirection * SwimmingSettings.BoostImpulse);

// 		if (BoostForceFeedback != nullptr)
// 			Player.PlayForceFeedback(BoostForceFeedback, false, true, n"SwimmingBoost");

// 		// FHazeRequestLocomotionData AnimationRequest;
// 		// AnimationRequest.AnimationTag = n"Swimming";
// 		// AnimationRequest.SubAnimationTag = n"Boost";

// 		// Player.RequestLocomotion(AnimationRequest);

// 		Player.SetAnimBoolParam(n"BoostActivated", true);
// 	}	
// }
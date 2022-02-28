import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.SnowGlobeStopSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USnowGlobeSwimmingDashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::Underwater);
	default CapabilityTags.Add(SwimmingTags::Boost);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;

	UPROPERTY()
	UForceFeedbackEffect BoostForceFeedback;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!SwimComp.bIsInWater)
        	return EHazeNetworkActivation::DontActivate;

		if (SwimComp.SwimmingState != ESwimmingState::Swimming)
			return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < SwimmingSettings::Dash.Cooldown)
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStartedDuringTime(ActionNames::MovementDash, 0.2f))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{			
		ConsumeAction(ActionNames::MovementDash);
		SwimComp.bIsBoosting = true;

		FVector ImpulseDirection = MoveComp.Velocity.GetSafeNormal();
		if (MoveComp.Velocity.IsNearlyZero())
			ImpulseDirection = Owner.ActorForwardVector;
		
		SwimComp.DesiredSpeed = FMath::Min(SwimComp.DesiredSpeed + SwimmingSettings::Dash.DesiredSpeedIncrease, SwimmingSettings::Speed.DesiredCruise);
		SwimComp.DesiredDecayCooldown = SwimmingSettings::Speed.DesiredDecayDelayAfterDash;
		MoveComp.Velocity = (ImpulseDirection * SwimComp.DesiredSpeed) + (ImpulseDirection * SwimmingSettings::Dash.ExtraBoostSpeed);
		SwimComp.UpdateSwimmingSpeedState();

		// Audio: Normal to Fast
		if (SwimComp.AudioData[Player].SubmergedDash != nullptr)
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].SubmergedDash);

		if (BoostForceFeedback != nullptr)
			Player.PlayForceFeedback(BoostForceFeedback, false, true, n"SwimmingBoost");

		FHazeRequestLocomotionData AnimationRequest;
		AnimationRequest.AnimationTag = n"SwimmingDashEnter";
		
		if (MoveComp.CanCalculateMovement())
			Player.RequestLocomotion(AnimationRequest);

		Player.SetAnimBoolParam(n"BoostActivated", true);

		SwimComp.CallOnDash();
	}	
}
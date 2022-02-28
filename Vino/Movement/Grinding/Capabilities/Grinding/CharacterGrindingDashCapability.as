import Vino.Movement.MovementSystemTags;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;
import Vino.Movement.Grinding.GrindSettings;
import Vino.Movement.Components.MovementComponent;

class UCharacterGrindingDashCapability : UHazeCapability
{
	default RespondToEvent(GrindingActivationEvents::Grinding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(MovementSystemTags::Grinding);
	default CapabilityTags.Add(GrindingCapabilityTags::Movement);
	default CapabilityTags.Add(GrindingCapabilityTags::Dash);

	default CapabilityDebugCategory = n"Grinding";	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 120;

	AHazePlayerCharacter Player;
	UUserGrindComponent UserGrindComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		UserGrindComp = UUserGrindComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!UserGrindComp.HasActiveGrindSpline())
        	return EHazeNetworkActivation::DontActivate;

		if (!UserGrindComp.ActiveGrindSpline.bCanDash)
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::MovementDash))
        	return EHazeNetworkActivation::DontActivate;

		if (DeactiveDuration < GrindSettings::Dash.Cooldown)
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
		float SpeedAfterDash = UserGrindComp.CurrentSpeed + GrindSettings::Dash.Impulse;
		UserGrindComp.CurrentSpeed = SpeedAfterDash;

		MoveComp.SetSubAnimationTagToBeRequested(n"Dash");

		if (UserGrindComp.GrindingForceFeedbackData != nullptr && UserGrindComp.GrindingForceFeedbackData.GrindDashRumble != nullptr)
			Player.PlayForceFeedback(UserGrindComp.GrindingForceFeedbackData.GrindDashRumble, false, true, NAME_None);
	}
}

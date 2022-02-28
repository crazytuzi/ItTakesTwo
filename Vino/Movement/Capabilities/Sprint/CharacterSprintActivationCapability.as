import Vino.Movement.MovementSystemTags;
import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
import Vino.Movement.Components.MovementComponent;

class UCharacterSprintActivationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Sprint);
	default CapabilityTags.Add(n"SprintActivation");
	
	default CapabilityDebugCategory = n"Movement";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	UCharacterSprintComponent SprintComp;
	UHazeMovementComponent MoveComp;

	float SprintActioningDuration = 0.f;
	float SprintRequiredActioningTime = 0.15f;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);	
		SprintComp = UCharacterSprintComponent::GetOrCreate(Owner);	
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
    void PreTick(float DeltaTime)	
    {
		// if (IsActioning(ActionNames::MovementSprint))
		// 	SprintActioningDuration += DeltaTime;
		// else
		// 	SprintActioningDuration = 0.f;

		if (WasActionStarted(ActionNames::MovementSprintToggle))
			SprintComp.bSprintToggled = !SprintComp.bSprintToggled;

		// if (Player.IsAnyCapabilityActive(MovementSystemTags::Dash) || Player.IsAnyCapabilityActive(n"AirMovement"))
		// 	return;

		if (MoveComp.IsAirborne() && !MoveComp.BecameAirborne())
			SprintComp.bSprintToggled = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SprintComp.InstigatorsForcingSprint.Num() > 0)
        	return EHazeNetworkActivation::ActivateLocal;
		
		// if (SprintActioningDuration >= SprintRequiredActioningTime)
        // 	return EHazeNetworkActivation::ActivateLocal;

		if (SprintComp.bSprintToggled)
        	return EHazeNetworkActivation::ActivateLocal;
		
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SprintComp.InstigatorsForcingSprint.Num() > 0)
        	return EHazeNetworkDeactivation::DontDeactivate;

		// if (IsActioning(ActionNames::MovementSprint))
        // 	return EHazeNetworkDeactivation::DontDeactivate;

		if (SprintComp.bSprintToggled)
        	return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SprintComp.bShouldSprint = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SprintComp.bShouldSprint = false;
		SprintComp.bSprintToggled = false;
	}
}

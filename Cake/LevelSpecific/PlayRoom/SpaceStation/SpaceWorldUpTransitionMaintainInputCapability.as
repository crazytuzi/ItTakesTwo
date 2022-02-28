import Vino.Movement.Components.MovementComponent;

class USpaceWorldUpTransitionMaintainInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 105;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;

	FVector PreviousWorldUp;
	FVector CurrentWorldUp;

	bool bPositiveWhenActivated = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CurrentWorldUp = MoveComp.WorldUp;
		PreviousWorldUp = MoveComp.WorldUp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(n"SwingingMovement"))
			return EHazeNetworkActivation::DontActivate;

		if (CurrentWorldUp.Z > 0.f && PreviousWorldUp.Z < 0.f)
        	return EHazeNetworkActivation::ActivateFromControl;

		if (CurrentWorldUp.Z < 0.f && PreviousWorldUp.Z > 0.f)
			return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GetAttributeVector(AttributeVectorNames::MovementRaw).Size() == 0.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		const FVector2D PlayerInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		if (bPositiveWhenActivated && PlayerInput.Y < 0.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!bPositiveWhenActivated && PlayerInput.Y > 0.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		bPositiveWhenActivated = Input.Y > 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		PreviousWorldUp = CurrentWorldUp;
		CurrentWorldUp = MoveComp.WorldUp;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Player.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, -GetAttributeVector(AttributeVectorNames::MovementDirection));
	}
}
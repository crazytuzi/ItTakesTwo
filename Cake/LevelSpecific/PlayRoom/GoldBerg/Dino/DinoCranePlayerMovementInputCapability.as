import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCraneRidingComponent;

class UDinoCranePlayerMovementInputCapability : UHazeCapability
{
    default CapabilityTags.Add(CapabilityTags::GameplayAction);
    default CapabilityTags.Add(CapabilityTags::MovementInput);
    default CapabilityTags.Add(CapabilityTags::Input);

	UDinoCraneRidingComponent RideComp;
	UHazeBaseMovementComponent MoveComp;
	AHazePlayerCharacter Player;

	float ActiveTimer = 0.f;
	bool bIsShowingTutorial;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams& Params)
	{
		RideComp = UDinoCraneRidingComponent::GetOrCreate(Owner);
		MoveComp = UHazeBaseMovementComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (RideComp.DinoCrane == nullptr)
		{
            return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (RideComp.DinoCrane == nullptr)
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	void StopTutorial()
	{
		bIsShowingTutorial = false;
	}


    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		ActiveTimer += DeltaTime;

		RideComp.SteeringInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
		RideComp.RawInput = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
		RideComp.VerticalInput = GetAttributeValue(AttributeNames::PrimaryLevelAbilityAxis) - GetAttributeValue(AttributeNames::SecondaryLevelAbilityAxis);
		RideComp.ControlRotation = Owner.GetControlRotation();
		RideComp.bIsBiting = IsActioning(ActionNames::InteractionTrigger) && ActiveTimer > 0.5f && !IsActioning(CapabilityTags::Interaction);


    }
};
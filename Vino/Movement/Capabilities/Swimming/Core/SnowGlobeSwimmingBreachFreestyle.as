import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USnowGlobeSwimmingBreachFreestyleCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::Swimming);
	default CapabilityTags.Add(SwimmingTags::AboveWater);
	default CapabilityTags.Add(SwimmingTags::BreachFreestyle);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SwimComp.SwimmingState != ESwimmingState::Breach)
        	return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::InteractionTrigger))
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SwimComp.SwimmingState != ESwimmingState::Breach)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (WasActionStopped(ActionNames::InteractionTrigger))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		Player.SetAnimBoolParam(n"FreestyleActive", true);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{		
		Player.SetAnimBoolParam(n"FreestyleActive", false);

		Player.SetAnimFloatParam(n"FreestyleX", 0.f);
		Player.SetAnimFloatParam(n"FreestyleY", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Player.SetAnimFloatParam(n"FreestyleX", GetAttributeVector(AttributeVectorNames::MovementRaw).X);
		Player.SetAnimFloatParam(n"FreestyleY", GetAttributeVector(AttributeVectorNames::MovementRaw).Y);
	}	
}
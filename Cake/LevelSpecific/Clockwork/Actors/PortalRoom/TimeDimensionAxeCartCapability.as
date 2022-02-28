import Cake.LevelSpecific.Clockwork.Actors.PortalRoom.TimeDimensionAxeCart;
import Vino.Interactions.InteractionComponent;

class UTimeDimensionAxeCartCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TimeDimensionAxeCartCapability");

	default CapabilityDebugCategory = n"TimeDimensionAxeCartCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	ATimeDimensionAxeCart Cart;
	UInteractionComponent InteractionPoint;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Cart == nullptr)
        	return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Cart == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		UObject CartTemp;
		if (ConsumeAttribute(n"Cart", CartTemp))
		{
			Cart = Cast<ATimeDimensionAxeCart>(CartTemp);
		}
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (IsActioning(ActionNames::Cancel) && Cart != nullptr)
		{
			Cart.DetachFromCart(Player, InteractionPoint);
			Cart = nullptr;
		}
	}
}
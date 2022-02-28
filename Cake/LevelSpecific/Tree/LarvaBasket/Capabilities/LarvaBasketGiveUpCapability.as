import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketGiveUpCapability : UHazeCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 60;

	AHazePlayerCharacter Player;
	ULarvaBasketPlayerComponent BasketComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BasketComp = ULarvaBasketPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!LarvaBasketGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		if (!WasActionStarted(ActionNames::Cancel))
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
		LarvaBasketManager.RequestGiveUp(Player);

		// Leave the game
		BasketComp.CurrentCage = nullptr;
	}
}
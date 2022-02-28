import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketCancelPromptCapability : UHazeCapability
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

		bool bCorrectState = LarvaBasketGameIsIdle() || LarvaBasketGameIsActive();
		if (!bCorrectState)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		bool bCorrectState = LarvaBasketGameIsIdle() || LarvaBasketGameIsActive();
		if (!bCorrectState)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FText GiveUpText = NSLOCTEXT("LarvaBasket", "GiveUp", "Give Up");
		if (LarvaBasketGameIsActive())
			Player.ShowCancelPromptWithText(this, GiveUpText);
		else
			Player.ShowCancelPrompt(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveCancelPromptByInstigator(this);
	}
}
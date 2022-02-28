import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketActiveCapability : UHazeCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

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

		if (LarvaBasketGameIsIdle())
			return EHazeNetworkActivation::DontActivate;

		if (LarvaBasketGameIsFinished())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (LarvaBasketGameIsIdle())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (LarvaBasketGameIsFinished())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (Player.IsMay())
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Player.IsMay())
			Player.ClearViewSizeOverride(this);

		// Leave the game
		BasketComp.CurrentCage = nullptr;
	}
}
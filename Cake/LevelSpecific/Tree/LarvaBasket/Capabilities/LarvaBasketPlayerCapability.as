import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketPlayerComponent;
import Cake.LevelSpecific.Tree.LarvaBasket.LarvaBasketManager;

class ULarvaBasketPlayerCapability : UHazeCapability
{
	default BlockExclusionTags.Add(n"LarvaBasket");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityDebugCategory = n"LarvaBasket";
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ULarvaBasketPlayerComponent BasketComp;
	ALarvaBasketCage Cage;

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

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (BasketComp.CurrentCage == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Cage = BasketComp.CurrentCage;
		Cage.Interaction.Disable(n"Busy");
		Cage.SetPlayerOwner(Player);

		Player.AddLocomotionFeature(BasketComp.Feature[Player]);

		auto Manager = LarvaBasketManager;
		Manager.DoubleInteract.StartInteracting(Player);
		Player.ActivateCamera(Manager.Camera.Camera, CameraBlend::Normal(2.f));

		Player.CleanupCurrentMovementTrail();
		Player.BlockMovementSyncronization(this);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilitiesExcluding(CapabilityTags::GameplayAction, n"LarvaBasket", this);
		Player.BlockCapabilities(ActionNames::WeaponAim, this);
		Player.BlockCapabilities(ActionNames::WeaponFire, this);

		Player.AttachToComponent(Cage.AttachComp, NAME_None, EAttachmentRule::SnapToTarget);
		System::SetTimer(this, n"CheckPendingBark", 2.f, false);
	}

	UFUNCTION()
	void CheckPendingBark()
	{
		if (!IsActive())
			return;

		if (!LarvaBasketGameIsIdle())
			return;

		LarvaBasketPlayPendingBark(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Cage.Interaction.EnableAfterFullSyncPoint(n"Busy");

		Player.RemoveLocomotionFeature(BasketComp.Feature[Player]);

		auto Manager = LarvaBasketManager;
		Player.DeactivateCamera(Manager.Camera.Camera);

		Player.DetachRootComponentFromParent();

		Player.UnblockMovementSyncronization(this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(ActionNames::WeaponAim, this);
		Player.UnblockCapabilities(ActionNames::WeaponFire, this);

		if (BasketComp.HeldBall != nullptr)
		{
			BasketComp.HeldBall.DeactivateBall();
			BasketComp.HeldBall = nullptr;
		}

		if (LarvaBasketGameIsFinished() && HasControl())
			NetPlayReactions();
	}

	UFUNCTION(NetFunction)
	void NetPlayReactions()
	{
		// To make sure both sides do this properly
		if (LarvaBasketManager != nullptr)
			LarvaBasketManager.Minigame.ActivateReactionAnimations(Player);
	}
}
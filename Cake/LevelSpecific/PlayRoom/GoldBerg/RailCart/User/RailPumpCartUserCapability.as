import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent;

class URailPumpCartUserCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::ActiveGameplay);
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::User);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;
	URailPumpCartUserComponent CartUser;

	ARailPumpCart Cart;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CartUser = URailPumpCartUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CartUser.PendingCart == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		CartUser.CurrentCart = CartUser.PendingCart;
		CartUser.bFront = CartUser.bPendingFront;

		CartUser.PendingCart = nullptr;

		Cart = CartUser.CurrentCart;

		Player.CleanupCurrentMovementTrail();
		Player.BlockMovementSyncronization(this);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		FName AttachSocket = CartUser.bFront ? n"FrontSocket" : n"BackSocket";
		Player.AttachToComponent(Cart.Mesh, AttachSocket, EAttachmentRule::SnapToTarget);

		Cart.SetPlayerStartedUsingCart(CartUser.bFront, Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Player.UnblockMovementSyncronization(this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		if (Cart != nullptr)
		{
			Player.DetachRootComponentFromParent();
			Cart.SetPlayerStoppedUsingCart(CartUser.bFront);

			Cart = nullptr;
		}
	}
}
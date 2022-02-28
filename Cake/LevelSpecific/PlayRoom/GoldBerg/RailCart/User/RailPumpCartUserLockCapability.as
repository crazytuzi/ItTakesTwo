import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent;
import Vino.Camera.Components.CameraUserComponent;

class URailPumpCartUserLockCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
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
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!CartUser.CurrentCart.AreBothPlayersOnCart())
			return EHazeNetworkActivation::DontActivate;

		if (CartUser.CurrentCart.bIsLocked)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!CartUser.CurrentCart.AreBothPlayersOnCart())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (CartUser.CurrentCart.bIsLocked)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		CartUser.bIsLocked = true;

		Cart = CartUser.CurrentCart;
		Owner.BlockCapabilities(RailCartTags::Leave, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		CartUser.bIsLocked = false;

		Owner.UnblockCapabilities(RailCartTags::Leave, this);
	}
}
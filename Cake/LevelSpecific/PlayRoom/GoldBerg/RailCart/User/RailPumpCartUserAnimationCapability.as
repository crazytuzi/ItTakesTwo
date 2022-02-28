import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent;

class URailPumpCartUserAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::User);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

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
		Cart = CartUser.CurrentCart;
		Player.AddLocomotionAsset(Player.IsCody() ? Cart.CodyLocomotion : Cart.MayLocomotion, this);

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Player.ClearLocomotionAssetByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"ToyCart";
		Player.RequestLocomotion(Data);
	}
}
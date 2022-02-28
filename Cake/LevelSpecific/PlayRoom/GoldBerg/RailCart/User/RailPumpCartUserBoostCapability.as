import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent;
import Vino.Characters.PlayerCharacter;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class URailPumpCartUserBoostCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::User);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	APlayerCharacter Player;
	URailPumpCartUserComponent CartUser;

	ARailPumpCart Cart;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<APlayerCharacter>(Owner);
		CartUser = URailPumpCartUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!CartUser.CurrentCart.bBoosting)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!CartUser.CurrentCart.bBoosting)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Cart = CartUser.CurrentCart;

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;

		Player.ApplyCameraSettings(Cart.BoostedCameraSettings, Blend, this, EHazeCameraPriority::High);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(1.f, this));
	}
}
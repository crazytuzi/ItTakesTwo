import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailPumpCartPumpWidgetCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ARailPumpCart PumpCart;
	float SyncTime = 0.f;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PumpCart = Cast<ARailPumpCart>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkActivation::DontActivate;

		if (PumpCart.bIsLocked)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (PumpCart.bIsLocked)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Player = PumpCart.BackPlayer;
		PumpCart.Widget = Cast<URailPumpCartWidget>(Player.AddWidget(PumpCart.WidgetClass));
		PumpCart.Widget.AttachWidgetToComponent(PumpCart.WidgetAttach);
		PumpCart.Widget.SetWidgetShowInFullscreen(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Player.RemoveWidget(PumpCart.Widget);
		PumpCart.Widget = nullptr;
		Player = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		PumpCart.Widget.FrontPumpRate = PumpCart.FrontPumpRate;
		PumpCart.Widget.BackPumpRate = PumpCart.BackPumpRate;
		PumpCart.Widget.bIsBoosting = PumpCart.bBoosting;
	}
}
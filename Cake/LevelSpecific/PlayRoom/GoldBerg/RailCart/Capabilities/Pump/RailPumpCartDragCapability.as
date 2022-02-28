import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailPumpCartDragCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Movement);
	default CapabilityTags.Add(RailCartTags::Physics);
	default CapabilityTags.Add(RailCartTags::ManualControl);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ARailPumpCart PumpCart;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PumpCart = Cast<ARailPumpCart>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float DragCoefficient = PumpCart.Speed > 0.f ? RailCart::Speed::Drag_Positive : RailCart::Speed::Drag_Negative;
		PumpCart.Speed -= PumpCart.Speed * DragCoefficient * DeltaTime;
	}
}
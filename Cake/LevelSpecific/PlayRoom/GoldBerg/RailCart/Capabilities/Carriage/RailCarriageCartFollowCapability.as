import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCarriageCart;

class URailCarriageCartFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ARailCarriageCart CarriageCart;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CarriageCart = Cast<ARailCarriageCart>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CarriageCart.FollowCart == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CarriageCart.FollowCart == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeSplineSystemPosition FollowPosition = CarriageCart.FollowCart.Position;
		FollowPosition.Move(-800.f);

		CarriageCart.SetActorTransform(FollowPosition.GetWorldTransform());
		CarriageCart.Speed = CarriageCart.FollowCart.Speed;
		CarriageCart.Position = FollowPosition;
	}
}
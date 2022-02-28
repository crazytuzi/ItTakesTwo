import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCart;

// The carriage cart following the PumpCart. Filled with dynamite :)
class ARailCarriageCart : ARailCart
{
	default Weight = 1.6f;

	UPROPERTY()
	ARailCart FollowCart;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"RailCarriageCartFollowCapability");
		AddCapability(n"RailCartTiltCapability");
		AddCapability(n"RailCartOffsetCapability");
		AddCapability(n"RailCartTransferCapability");

		AddTickPrerequisiteActor(FollowCart);
	}
}
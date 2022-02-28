import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailPumpCartGravityCapability : UHazeCapability
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
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeSplineSystemPosition Position = PumpCart.SplineFollow.GetPosition();

		float SlopeAngle = Math::DotToDegrees(Position.WorldUpVector.DotProduct(FVector::UpVector));
		if (SlopeAngle < RailCart::Speed::MinSlope)
			return;

		FVector Forward = Position.GetWorldForwardVector();
		Forward.Normalize();

		float GravityFactor = Forward.DotProduct(FVector::UpVector);
		PumpCart.Speed -= GravityFactor * 4000.f * DeltaTime;
	}
}
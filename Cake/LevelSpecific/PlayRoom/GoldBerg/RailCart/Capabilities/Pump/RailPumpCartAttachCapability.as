import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

// NOTE: The point of this capability is to re-align the cart to the track after something blocked it 
// 	(most likely a cutscene)
// But at some point, it would be nice to do all attachment logic in here instead of in the actor
class URailPumpCartAttachCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 10;

	ARailPumpCart PumpCart;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PumpCart = Cast<ARailPumpCart>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PumpCart.IsAttachedToSpline())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PumpCart.IsAttachedToSpline())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PumpCart.OffsetComp.FreezeAndResetWithTime(1.2f);
		PumpCart.SplineFollow.UpdateSplineMovement(PumpCart.ActorLocation, PumpCart.Position);
	}
}
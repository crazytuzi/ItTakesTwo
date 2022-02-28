import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCart;

class URailCartTransferCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Movement);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ARailCart Cart;
	UHazeSplineComponentBase AttachedSpline;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cart = Cast<ARailCart>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Cart.IsAttachedToSpline())
		{
			if (AttachedSpline != nullptr)
				return EHazeNetworkActivation::ActivateLocal;
			else
				return EHazeNetworkActivation::DontActivate;
		}

		FHazeSplineSystemPosition Position = Cart.Position;

		if (Position.Spline == AttachedSpline)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		auto Position = Cart.Position;
		auto Spline = Position.Spline;

		// Update actor position
		Cart.AttachToComponent(Spline);

		FTransform SplineTransform = Position.GetRelativeTransform();
		Cart.SetActorRelativeTransform(SplineTransform);
	}
}
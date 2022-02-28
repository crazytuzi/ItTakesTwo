import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailPumpCartPumpCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Movement);
	default CapabilityTags.Add(RailCartTags::Physics);
	default CapabilityTags.Add(RailCartTags::ManualControl);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 50;

	ARailPumpCart PumpCart;
	float SyncTime = 0.f;

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

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		PumpCart.CombinedPumpRate = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			PumpCart.CombinedPumpRate = PumpCart.FrontPumpRate * PumpCart.BackPumpRate;

			if (SyncTime < Time::GetGameTimeSeconds())
			{
				NetSetCombinedPumpRateRate(PumpCart.CombinedPumpRate);
				SyncTime = Time::GameTimeSeconds + 0.2f;
			}
		}

		float AccelFactor = 1.f;
		AccelFactor = 1.f - Math::Saturate(FMath::Abs(PumpCart.Speed) / PumpCart.MaxSpeed);

		PumpCart.Speed += PumpCart.CombinedPumpRate * (AccelFactor * RailCart::Speed::Acceleration) * DeltaTime;
	}

	UFUNCTION(NetFunction)
	void NetSetCombinedPumpRateRate(float CombinedRate)
	{
		PumpCart.CombinedPumpRate = CombinedRate;
	}
}
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailPumpCartBoostFadeCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Movement);
	default CapabilityTags.Add(RailCartTags::Boost);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ARailPumpCart PumpCart;
	float FadeBeginBoost;
	float Time;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PumpCart = Cast<ARailPumpCart>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PumpCart.bBoosting)
			return EHazeNetworkActivation::DontActivate;

		if (PumpCart.BoostFadeDuration < 0.f)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PumpCart.bBoosting)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (PumpCart.BoostFadeDuration < 0.f)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		FadeBeginBoost = PumpCart.BoostSpeed;
		Time = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		PumpCart.BoostSpeed = PumpCart.BoostFadeSpeed;
		PumpCart.BoostFadeDuration = -1.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PumpCart.BoostFadeDuration < SMALL_NUMBER)
		{
			PumpCart.BoostSpeed = PumpCart.BoostFadeSpeed;
			PumpCart.BoostFadeDuration = -1.f;
			return;
		}

		Time += DeltaTime;
		float Alpha = Time / PumpCart.BoostFadeDuration;

		float FadedBoost = FMath::Lerp(FadeBeginBoost, PumpCart.BoostFadeSpeed, Alpha);
		PumpCart.BoostSpeed = FadedBoost;

		if (Time > PumpCart.BoostFadeDuration)
		{
			PumpCart.BoostFadeDuration = -1.f;
		}
	}
}
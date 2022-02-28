import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailPumpCartBoostCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Movement);
	default CapabilityTags.Add(RailCartTags::Boost);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ARailPumpCart PumpCart;
	UHazeAkComponent HazeAkComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PumpCart = Cast<ARailPumpCart>(Owner);
		HazeAkComponent = PumpCart.HazeAkComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkActivation::DontActivate;

		if (!PumpCart.bBoosting)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!PumpCart.bBoosting)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		if(PumpCart.BoostStartEvent != nullptr)
		{
			HazeAkComponent.HazePostEvent(PumpCart.BoostStartEvent);
		}

		HazeAkComponent.SetRTPCValue(HazeAudio::RTPC::RailCartBoost, 1.f, 0.f);		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		if(PumpCart.BoostStopEvent != nullptr)
		{
			HazeAkComponent.HazePostEvent(PumpCart.BoostStopEvent);
		}
		
		HazeAkComponent.SetRTPCValue(HazeAudio::RTPC::RailCartBoost, 0.f, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Speed = PumpCart.Speed;
		Speed = FMath::Lerp(Speed, PumpCart.BoostSpeed, 7.f * DeltaTime);

		PumpCart.Speed = Speed;
	}
}
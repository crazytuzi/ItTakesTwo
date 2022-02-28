import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCartUserComponent;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;

class URailPumpCartUserMashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::User);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	AHazePlayerCharacter Player;
	URailPumpCartUserComponent CartUser;

	ARailPumpCart Cart;
	UButtonMashSilentHandle ButtonMash;

	float SyncTime = 0.f;
	float SyncedPumpRate = 0.f;

	float PumpRate = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CartUser = URailPumpCartUserComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (CartUser.CurrentCart.bIsLocked)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CartUser.CurrentCart == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (CartUser.CurrentCart.bIsLocked)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Cart = CartUser.CurrentCart;
		ButtonMash = StartButtonMashSilent(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		StopButtonMash(ButtonMash);
		PumpRate = 0.f;

		if (Cart != nullptr)
		{
			if (CartUser.bFront)
				Cart.FrontPumpRate = 0.f;
			else
				Cart.BackPumpRate = 0.f;

			Cart = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float TargetPumpValue = ButtonMash.MashRateControlSide / Cart.MaxMashRate;
			PumpRate = FMath::Lerp(PumpRate, TargetPumpValue, 2.f * DeltaTime);

			if (SyncTime < Time::GetGameTimeSeconds())
			{
				SyncTime = Time::GameTimeSeconds + 0.2f;
				NetSetPumpRate(PumpRate);
			}

			if (CartUser.bFront)
				Cart.FrontPumpRate = PumpRate;
			else
				Cart.BackPumpRate = PumpRate;

			if (Cart.Widget != nullptr && WasActionStarted(ActionNames::InteractionTrigger))
			{
				Cart.Widget.OnButtonPressed();
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetPumpRate(float PumpRate)
	{
		SyncedPumpRate = PumpRate;

		if (Cart == nullptr)
			return;

		if (CartUser.bFront)
			Cart.FrontPumpRate = PumpRate;
		else
			Cart.BackPumpRate = PumpRate;
	}
}
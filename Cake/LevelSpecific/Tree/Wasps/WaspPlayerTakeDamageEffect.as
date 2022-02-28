import Peanuts.Outlines.Outlines;
import Vino.PlayerHealth.PlayerHealthComponent;

UCLASS()
class UWaspPlayerTakeDamageEffect : UPlayerDamageEffect
{
	// we'll handle that ourselves in the capability that uses it. 
	default bInvulnerableDuringEffect = false;

	// Total blinking time
	float HurtEffectDuration = 1.8f;
	float HurtEffectTimeStamp = 0.f;

	bool bBlockingVisibility = false;

	void Activate()
	{
		Super::Activate();
		HurtEffectTimeStamp = Time::GetGameTimeSeconds();
	}

	void Tick(float DeltaTime) override 
	{
		Super::Tick(DeltaTime);

		if (Time::GetGameTimeSince(HurtEffectTimeStamp) > HurtEffectDuration)
		{
			if (bBlockingVisibility)
			{
				Player.UnblockCapabilities(CapabilityTags::Visibility, this);
				bBlockingVisibility = false;
			}
			FinishEffect();
			return;
		}

 		const float PulsatingValue = FMath::MakePulsatingValue(Time::GetGameTimeSeconds(), 5.f);
		const bool bShouldHide = false;//PulsatingValue > 0.5f;

		if (bBlockingVisibility != bShouldHide)
		{
			bBlockingVisibility = bShouldHide;
			if (bBlockingVisibility)
				Player.BlockCapabilities(CapabilityTags::Visibility, this);
			else
				Player.UnblockCapabilities(CapabilityTags::Visibility, this);
		}
	};

    void Deactivate() override
	{
		Super::Deactivate();
		if (bBlockingVisibility)
		{
			Player.UnblockCapabilities(CapabilityTags::Visibility, this);
			bBlockingVisibility = false;
		}
	}

};
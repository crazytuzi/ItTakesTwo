import Peanuts.Outlines.Outlines;
import Vino.PlayerHealth.PlayerHealthComponent;

UCLASS()
class UBeetlePlayerDamageEffect : UPlayerDamageEffect
{
	// we'll handle that ourselves in the capability that uses it. 
	default bInvulnerableDuringEffect = false;

	// Total blinking time
	float HurtEffectDuration = 1.8f;
	float HurtEffectTimeStamp = 0.f;

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
			FinishEffect();
			return;
		}
	};

};

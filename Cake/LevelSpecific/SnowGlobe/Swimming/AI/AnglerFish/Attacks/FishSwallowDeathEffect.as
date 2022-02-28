import Peanuts.Fades.FadeStatics;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.BaseExplodeDeathEffect;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class UFishSwallowDeathEffect : UBaseExplodeDeathEffect
{
	default EffectDuration = 2.f;
	USnowGlobeSwimmingComponent SwimComp;
	
	void Activate() override
	{
		// Dying to the fish flags player as not underwater anymore, we force this state like so to ensure player VO stays in underwater-mode
		// for the duration of this death
		SwimComp = USnowGlobeSwimmingComponent::Get(Player);
		if(SwimComp != nullptr)
		{
			SwimComp.bForceUnderwater = true;
			System::SetTimer(this, n"ResetForceUnderwater", 3.f, false);
		}

		Super::Activate();
		FadeOutPlayer(Player, 3.f, 0.1f, 1.f);

	}

	UFUNCTION()
	void ResetForceUnderwater()
	{
		SwimComp.bForceUnderwater = false;
	}
}
import Vino.PlayerHealth.PlayerDeathEffect;

class UPlayerLockedDeathEffect : UPlayerDeathEffect
{
	UFUNCTION()
	void FinishDeathEffect()
	{
		FinishEffect();
	}
}
import Vino.PlayerHealth.BaseDissolvePlayerDeathEffect;

UCLASS(Abstract)
class UDissolveSinkPlayerDeathEffect : UBaseDissolvePlayerDeathEffect
{
	default EffectDuration = 1.17f;
	default EffectDelay = 1.f;
	default TimeUntilEffectDetachment = 1.17f;

	default DissolveDuration = 0.25f;
	default DissolveDelay = 0.9f;

	UPROPERTY()
	bool bHideOutline = true;

	void Activate() override
	{
		if (bHideOutline)
			Player.OtherPlayer.DisableOutlineByInstigator(this);

		Super::Activate();
	}

	void Deactivate() override
	{
		if (bHideOutline)
			Player.OtherPlayer.EnableOutlineByInstigator(this);

		Super::Deactivate();
	}

	void SpawnEffect() override
	{
		Super::SpawnEffect();

		if (EffectComponent != nullptr)
			EffectComponent.SetTranslucentSortPriority(3);
	}
}
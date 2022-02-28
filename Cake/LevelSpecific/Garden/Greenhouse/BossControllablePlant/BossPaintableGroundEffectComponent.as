import Vino.PlayerHealth.PlayerHealthComponent;

class UBossPaintableGroundEffectComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> GooDamageEffect;
}
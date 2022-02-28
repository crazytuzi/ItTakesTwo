import Vino.PlayerHealth.PlayerGenericEffect;

UCLASS(Abstract)
class UPlayerDeathEffect : UPlayerGenericEffect
{
	// Whether players that died by this effect should be allowed to respawn back in the same place
	UPROPERTY()
	bool bAllowRespawnInPlace = false;

	// This will happen if the death happens from a stale activation
	bool bStale = false;
};

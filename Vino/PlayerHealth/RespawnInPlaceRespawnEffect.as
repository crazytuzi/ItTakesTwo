import Vino.PlayerHealth.PlayerRespawnComponent;
import Vino.PlayerHealth.PlayerHealthStatics;

class URespawnInPlaceRespawnEffect : UPlayerRespawnEffect
{
	UPROPERTY()
	bool bRespawnImmediately = true;

	UPROPERTY()
	float InvulnerabilityDuration = 1.f;

	void Activate() override
	{
		Super::Activate();

		if (bRespawnImmediately)
		{
			TriggerRespawn();
			FinishEffect();
		}

		AddPlayerInvulnerabilityDuration(Player, InvulnerabilityDuration);
	}

	void TeleportToRespawnLocation(FPlayerRespawnEvent Event)
	{
		// We don't do a teleport if we're respawning in place
	}
};
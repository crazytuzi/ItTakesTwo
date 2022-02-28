import Vino.PlayerHealth.BaseDissolvePlayerDeathEffect;

UCLASS(Abstract)
class UDissolveFallPlayerDeathEffect : UBaseDissolvePlayerDeathEffect
{
	void Activate() override
	{
		Player.SetCapabilityActionState(n"DeathVelocity", EHazeActionState::Active);
		Super::Activate();
	}

	void Deactivate() override
	{
		Player.SetCapabilityActionState(n"DeathVelocity", EHazeActionState::Inactive);
		Super::Deactivate();
	}
}
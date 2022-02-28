import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerRespawnComponent;
import Peanuts.Foghorn.FoghornStatics;

UCLASS(Abstract)
class UTimedPlayerDeathEffect : UPlayerDeathEffect
{
	UPROPERTY(Category = "Effect")
	float EffectDuration = 2.f;

	UPROPERTY(Category = "Effect")
	float ForceFeedbackDuration = 0.5f;

	UPROPERTY(Category = "Effect")
	bool bHidePlayerAfterEffectFinishes = true;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayDeathAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyDeathAudioEvent;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset MayDeathVoEvent;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset CodyDeathVoEvent;

    UPROPERTY(Category = "Capabilities")
    TArray<FName> BlockedCapabilities;
	default BlockedCapabilities.Add(CapabilityTags::Movement);
	default BlockedCapabilities.Add(CapabilityTags::GameplayAction);
	default BlockedCapabilities.Add(CapabilityTags::LevelSpecific);
	default BlockedCapabilities.Add(CapabilityTags::Collision);

	private float Timer = 0.f;

	void Activate() override
	{
        for (FName Capability : BlockedCapabilities)
            Player.BlockCapabilities(Capability, this);

		if (Player.IsMay() && MayDeathAudioEvent != nullptr)
				Player.PlayerHazeAkComp.HazePostEvent(MayDeathAudioEvent);
				
			else if (Player.IsCody() && CodyDeathAudioEvent != nullptr)
				Player.PlayerHazeAkComp.HazePostEvent(CodyDeathAudioEvent);

		if (Player.IsMay() && MayDeathVoEvent != nullptr)
				PauseFoghornActorWithEffort(Player, MayDeathVoEvent, nullptr);
				
			else if (Player.IsCody() && CodyDeathVoEvent != nullptr)
				PauseFoghornActorWithEffort(Player, CodyDeathVoEvent, nullptr);

		Super::Activate();
	}

	void Deactivate() override
	{
        for (FName Capability : BlockedCapabilities)
            Player.UnblockCapabilities(Capability, this);

		Super::Deactivate();

		auto HealthComp = UPlayerHealthComponent::Get(Player);
		if (!HealthComp.bVisibilityBlocked)
			Player.SetActorHiddenInGame(false);
	}

	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);

		if (!bFinished)
		{
			Timer += DeltaTime;

			// Force feedback timer
			if (Timer < ForceFeedbackDuration)
				Player.SetFrameForceFeedback(1.f, 1.f);

			// Effect finish timer
			if (Timer >= EffectDuration)
			{
				FinishEffect();
				if (bHidePlayerAfterEffectFinishes)
				{
					auto RespawnComp = UPlayerRespawnComponent::Get(Player);
					RespawnComp.HidePlayerFromDeath();
				}
			}
		}
	}
};
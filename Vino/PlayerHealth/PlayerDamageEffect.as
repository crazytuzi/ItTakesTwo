import Vino.PlayerHealth.PlayerGenericEffect;

UCLASS(Abstract)
class UPlayerDamageEffect : UPlayerGenericEffect
{
    // If set, the player will not be able to take any additional damage while this effect is active
    UPROPERTY()
    bool bInvulnerableDuringEffect = true;

    // Whether to also play the universal damage effect in addition to this effect when it is triggered
    UPROPERTY()
    bool bPlayUniversalDamageEffect = true;

	// Duration for the universal damage effect if it is being applied
	UPROPERTY(EditDefaultsOnly, BlueprintHidden, Meta = (EditCondition = "bPlayUniversalDamageEffect", EditConditionHides))
	float UniversalDamageEffectDuration = 1.f;
		
	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayDamageAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyDamageAudioEvent;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset MayDamageVoEvent;

	UPROPERTY(Category = "Voiceover")
    UFoghornBarkDataAsset CodyDamageVoEvent;

	UFUNCTION()
	void Activate()
	{
		Super::Activate();

		if (Player.IsMay() && MayDamageAudioEvent != nullptr)
				Player.PlayerHazeAkComp.HazePostEvent(MayDamageAudioEvent);
				
			else if (Player.IsCody() && CodyDamageAudioEvent != nullptr)
				Player.PlayerHazeAkComp.HazePostEvent(CodyDamageAudioEvent);

		if (Player.IsMay() && MayDamageVoEvent != nullptr)
				PlayFoghornEffort(MayDamageVoEvent, Player);
				
			else if (Player.IsCody() && CodyDamageVoEvent != nullptr)
				PlayFoghornEffort(CodyDamageVoEvent, Player);
	}
};

UCLASS(Abstract)
class UPlayerUniversalDamageEffect : UPlayerDamageEffect
{
	default bPlayUniversalDamageEffect = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float WantedEffectDuration = 0.f;
};
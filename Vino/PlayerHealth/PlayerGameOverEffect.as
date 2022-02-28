import Vino.PlayerHealth.PlayerGenericEffect;

UCLASS(Abstract)
class UPlayerGameOverEffect : UPlayerGenericEffect
{
	/* Whether to automatically restart from the latest save when the effect is finished. */
	UPROPERTY()
	bool bRestartFromSaveAfterEffect = true;

	/* Called when all death effects are finished playing. */
	UFUNCTION(BlueprintEvent)
	void OnDeathEffectsFinishedPlaying() {}
};

class UDummyPlayerGameOverEffect : UPlayerGameOverEffect
{
	void Activate()
	{
		Super::Activate();
		FinishEffect();
	}
};
import Peanuts.DamageFlash.DamageFlashStatics;
import Vino.PlayerHealth.PlayerHealthComponent;

UCLASS(Abstract)
class UQueenDeathRayDamageEffect : UPlayerDamageEffect
{
	float HurtEffectDuration = 1.8f;
	float HurtEffectTimeStamp = 0.f;
	
	UPROPERTY()
	UAnimSequence CodyAnim;
	UPROPERTY()
	UAnimSequence MayAnim;

    void Deactivate() override
	{
		Super::Deactivate();
	}

    void Activate() override
    {
		HurtEffectTimeStamp = Time::GetGameTimeSeconds();
		FHazeSlotAnimSettings Settings;
		UAnimSequence AnimTouse;

		if(Player.IsCody())
		{
			AnimTouse = CodyAnim;
		}

		else
		{
			AnimTouse = MayAnim;
		}

		Player.PlaySlotAnimation(Animation = AnimTouse, OnBlendingOut = FHazeAnimationDelegate(this, n"OnSlotAnimationDone"));

		FVector ImpulseVector = FVector::RightVector * - 1000;
		ImpulseVector += FVector::UpVector * 1000;
		Player.AddImpulse(ImpulseVector);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);

		Super::Activate();
    }

	UFUNCTION()
	void OnSlotAnimationDone()
	{
		Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	void Tick(float DeltaTime) override 
	{
		Super::Tick(DeltaTime);

		if (bFinished)
			return;

		if (Time::GetGameTimeSince(HurtEffectTimeStamp) > HurtEffectDuration)
		{
			FinishEffect();
			return;
		}

 		const float PulsatingValue = FMath::MakePulsatingValue(Time::GetGameTimeSeconds(), 5.f);
	}
};
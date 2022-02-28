import Vino.PlayerHealth.TimedPlayerDeathEffect;

class UBaseDissolvePlayerDeathEffect : UTimedPlayerDeathEffect
{
	default bHidePlayerAfterEffectFinishes = false;
	default EffectDuration = 0.5f;

	float ActiveDuration = 0.f;

	// How long until the player is fully dissolved
	UPROPERTY(Category = "Dissolve")
	float DissolveDuration = 0.4f;

	UPROPERTY(Category = "Dissolve")
	float DissolveDelay = 0.f;

	UPROPERTY(Category = "Effect")
	UNiagaraSystem MayEffect;

	UPROPERTY(Category = "Effect")
	UNiagaraSystem CodyEffect;

	UPROPERTY(Category = "Effect")
	float EffectDelay = 0.f;

	// Change if you want the particle effect to stay put even if the player keeps moving. Always detaches when the death effect is over
	UPROPERTY(Category = "Effect")
	float TimeUntilEffectDetachment = 0.5f;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayAnimation;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyAnimation;

	UAnimSequence Anim;

	UPlayerRespawnComponent PlayerRespawnComponent;
	UNiagaraComponent EffectComponent;
	bool bEffectStarted = false;
	bool bEffectDetached = false;
	bool bDissolveStarted = false;
	float DissolveStartTime = 0.f;

	void Activate() override
	{
		bEffectDetached = false;
		bDissolveStarted = false;
		bEffectStarted = false;
		DissolveStartTime = 0.f;

		if (EffectDelay == 0.f)
			SpawnEffect();

		if (Player.IsMay() && MayAnimation != nullptr)
			Anim = MayAnimation;
		else if (Player.IsCody() && CodyAnimation != nullptr)
			Anim = CodyAnimation;

		if (Anim != nullptr)
			Player.PlaySlotAnimation(Animation = Anim);

		ActiveDuration = 0.f;

		Super::Activate();
		PlayerRespawnComponent = Cast<UPlayerRespawnComponent>(Player.GetComponentByClass(UPlayerRespawnComponent::StaticClass()));
		PlayerRespawnComponent.OnPlayerDissolveStarted.ExecuteIfBound(Player);
	}

	void Deactivate() override
	{
		if (EffectComponent != nullptr && !bEffectDetached)
		{
			bEffectDetached = true;
			EffectComponent.DetachFromParent(true, false);
		}

		if (Anim != nullptr)
			Player.StopAnimationByAsset(Anim);

		Super::Deactivate();
	}

	void SpawnEffect()
	{
		if (bEffectStarted)
			return;

		bEffectStarted = true;

		UNiagaraSystem Effect;
		if (Player.IsMay() && MayEffect != nullptr)
			Effect = MayEffect;
		else if (Player.IsCody() && CodyEffect != nullptr)
			Effect = CodyEffect;
		
		if (Effect != nullptr)
			EffectComponent = Niagara::SpawnSystemAttached(Effect, Player.Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);

		ActiveDuration += DeltaTime;
		if (ActiveDuration >= DissolveDelay)
		{
			if (!bDissolveStarted)
			{
				bDissolveStarted = true;
				DissolveStartTime = ActiveDuration;
			}
			float CurrentDissolveValue = FMath::GetMappedRangeValueClamped(FVector2D(DissolveStartTime, DissolveStartTime + DissolveDuration), FVector2D(0.f, 1.f), ActiveDuration);
			PlayerRespawnComponent.SetDissolve(CurrentDissolveValue);
		}

		if (!bEffectStarted && ActiveDuration >= EffectDelay)
		{
			SpawnEffect();
		}

		if (EffectComponent != nullptr && !bEffectDetached && ActiveDuration >= TimeUntilEffectDetachment)
		{
			bEffectDetached = true;
			EffectComponent.DetachFromParent(true, false);
		}
	}
}
import Vino.PlayerHealth.TimedPlayerDeathEffect;

class UBaseExplodeDeathEffect : UTimedPlayerDeathEffect
{
	// default BlockedCapabilities.Add(CapabilityTags::Visibility);

	default EffectDuration = 0.5f;

	float ActiveDuration = 0.f;

	UPROPERTY(Category = "Effect")
	UNiagaraSystem MayExplodeEffect;

	UPROPERTY(Category = "Effect")
	UNiagaraSystem CodyExplodeEffect;

	UPROPERTY(Category = "Animation")
	UAnimSequence MayAnim;

	UPROPERTY(Category = "Animation")
	UAnimSequence CodyAnim;

	UPlayerRespawnComponent PlayerRespawnComponent;

	void Activate() override
	{
		UNiagaraSystem ExplodeEffect;

		if (Player.IsMay() && MayExplodeEffect != nullptr)
			ExplodeEffect = MayExplodeEffect;
		else if (Player.IsCody() && CodyExplodeEffect != nullptr)
			ExplodeEffect = CodyExplodeEffect;
		
		if (ExplodeEffect != nullptr)
		{
			// FVector ExplodeEffectLocation = Player.ActorLocation + (Player.MovementWorldUp * (Player.CapsuleComponent.ScaledCapsuleHalfHeight));
			// UNiagaraComponent ExplodeEffectComp = Niagara::SpawnSystemAtLocation(ExplodeEffect, ExplodeEffectLocation, Player.ActorRotation);
			// ExplodeEffectComp.SetNiagaraVariableVec3("User.Velocity", Player.GetActualVelocity());

			Niagara::SpawnSystemAttached(ExplodeEffect, Player.Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

			//if (Player.IsMay() && MayAudioEvent != nullptr)
			//	Player.PlayerHazeAkComp.HazePostEvent(MayAudioEvent);
				
			//else if (Player.IsCody() && CodyAudioEvent != nullptr)
			//	Player.PlayerHazeAkComp.HazePostEvent(CodyAudioEvent);
		}

		UAnimSequence Anim;
		if (Player.IsMay() && MayAnim != nullptr)
			Anim = MayAnim;
		else if (Player.IsCody() && CodyAnim != nullptr)
			Anim = CodyAnim;

		if (Anim != nullptr)
			Player.PlaySlotAnimation(Animation = Anim);

		ActiveDuration = 0.f;

		Player.SetCapabilityActionState(n"DeathVelocity", EHazeActionState::Active);

		Super::Activate();
		PlayerRespawnComponent = Cast<UPlayerRespawnComponent>(Player.GetComponentByClass(UPlayerRespawnComponent::StaticClass()));
		PlayerRespawnComponent.OnPlayerDissolveStarted.ExecuteIfBound(Player);
	}

	void Deactivate() override
	{
		Player.StopAnimation();
		Player.SetCapabilityActionState(n"DeathVelocity", EHazeActionState::Inactive);
		Super::Deactivate();
	}

	TArray<AActor> AttachedActors;
	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);

		ActiveDuration += DeltaTime;
		float CurrentDissolveValue = FMath::GetMappedRangeValueClamped(FVector2D(0.f, EffectDuration), FVector2D(0.f, 1.f), ActiveDuration);
		PlayerRespawnComponent.SetDissolve(CurrentDissolveValue);
	}
}
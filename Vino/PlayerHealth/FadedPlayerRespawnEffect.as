import Vino.PlayerHealth.PlayerRespawnComponent;
import Peanuts.Fades.FadeStatics;
import Vino.PlayerHealth.PlayerHealthStatics;

class UFadedPlayerRespawnEffect : UPlayerRespawnEffect
{
	UPROPERTY(Category = "Fade Out")
	float FadeOutDuration = 0.5f;

	UPROPERTY(Category = "Fade Out")
	float FadeLength = 0.5f;

	UPROPERTY(Category = "Fade Out")
	float FadeInDuration = 0.5f;

	UPROPERTY(Category = "Invulnerability")
	float InvulnerabilityDuration = 2.f;

	// Whether to flash the player if they were made invulnerable by this effect
	UPROPERTY(Category = "Flash")
	bool bFlashPlayerInvulnerability = true;

	// What color to flash the player while invulnerable
	UPROPERTY(Category = "Flash", Meta = (EditCondition = "bFlashPlayerInvulnerability"))
	FLinearColor FlashColor(1.5f, 0.996f, 0.077f, 1.f);

	// Time between subsequent flashes 
	UPROPERTY(Category = "Flash", Meta = (EditCondition = "bFlashPlayerInvulnerability"))
	float FlashInterval = 0.2f;

	// Duration of each invulnerability flash
	UPROPERTY(Category = "Flash", Meta = (EditCondition = "bFlashPlayerInvulnerability"))
	float FlashDuration = 2.f;

	private bool bHasTriggeredAudio = false;
	private bool bIsInputBlocked = false;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayRespawnAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyRespawnAudioEvent;

	private float Timer = 0.f;
	private float FlashTimer = 0.f;
	private float NextFlash = 0.f;
	private UPlayerHealthComponent HealthComp;
	private UPlayerRespawnComponent RespawnComp;
	private UNiagaraComponent RespawnEffect;

	void Activate() override
	{
		Super::Activate();

		if (!SceneView::IsFullScreen())
		{
			FadeOutPlayer(Player, FadeDuration = FadeLength, FadeOutTime = FadeOutDuration, FadeInTime = FadeInDuration);

			if (Player.IsMay())
				UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_Death_May", 1.f);
			else
				UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_Death_Cody", 1.f);

			BlockInput();
		}

		HealthComp = UPlayerHealthComponent::Get(Player);
		RespawnComp = UPlayerRespawnComponent::Get(Player);

		bHasTriggeredAudio = false;
	}

	void OnPerformRespawn(FPlayerRespawnEvent Event) override
	{
		RespawnComp.TriggerDissolveEffect();

		Super::OnPerformRespawn(Event);

		if (!SceneView::IsFullScreen())
			Player.SnapCameraAtEndOfFrame();

		if (RespawnComp.RespawnSystem != nullptr)
			RespawnEffect = Niagara::SpawnSystemAttached(RespawnComp.RespawnSystem, Player.Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	void Tick(float DeltaTime) override
	{
		Super::Tick(DeltaTime);

		Timer += DeltaTime;

		// Trigger the respawn when the fade out is done
		if (!bRespawnTriggered && Timer > FadeOutDuration)
		{
			TriggerRespawn();

			if (bFlashPlayerInvulnerability && !Player.bIsControlledByCutscene)
				HealthComp.FlashInvulnerability(FlashColor, FlashDuration, FlashInterval);
		}

		// Play audio event when the fade in starts
		if(bRespawnTriggered && Timer > FadeOutDuration + FadeLength && !bHasTriggeredAudio)
		{
			UAkAudioEvent RespawnEvent = MayRespawnAudioEvent;
			if(Player.IsCody())
				RespawnEvent = CodyRespawnAudioEvent;

			Player.PlayerHazeAkComp.HazePostEvent(RespawnEvent);
			bHasTriggeredAudio = true;
		}

		// Allow player input halfway through fade in length
		if (bIsInputBlocked && bRespawnTriggered && Timer > FadeOutDuration + FadeLength)
			UnblockInput();

		// Finish the effect when all fading is done
		if (bRespawnTriggered && Timer > FadeOutDuration + FadeLength + FadeInDuration && !bFinished)
		{
			FinishEffect();

			if (InvulnerabilityDuration > 0.f)
				AddPlayerInvulnerabilityDuration(Player, InvulnerabilityDuration);
		}
	}

	void BlockInput()
	{
		ensure(!bIsInputBlocked);

		Player.BlockCapabilities(CapabilityTags::MovementInput, Outer);
		bIsInputBlocked = true;
	}

	void UnblockInput()
	{
		ensure(bIsInputBlocked);

		Player.UnblockCapabilities(CapabilityTags::MovementInput, Outer);
		bIsInputBlocked = false;
	}

	void Deactivate() override
	{
		if (!bFinished)
		{
			ClearPlayerFades(Player, FadeInTime=0.f);

			if (RespawnEffect != nullptr)
				RespawnEffect.Deactivate();

			RespawnComp.StopDissolveEffect();
		}

		if (Player.IsMay())
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_Death_May", 0.f);
		else
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_UI_Death_Cody", 0.f);

		if (bIsInputBlocked)
			UnblockInput();
			
		Super::Deactivate();
	}
};
import Vino.Interactions.ThreeShotInteraction;

event void FFrayedCableEvent(AHazePlayerCharacter Player);

class AVacuumGeneratorFrayedCables : AThreeShotInteraction
{
	bool bCablesHeld = false;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayElectrifiedMh;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyElectrifiedMh;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ElectrifiedCamShake;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> ElectrifiedPassiveCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ElectrifiedRumble;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ElectrifiedPassiveRumble;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem ElectrifiedSystem;
	UNiagaraComponent EffectComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayerElectrifiedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ReleasePlayerAudioEvent;

	UPROPERTY()
	FFrayedCableEvent OnPlayerInteracted;
	UPROPERTY()
	FFrayedCableEvent OnPlayerElectrified;

	UPROPERTY()
	AActor PoiActor;

	AHazePlayerCharacter ElectrifiedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnThreeShotActivated.AddUFunction(this, n"Activated");
		OnStartBlendingOut.AddUFunction(this, n"BlendedIn");
		OnMHBlendingOut.AddUFunction(this, n"Canceled");
	}

	UFUNCTION(NotBlueprintCallable)
	void Activated(AHazePlayerCharacter Player, AThreeShotInteraction Interaction)
	{
		Player.ApplyCameraSettings(CamSettings, FHazeCameraBlendSettings(2.f), this);
	}

	UFUNCTION(NotBlueprintCallable)
	void BlendedIn(AHazePlayerCharacter Player, AThreeShotInteraction Interaction)
	{
		bCablesHeld = true;
		OnPlayerInteracted.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void Canceled(AHazePlayerCharacter Player, AThreeShotInteraction Interaction)
	{
		bCablesHeld = false;
		Player.ClearCameraSettingsByInstigator(this, 2.f);
	}

	void ElectricChargePassedThrough()
	{
		ElectrifiedPlayer = ActivePlayer;

		DisableInteraction(n"Electrified");
		EndInteraction();

		UAnimSequence Anim = ElectrifiedPlayer.IsCody() ? CodyElectrifiedMh : MayElectrifiedMh;
		ElectrifiedPlayer.PlayEventAnimation(Animation = Anim, bLoop = true);

		ElectrifiedPlayer.PlayForceFeedback(ElectrifiedRumble, false, true, n"Electrified");
		ElectrifiedPlayer.PlayForceFeedback(ElectrifiedPassiveRumble, true, true, n"ElectrifiedPassive");
		ElectrifiedPlayer.PlayCameraShake(ElectrifiedCamShake, 0.5f);
		ElectrifiedPlayer.PlayCameraShake(ElectrifiedPassiveCamShake);

		ElectrifiedPlayer.ApplyCameraSettings(CamSettings, FHazeCameraBlendSettings(1.f), this);

		OnPlayerElectrified.Broadcast(ElectrifiedPlayer);

		ElectrifiedPlayer.PlayerHazeAkComp.HazePostEvent(PlayerElectrifiedAudioEvent);

		if (ElectrifiedSystem != nullptr)
			EffectComponent = Niagara::SpawnSystemAttached(ElectrifiedSystem, ElectrifiedPlayer.Mesh, n"Root", FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);

		if (PoiActor != nullptr)
		{
			FHazePointOfInterest PoI;
			PoI.FocusTarget.Actor = PoiActor;
			PoI.Blend.BlendTime = 1.5f;
			PoI.Blend.Type = EHazeCameraBlendType::BlendInThenFollow;
			PoI.Blend.Fraction = 0.5f;
			PoI.FocusTarget.WorldOffset = FVector(-300.f, 0.f, 0.f);
			ElectrifiedPlayer.ApplyPointOfInterest(PoI, this);
		}
	}

	void ReleaseElectrifiedPlayer()
	{
		EnableInteraction(n"Electrified");
		ElectrifiedPlayer.StopAnimation();
		ElectrifiedPlayer.StopAllCameraShakes();
		ElectrifiedPlayer.StopForceFeedback(ElectrifiedPassiveRumble, n"ElectrifiedPassive");

		ElectrifiedPlayer.ClearCameraSettingsByInstigator(this, 1.f);

		ElectrifiedPlayer.ClearPointOfInterestByInstigator(this);

		ElectrifiedPlayer.PlayerHazeAkComp.HazePostEvent(ReleasePlayerAudioEvent);

		if (EffectComponent != nullptr)
			EffectComponent.Deactivate();
	}
}
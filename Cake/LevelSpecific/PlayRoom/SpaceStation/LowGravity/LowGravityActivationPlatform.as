import Vino.Interactions.InteractionComponent;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.LowGravity.GravityVolumeObjectManager;

event void FLowGravityEvent();

class ALowGravityActivationPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent ToyMesh;

	UPROPERTY(DefaultComponent, Attach = ToyMesh)
	UHazeSkeletalMeshComponentBase MaySpinner;

	UPROPERTY(DefaultComponent, Attach = ToyMesh)
	UHazeSkeletalMeshComponentBase CodySpinner;

	UPROPERTY(DefaultComponent, Attach = MaySpinner)
	UStaticMeshComponent MaySpinnerMesh;

	UPROPERTY(DefaultComponent, Attach = CodySpinner)
	UStaticMeshComponent CodySpinnerMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent LightPillarMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UInteractionComponent MayInteractionComp;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UInteractionComponent CodyInteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio", EditDefaultsOnly)
	UAkAudioEvent PillarLightStart;

	UPROPERTY(Category = "Audio", EditDefaultsOnly)
	UAkAudioEvent PillarLightStop;

	FHazeAudioEventInstance PillarLightStartEventInstance;
	FHazeAudioEventInstance PillarLightStopEventInstance;

	UPROPERTY(DefaultComponent, Attach = MaySpinner)
	UHazeAkComponent MaySpinnerHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = CodySpinner)
	UHazeAkComponent CodySpinnerHazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MaySpinnerActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodySpinnerActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LowGravityActivatedAudioEvent;

	UPROPERTY()
	FLowGravityEvent OnLowGravityActivated;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor InactiveColor;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor SlapColor;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor ActiveColor;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MaySpinnerAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodySpinnerAnim;

	UPROPERTY()
	AGravityVolumeObjectManager Manager;

	FHazeAnimNotifyDelegate MayAnimNotifyDelegate;
	FHazeAnimNotifyDelegate CodyAnimNotifyDelegate;

	bool bPlayerRecentlyActivated = false;
	float CurrentBrightness = 0.5f;

	float MaxTimeDifference = 3.f;
	float TimeSinceMayActivation = 2.f;
	float TimeSinceCodyActivation = 2.f;

	bool bLowGravityActive = false;

	float CurrentEmissiveAlpha = 0.f;

	bool bLightPillarActive = false;

	FTimerHandle CodyPendingStartHandle;
	FTimerHandle MayPendingStartHandle;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeSinceMayActivation++;
		TimeSinceCodyActivation++;

		MayInteractionComp.SetExclusiveForPlayer(EHazePlayer::May);
		CodyInteractionComp.SetExclusiveForPlayer(EHazePlayer::Cody);

		MayInteractionComp.OnActivated.AddUFunction(this, n"MayInteractionActivated");
		CodyInteractionComp.OnActivated.AddUFunction(this, n"CodyInteractionActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	void MayInteractionActivated(UInteractionComponent InteractionComp, AHazePlayerCharacter Player)
	{
		MayInteractionComp.Disable(n"Used");

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.TriggerMovementTransition(this);
		
		System::SetTimer(this, n"UnlockMayMovement", 0.75f, false);

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"MayAnimFinished");
		Player.PlaySlotAnimation(OnBlendingOut = AnimDelegate, Animation = MayAnim, BlendTime = 0.05f);

		MayAnimNotifyDelegate.BindUFunction(this, n"MaySpinnerActivated");
		Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), MayAnimNotifyDelegate);

		FHazeAnimationDelegate SpinnerBlendingOutDelegate;
		SpinnerBlendingOutDelegate.BindUFunction(this, n"MaySpinnerAnimationFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = MaySpinnerAnim;
		MaySpinner.PlaySlotAnimation(FHazeAnimationDelegate(), SpinnerBlendingOutDelegate, AnimParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void MaySpinnerActivated(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), MayAnimNotifyDelegate);
		TimeSinceMayActivation = 0.f;

		MaySpinnerHazeAkComp.HazePostEvent(MaySpinnerActivatedAudioEvent);

		System::ClearAndInvalidateTimerHandle(MayPendingStartHandle);
		MayPendingStartHandle = System::SetTimer(this, n"TriggerMayPendingStart", 1.5f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerMayPendingStart()
	{
		Manager.MinigameComp.PlayPendingStartVOBark(Game::GetMay(), ActorLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	void MayAnimFinished()
	{
		Game::GetMay().UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UnlockMayMovement()
	{
		Game::GetMay().TriggerMovementTransition(this);
		Game::GetMay().UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void MaySpinnerAnimationFinished()
	{
		MayInteractionComp.EnableAfterFullSyncPoint(n"Used");
	}

	UFUNCTION(NotBlueprintCallable)
	void CodyInteractionActivated(UInteractionComponent InteractionComp, AHazePlayerCharacter Player)
	{
		CodyInteractionComp.Disable(n"Used");

		ForceCodyMediumSize();

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.TriggerMovementTransition(this);

		System::SetTimer(this, n"UnlockCodyMovement", 0.75f, false);

		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"CodyAnimFinished");
		Player.PlaySlotAnimation(OnBlendingOut = AnimDelegate, Animation = CodyAnim, BlendTime = 0.05f);

		CodyAnimNotifyDelegate.BindUFunction(this, n"CodySpinnerActivated");
		Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), CodyAnimNotifyDelegate);

		FHazeAnimationDelegate SpinnerBlendingOutDelegate;
		SpinnerBlendingOutDelegate.BindUFunction(this, n"CodySpinnerAnimationFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = CodySpinnerAnim;
		CodySpinner.PlaySlotAnimation(FHazeAnimationDelegate(), SpinnerBlendingOutDelegate, AnimParams);
	}

	UFUNCTION(NotBlueprintCallable)
	void CodySpinnerActivated(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
	{
		Actor.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), CodyAnimNotifyDelegate);
		TimeSinceCodyActivation = 0.f;

		CodySpinnerHazeAkComp.HazePostEvent(CodySpinnerActivatedAudioEvent);

		System::ClearAndInvalidateTimerHandle(CodyPendingStartHandle);
		CodyPendingStartHandle = System::SetTimer(this, n"TriggerCodyPendingStart", 1.5f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerCodyPendingStart()
	{
		Manager.MinigameComp.PlayPendingStartVOBark(Game::GetCody(), ActorLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	void CodyAnimFinished()
	{
		Game::GetCody().UnblockCapabilities(CapabilityTags::MovementInput, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void UnlockCodyMovement()
	{
		Game::GetCody().TriggerMovementTransition(this);
		Game::GetCody().UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void CodySpinnerAnimationFinished()
	{
		CodyInteractionComp.EnableAfterFullSyncPoint(n"Used");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TimeSinceMayActivation += DeltaTime;
		TimeSinceCodyActivation += DeltaTime;

		float TargetEmissiveAlpha = 0.f;

		if (bLowGravityActive)
			TargetEmissiveAlpha = 3.f;
		else if (TimeSinceMayActivation <= MaxTimeDifference || TimeSinceCodyActivation <= MaxTimeDifference)
			TargetEmissiveAlpha = 0.25f;

		CurrentEmissiveAlpha = FMath::FInterpTo(CurrentEmissiveAlpha, TargetEmissiveAlpha, DeltaTime, 2.f);
		FLinearColor CurrentEmissiveColor = FMath::Lerp(InactiveColor, ActiveColor, CurrentEmissiveAlpha);
		LightPillarMesh.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", CurrentEmissiveColor);

		HazeAkComp.SetRTPCValue("Rtcp_World_SideContent_Playroom_MiniGame_LowGravityRoom_PillarLight_Intensity", CurrentEmissiveAlpha);


		if (bLowGravityActive)
			ActivateLightPillar();
		else if (CurrentEmissiveAlpha > 0.f)
			ActivateLightPillar();
		else if (CurrentEmissiveAlpha == 0.f)
			DeactivateLightPillar();

		if (TimeSinceMayActivation <= MaxTimeDifference && TimeSinceCodyActivation <= MaxTimeDifference && !bLowGravityActive && HasControl())
		{
			NetActivateLowGravity();
		}
	}

	void ActivateLightPillar()
	{
		if (bLightPillarActive)
			return;

		bLightPillarActive = true;

		
		if (!HazeAkComp.HazeIsEventActive(PillarLightStartEventInstance.EventID))
			PillarLightStartEventInstance = HazeAkComp.HazePostEvent(PillarLightStart);
	}

	void DeactivateLightPillar()
	{
		if (!bLightPillarActive)
			return;

		bLightPillarActive = false;

		if (!HazeAkComp.HazeIsEventActive(PillarLightStopEventInstance.EventID))
			PillarLightStopEventInstance = HazeAkComp.HazePostEvent(PillarLightStop);
	}

	UFUNCTION(NetFunction)
	void NetActivateLowGravity()
	{
		bLowGravityActive = true;
		TimeSinceMayActivation = MaxTimeDifference;
		TimeSinceCodyActivation = MaxTimeDifference;
		DisableInteractions();
		OnLowGravityActivated.Broadcast();
	}

	UFUNCTION()
	void DisableInteractions()
	{
		CodyInteractionComp.Disable(n"GameActive");
		MayInteractionComp.Disable(n"GameActive");
	}

	UFUNCTION()
	void EnableInteractions()
	{
		bLowGravityActive = false;
		CodyInteractionComp.Enable(n"GameActive");
		MayInteractionComp.Enable(n"GameActive");
	}
}
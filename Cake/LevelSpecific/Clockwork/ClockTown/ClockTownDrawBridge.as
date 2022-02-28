import Vino.Buttons.GroundPoundButton;
import Vino.Movement.Grinding.GrindSpline;
import Cake.LevelSpecific.Clockwork.VOBanks.ClockworkOutsideVOBank;

event void FClockTownDrawBridgeEvent();

UCLASS(Abstract)
class AClockTownDrawBridge : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BridgeRoot;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	UStaticMeshComponent BridgeMesh;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	UNiagaraComponent BlockedEffect;

	UPROPERTY(DefaultComponent, Attach = BridgeRoot)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RaiseBridgeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RaiseBridgeCompleteAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LowerBridgeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LowerBridgeCompleteAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StoppedByLockAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike LowerTimeLike;
	default LowerTimeLike.Duration = 0.35f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RaiseTimeLike;
	default RaiseTimeLike.Duration = 2.5f;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> BlockedCamShake;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect BlockedForceFeedback;

	UPROPERTY()
	FClockTownDrawBridgeEvent OnBridgeFullyLowered;

	UPROPERTY()
	FClockTownDrawBridgeEvent OnBridgeFullyRaised;

	UPROPERTY()
	AGroundPoundButton ConnectedButton;

	UPROPERTY()
	float MaxPitch = 45.f;

	UPROPERTY()
	AGrindspline AttachedGrindSpline;

	UPROPERTY()
	AGrindspline AttachedGrindSpline2;

	UPROPERTY(EditDefaultsOnly)
	UClockworkOutsideVOBank VOBank;

	float RaiseStartPitch = 0.f;

	int TimesBlocked = 0;

	float LoweredTime = 4.f;
	FTimerHandle RaiseTimerHandle;

	bool bLocked = false;
	bool bLowered = false;

	UPROPERTY()
	bool bBlocked = false;

	bool bPermanentlyLocked = false;

	UPROPERTY()
	bool bPreviewMaxPitch = false;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(CallInEditor)
	void AttachGrindSpline()
	{
		if (AttachedGrindSpline != nullptr)
			AttachedGrindSpline.AttachToComponent(BridgeRoot, NAME_None, EAttachmentRule::KeepWorld);

		if (AttachedGrindSpline2 != nullptr)
			AttachedGrindSpline2.AttachToComponent(BridgeRoot, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		BridgeMesh.SetCullDistance(Editor::GetDefaultCullingDistance(BridgeMesh) * CullDistanceMultiplier);
		
		float Pitch = bPreviewMaxPitch ? MaxPitch : 0.f;
		SetBridgePitch(Pitch);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AttachGrindSpline();
		LowerTimeLike.BindUpdate(this, n"UpdateLower");
		LowerTimeLike.BindFinished(this, n"FinishLower");

		RaiseTimeLike.BindUpdate(this, n"UpdateRaise");
		RaiseTimeLike.BindFinished(this, n"FinishRaise");

		ConnectedButton.OnButtonGroundPoundStarted.AddUFunction(this, n"LowerBridge");

		SetBridgePitch(0.f);
	}

	UFUNCTION(NotBlueprintCallable)
	void LowerBridge(AHazePlayerCharacter Player)
	{
		if (!Game::GetCody().HasControl())
			return;

		if (bPermanentlyLocked)
			return;

		NetLowerBridge();
	}

	UFUNCTION(NetFunction)
	void NetLowerBridge()
	{
		LowerTimeLike.PlayFromStart();
		HazeAkComp.HazePostEvent(LowerBridgeAudioEvent);
		BP_LowerBridge();
	}

	UFUNCTION(BlueprintEvent)
	void BP_LowerBridge() {}

	UFUNCTION(NotBlueprintCallable)
	void UpdateLower(float CurValue)
	{
		float CurPitch = FMath::Lerp(MaxPitch, 0.f, CurValue);

		if (bBlocked)
		{
			CurPitch = FMath::Clamp(CurPitch, 10.5f, MaxPitch);
			if (CurPitch == 10.5f)
			{
				BridgeStoppedByBlockage();
			}
		}

		SetBridgePitch(CurPitch);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishLower()
	{
		OnBridgeFullyLowered.Broadcast();
		HazeAkComp.HazePostEvent(LowerBridgeCompleteAudioEvent);
		RaiseTimerHandle = System::SetTimer(this, n"RaiseBridge", LoweredTime, false);
		bLowered = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void BridgeStoppedByBlockage()
	{
		TimesBlocked++;
		LowerTimeLike.Stop();
		RaiseTimerHandle = System::SetTimer(this, n"RaiseBridge", LoweredTime, false);
		BlockedEffect.Activate(true);
		HazeAkComp.HazePostEvent(StoppedByLockAudioEvent);
		if(TimesBlocked >= 2)
		{
			FName EventName = n"FoghornDBClockworkOutsideBridgeClawHint";
			PlayFoghornVOBankEvent(VOBank, EventName);
		}

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayCameraShake(BlockedCamShake, 0.35f);
			Player.PlayForceFeedback(BlockedForceFeedback, false, true, n"BridgeBlocked");
		}
	}

	UFUNCTION()
	void RaiseBridge()
	{
		if (!Game::GetCody().HasControl())
			return;

		if (bPermanentlyLocked)
			return;

		NetRaiseBridge();
	}

	UFUNCTION(NetFunction)
	void NetRaiseBridge()
	{
		RaiseStartPitch = BridgeRoot.RelativeRotation.Pitch;
		RaiseTimeLike.PlayFromStart();
		HazeAkComp.HazePostEvent(RaiseBridgeAudioEvent);
		bLowered = false;
		BP_RaiseBridge();
	}

	UFUNCTION(BlueprintEvent)
	void BP_RaiseBridge() {}

	UFUNCTION(NotBlueprintCallable)
	void UpdateRaise(float CurValue)
	{
		float CurPitch = FMath::Lerp(RaiseStartPitch, MaxPitch, CurValue);
		SetBridgePitch(CurPitch);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishRaise()
	{
		OnBridgeFullyRaised.Broadcast();
		ConnectedButton.ResetButton();
		HazeAkComp.HazePostEvent(RaiseBridgeCompleteAudioEvent);
	}

	void LockBridge()
	{
		if (bPermanentlyLocked)
			return;

		if (RaiseTimeLike.IsPlaying())
			return;

		if (bLocked)
			return;

		bLocked = true;
		System::ClearAndInvalidateTimerHandle(RaiseTimerHandle);
	}

	void UnlockBridge()
	{
		if (bPermanentlyLocked)
			return;

		if (RaiseTimeLike.IsPlaying())
			return;

		if (!bLocked)
			return;

		bLocked = false;
		RaiseBridge();
	}

	UFUNCTION()
	void PermanentlyLock()
	{
		bPermanentlyLocked = true;
	}

	void SetBridgePitch(float Pitch)
	{
		BridgeRoot.SetRelativeRotation(FRotator(Pitch, 0.f, 0.f));
	}

	bool IsFullyLowered()
	{
		if (bLowered)
			return true;

		return false;
	}

	bool IsLocked()
	{
		if (bLocked)
			return true;

		return false;
	}
}

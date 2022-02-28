import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;
import Vino.Interactions.InteractionComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Interactions.AnimNotify_Interaction;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

event void FOnGeneratorSuccessfullyActivated();

class ASpaceGenerator : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent RootComp;
	default RootComp.Mobility = EComponentMobility::Static;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent GeneratorMesh;
	default GeneratorMesh.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent, Attach = HeadRoot)
	UHazeSkeletalMeshComponentBase HeadMesh;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent LeverBase;
    default LeverBase.RelativeLocation = FVector(190.f, 0.f, 110.f);
    default LeverBase.RelativeRotation = FRotator(0.f, 90.f, -90.f);
	default LeverBase.Mobility = EComponentMobility::Static;

    UPROPERTY(DefaultComponent, Attach = LeverBase)
    UStaticMeshComponent LeverMesh;
    default LeverMesh.RelativeRotation = FRotator(-45.f, 0.f, 0.f);

    UPROPERTY(EditDefaultsOnly)
    FHazeTimeLike RotateLeverTimeLike;
    default RotateLeverTimeLike.Duration = 0.2f;

    FRotator StartRotation;
    FRotator TargetRotation = FRotator(45.f, 0.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UInteractionComponent LeverInteractionPoint;
    default LeverInteractionPoint.RelativeLocation = FVector(250.f, 0.f, 0.f);
    default LeverInteractionPoint.RelativeRotation = FRotator(0.f, 180.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = BatteryBase)
    UInteractionComponent BatteryInteractionPoint;
	default BatteryInteractionPoint.MovementSettings.InitializeSmoothTeleport();
	default BatteryInteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default BatteryInteractionPoint.ActionShape.SphereRadius = 350.f;
	default BatteryInteractionPoint.FocusShape.Type = EHazeShapeType::Sphere;
	default BatteryInteractionPoint.FocusShape.SphereRadius = 1000.f;
	default BatteryInteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent BatteryBase;
	default BatteryBase.Mobility = EComponentMobility::Static;

	UPROPERTY(DefaultComponent, Attach = BatteryBase)
	UHazeSkeletalMeshComponentBase BatteryAnimActor;

	UPROPERTY(DefaultComponent, Attach = BatteryAnimActor)
	UStaticMeshComponent BatteryMesh;

	UPROPERTY(DefaultComponent, Attach = BatteryAnimActor)
	UNiagaraComponent BatteryEffectComp;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(DefaultComponent, Attach = LeverBase)
	UHazeAkComponent HazeAkCompLever;

	UPROPERTY(DefaultComponent, Attach = BatteryBase)
	UHazeAkComponent HazeAkCompBattery;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeverActivatedSuccesfullAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LeverActivatedFailedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BatteryInteractionActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent BatteryDisconnectAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SparkAudioEvent;

	UPROPERTY(Category = "Vo Events")
	UAkAudioEvent FailedEvent;

	UPROPERTY(Category = "Vo Events")
	UAkAudioEvent SuccessEvent;

	UPROPERTY(NotEditable)
    bool bBatteryConnected = false;
    bool bLeverBeingPulled = false;

    UPROPERTY(EditDefaultsOnly)
    UAnimSequence MayAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyAnim;

    UPROPERTY(EditDefaultsOnly)
    FSizeBasedAnimations SizeBasedLeverAnimations;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect BatteryConnectedRumble;

    UPROPERTY()
    FOnGeneratorSuccessfullyActivated OnGeneratorSuccessfullyActivated;

	UPROPERTY(NotVisible)
	bool bGeneratorSuccessfullyActivated = false;

	bool bConnectingBattery = false;
	
	UPROPERTY()
	bool bLeverActiveForCody = true;

	UPROPERTY()
	bool bDisableBatteryUnlessSmall = true;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> ConnectCablesCapability;

	FHazeAnimNotifyDelegate OnLeverHit;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        RotateLeverTimeLike.BindUpdate(this, n"UpdateRotateLever");
        RotateLeverTimeLike.BindFinished(this, n"FinishRotateLever");

		LeverInteractionPoint.OnActivated.AddUFunction(this, n"LeverInteractionActivated");
		BatteryInteractionPoint.OnActivated.AddUFunction(this, n"OnBatteryInteractionActivated");

		if (!bLeverActiveForCody)
			LeverInteractionPoint.DisableForPlayer(Game::GetCody(), n"Gravity");

		Capability::AddPlayerCapabilityRequest(ConnectCablesCapability.Get(), EHazeSelectPlayer::Cody);

		ChangeSizeCallbackComp.OnCharacterChangedSize.AddUFunction(this, n"CodyChangedSize");

		if (bDisableBatteryUnlessSmall)
			BatteryInteractionPoint.DisableForPlayer(Game::GetCody(), n"Size");
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(ConnectCablesCapability.Get(), EHazeSelectPlayer::Cody);
	}

	UFUNCTION(NotBlueprintCallable)
	void CodyChangedSize(FChangeSizeEventTempFix Size)
	{
		if (Size.NewSize == ECharacterSize::Medium)
		{
			LeverInteractionPoint.EnableForPlayer(Game::GetCody(), n"Size");
			if (bDisableBatteryUnlessSmall)
				BatteryInteractionPoint.DisableForPlayer(Game::GetCody(), n"Size");
		}
		else
		{
			LeverInteractionPoint.DisableForPlayer(Game::GetCody(), n"Size");
			if (Size.NewSize == ECharacterSize::Small)
			{
				if (bDisableBatteryUnlessSmall)
					BatteryInteractionPoint.EnableForPlayer(Game::GetCody(), n"Size");
			}
		}
	}

    UFUNCTION()
    void LeverInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
        Player.SmoothSetLocationAndRotation(LeverInteractionPoint.WorldLocation, LeverInteractionPoint.WorldRotation);
        LeverInteractionPoint.Disable(n"LeverPulled");
		
		OnLeverHit.BindUFunction(this, n"LeverHit");
		Player.BindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), OnLeverHit);

		UAnimSequence Anim = Player.IsMay() ? MayAnim : CodyAnim;
        Player.PlayEventAnimation(Animation = Anim);

        bLeverBeingPulled = true;
    }

	UFUNCTION()
	void LeverHit(AHazeActor Actor, UHazeSkeletalMeshComponentBase SkelMeshComp, UAnimNotify AnimNotify)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		Player.UnbindAnimNotifyDelegate(UAnimNotify_Interaction::StaticClass(), OnLeverHit);
		StartRotatingLever();
	}

	UFUNCTION()
	void ForceActivateGenerator()
	{
		bGeneratorSuccessfullyActivated = true;
		BatteryInteractionPoint.Disable(n"ForceActivated");
		LeverInteractionPoint.Disable(n"ForceActivated");
		LeverMesh.SetRelativeRotation(TargetRotation);
		BatteryAnimActor.SetRelativeRotation(FRotator(0.f, -180.f, 0.f));
		BP_ConnectBattery();
	}

	UFUNCTION(NetFunction)
	void NetActivateGenerator()
	{
		OnGeneratorSuccessfullyActivated.Broadcast();
		bGeneratorSuccessfullyActivated = true;
		BP_GeneratorSuccessfullyActivated();
	}
    
    UFUNCTION()
    void OnBatteryInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
        BatteryInteractionPoint.Disable(n"BatteryConnected");
        Player.SetCapabilityAttributeObject(n"SpaceGenerator", this);
        Player.SetCapabilityActionState(n"ConnectCables", EHazeActionState::Active);
		bConnectingBattery = true;
		HazeAkCompBattery.HazePostEvent(BatteryInteractionActivatedAudioEvent);
		BP_BatteryInteractionActivated();
    }

	UFUNCTION(BlueprintEvent)
	void BP_BatteryInteractionActivated() {}

	UFUNCTION(BlueprintEvent)
	void BP_ConnectBattery() {}

	UFUNCTION(BlueprintEvent)
	void BP_DisconnectBattery() {}

    void SetBatteryConnected()
    {
        bBatteryConnected = true;
		BP_ConnectBattery();
		Game::GetCody().PlayForceFeedback(BatteryConnectedRumble, false, true, n"Battery");
		BatteryEffectComp.Activate(true);
		UHazeAkComponent::HazePostEventFireForget(SparkAudioEvent, BatteryEffectComp.GetWorldTransform());
    }

    void SetBatteryDisconnected()
    {
		if (!bGeneratorSuccessfullyActivated)
		{
        	BatteryInteractionPoint.Enable(n"BatteryConnected");
			bBatteryConnected = false;
			bConnectingBattery = false;
			HazeAkCompBattery.HazePostEvent(BatteryDisconnectAudioEvent);
			BP_DisconnectBattery();
		}
    }

    UFUNCTION()
    void StartRotatingLever()
    {
        StartRotation = LeverMesh.RelativeRotation;

        RotateLeverTimeLike.PlayFromStart();

		if (Game::GetCody().HasControl())
		{
			if (bBatteryConnected)
			{
				NetLeverSuccess();
			}
			else
			{
				NetLeverFail();
			}
		}
    }

	UFUNCTION(NetFunction)
	void NetLeverSuccess()
	{
		HeadMesh.SetAnimBoolParam(n"LeverHit", true);
		BP_LeverSuccess();
		HazeAkCompLever.HazePostEvent(LeverActivatedSuccesfullAudioEvent);
		HazeAkCompLever.HazePostEvent(SuccessEvent);
		NetActivateGenerator();
		BatteryEffectComp.Activate(true);
		UHazeAkComponent::HazePostEventFireForget(SparkAudioEvent, BatteryEffectComp.GetWorldTransform());
	}

	UFUNCTION(NetFunction)
	void NetLeverFail()
	{
		HeadMesh.SetAnimBoolParam(n"LeverHit", true);
		BP_LeverFail();
		System::SetTimer(this, n"ResetLever", 1.25f, false);
		HazeAkCompLever.HazePostEvent(LeverActivatedFailedAudioEvent);
		HazeAkCompLever.HazePostEvent(FailedEvent);
		BatteryEffectComp.Activate(true);
		UHazeAkComponent::HazePostEventFireForget(SparkAudioEvent, BatteryEffectComp.GetWorldTransform());
	}

	UFUNCTION(BlueprintEvent)
	void BP_LeverSuccess() {}

	UFUNCTION(BlueprintEvent)
	void BP_LeverFail() {}

    UFUNCTION()
    void UpdateRotateLever(float CurValue)
    {
        FQuat CurQuat = FQuat::Slerp(FQuat(StartRotation), FQuat(TargetRotation), CurValue);

        LeverMesh.SetRelativeRotation(CurQuat.Rotator());
    }

    UFUNCTION()
    void FinishRotateLever()
    {
		if (bGeneratorSuccessfullyActivated)
			return;

		if (bLeverBeingPulled)
		{
			bLeverBeingPulled = false;
		}
		else
		{
			ReactivateLever();
			bLeverBeingPulled = true;
		}
    }

	UFUNCTION()
	void ReactivateLever()
	{
		LeverInteractionPoint.Enable(n"LeverPulled");
	}

	UFUNCTION(BlueprintEvent)
	void BP_GeneratorSuccessfullyActivated() {}

    UFUNCTION()
    void ResetLever()
    {
        RotateLeverTimeLike.ReverseFromEnd();
    }
}
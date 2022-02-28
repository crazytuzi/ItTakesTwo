import Vino.Interactions.InteractionComponent;
import Peanuts.ButtonMash.ButtonMashComponent;
import Vino.DoublePull.DoublePullComponent;
import Peanuts.Spline.SplineActor;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieFightCutieComponent;
import Vino.Interactions.DoubleInteractComponent;
import Vino.Interactions.DoubleInteractionActor;
import Cake.LevelSpecific.PlayRoom.Castle.Bookshelf.CutieWidget;
import Peanuts.Audio.AudioStatics;
event void FOnCutiePhaseActivated(float PhaseNumber);
event void FOnCutiePhaseDeactivated(float PhaseNumber);
event void FOnBothPlayersGrabbedEars();

event void FOnScrubSequencerEars(float Progress);
event void FOnScrubSequencerLegs(float Progress);
event void FOnScrubSequencerArms(float Progress);

event void FOnPlayerReleasedDrag(AHazePlayerCharacter Player);
event void FOnPlayerGrabbedDrag(AHazePlayerCharacter Player);
event void FOnDoublePullStartedVO();
event void FOnDoublePullStartedSecondSplineVO();


class ACutie: AHazeCharacter
{
	UPROPERTY(DefaultComponent, Attach = Base)
    UCapsuleComponent CapsuleComponentHead;

	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent LeftEar;
	default LeftEar.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;
	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent RightEar;
	default RightEar.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent RightArm;
	default RightArm.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;
	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent LeftArm;
	default LeftArm.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent LeftLeg;
	default LeftLeg.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;
	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent RightLeg;
	default RightLeg.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent DragLeftLegCody;
	default DragLeftLegCody.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;
	UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent DragRightLegMay;
	default DragRightLegMay.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteractCompEars;
	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteractCompLegs;
	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteractCompArms;

	UPROPERTY(DefaultComponent, Attach = Base)
    USceneComponent RightArmScene;
	UPROPERTY(DefaultComponent, Attach = Base)
    USceneComponent LeftArmScene;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftProgressnetworked;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightProgressnetworked;

	UPROPERTY(DefaultComponent, Attach = Base)
    UDoublePullComponent DoublePull;
	UPROPERTY()
    ASplineActor SplineActor1;
	UPROPERTY()
    ASplineActor SplineActor2;
	UPROPERTY()
    ASplineActor SplineActor3;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkCompCutie;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CutieStartDragAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CutieStopDragAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CutieStartLegRipAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CutieStopLegRipAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CutieStopEarRipAudioEvent;

	UPROPERTY()
	FOnBothPlayersGrabbedEars OnBothPlayersGrabbedEars;
	UPROPERTY()
	FOnPlayerReleasedDrag OnPlayerReleasedDrag;
	UPROPERTY()
	FOnPlayerGrabbedDrag OnPlayerGrabbedDrag;
	UPROPERTY()
	FOnCutiePhaseActivated OnCutiePhaseActivated;
	UPROPERTY()
	FOnCutiePhaseDeactivated OnCutiePhaseDeactivated;
	UPROPERTY()
	FOnEnterDoublePull OnEnterDoublePull;
	UPROPERTY()
	FOnExitDoublePull OnExitDoublePull;
	UPROPERTY()
	FOnDoublePullStartedVO OnDoublePullStartedVO;
	UPROPERTY()
	FOnDoublePullStartedSecondSplineVO OnDoublePullStartedSecondSplineVO;

	UPROPERTY()
	FOnCompleteDoublePull OnCompleteDoublePull;
	UPROPERTY()
	FOnScrubSequencerEars OnScrubSequencerEars;
	UPROPERTY()
	FOnScrubSequencerLegs OnScrubSequencerLegs;
	UPROPERTY()
	FOnScrubSequencerArms OnScrubSequencerArms;
	float fInterpFloatEar;
	float fInterpFloatLeg;
	float fInterpFloatArm;

	UPROPERTY()
	UHazeLocomotionStateMachineAsset CutieStateMachineAsset;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackButtonMash;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackBurst;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeConstantDoublePull;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeConstantIntensity1;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeConstantIntensity2;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeConstantIntensity3;
	UCameraShakeBase ShakeInstanceDoublePull;
	UCameraShakeBase ShakeInstanceIntensity1;
	UCameraShakeBase ShakeInstanceIntensity2;
	UCameraShakeBase ShakeInstanceIntensity3;

	UCutieFightCutieComponent CutieFightCutieComponent;
	AHazePlayerCharacter Player; 

	bool bCodyIsDoublePulling = false;
	bool bMayIsDoublePulling = false;

	UPROPERTY()
	float PhaseGlobal = 0;
	bool PlayerStartedInLegPull = false;

	float ExpectedLeftEarCD;
	float ExpectedRightEarCD;

	bool bEarDoubleInteractComplete = false;
	bool bLegDoubleInteractComplete = false;
	bool bArmDoubleInteractComplete = false;

	float floatCameraShakeBurst = 0;
	int CurrentCamerShakeIntensityEars = 0;
	int CurrentCamerShakeIntensityLegs = 0;
	int CurrentCamerShakeIntensityArms = 0;
	float DoublePullBurstForceFeedbackFloat;
	UPROPERTY()
	TSubclassOf<UCutieWidget> MovementWidgetClass;
	UCutieWidget MovementWidget;

	bool bWidgetOpacityZero = true;
	bool bWidgetOpacityOne = false;
	bool bNeverShowWidgetAgain = false;
	bool bAllowShowWidget = false;
	float TimeSpentDragging = 0;

	bool bAudioDoublePullStartVOTriggerd = false;
	bool bAudioDoublePullStartSecondSplineVOTriggerd = false;
	UPROPERTY()
	bool bAllowTriggerSecondSplineVO = false;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent LegTrailVFXComponent;
	UPROPERTY(DefaultComponent)
	UNiagaraComponent EarTrailVFXComponent;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		CapsuleComponent.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Spine2"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CapsuleComponentHead.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"Head"), EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, EAttachmentRule::SnapToTarget, false);
		CapsuleComponentHead.AddLocalOffset(FVector(0, 0, 65));

		OnCutiePhaseActivated.AddUFunction(this, n"OnPhaseActivated");
		OnCutiePhaseDeactivated.AddUFunction(this, n"OnPhaseDeactivated");

		DoubleInteractCompEars.OnTriggered.AddUFunction(this, n"OnCompletedInteractingEars");
		LeftEar.OnActivated.AddUFunction(this, n"OnInteractingEar");
		RightEar.OnActivated.AddUFunction(this, n"OnInteractingEar");	

		DoubleInteractCompLegs.OnTriggered.AddUFunction(this, n"OnCompletedInteractingLegs");
		LeftLeg.OnActivated.AddUFunction(this, n"OnInteractingLeg");
		RightLeg.OnActivated.AddUFunction(this, n"OnInteractingLeg");

		DoubleInteractCompArms.OnTriggered.AddUFunction(this, n"OnCompletedInteractingArms");
		LeftArm.OnActivated.AddUFunction(this, n"OnInteractingArm");
		RightArm.OnActivated.AddUFunction(this, n"OnInteractingArm");

		EarTrailVFXComponent.AttachToComponent(Mesh, Mesh.GetSocketBoneName(n"RightEar"), EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		CutieFightCutieComponent = UCutieFightCutieComponent::GetOrCreate(this);
		AddLocomotionAsset(CutieStateMachineAsset, this);
	
		SetUpDoublePull();
		SetPhase(1.f);
    }

	//Networked through other events
	UFUNCTION()
    void SetPhase(float phaseInput)
    {
		OnCutiePhaseDeactivated.Broadcast(phaseInput - 0.5f);
		OnCutiePhaseActivated.Broadcast(phaseInput);
		PhaseGlobal = phaseInput;
    }

	UFUNCTION()
	void LocallyActivateLegCapabilites()
	{
		PhaseGlobal = 4;
		bLegDoubleInteractComplete = true;
	}
	UFUNCTION()
	void LocallyActivateArmCapabilites()
	{
		PhaseGlobal = 6;
		bArmDoubleInteractComplete = true;
	}
	UFUNCTION()
	void LocallyPreActivateButtonMashCapabilites()
	{
		Game::GetCody().SetCapabilityAttributeObject(n"Cutie", this);
		Game::GetMay().SetCapabilityAttributeObject(n"Cutie", this);
	}


	UFUNCTION()
   	void OnPhaseActivated(float PhaseNumber)
  	{
		PrintToScreen("Phase Number Activated   " + PhaseNumber, 5.f);

		//Gives players refences to Cutie & StateMachines
		for (AHazePlayerCharacter iPlayer: Game::GetPlayers())
		{
			if(iPlayer.IsCody())
			{
				iPlayer.AddLocomotionAsset(CutieFightCutieComponent.CodyStateMachineAsset, this);
			}
			else
			{
				iPlayer.AddLocomotionAsset(CutieFightCutieComponent.MayStateMachineAsset, this);
			}
		}

		if(FMath::IsNearlyEqual(PhaseNumber, 2.0f, 0.001f))
		{
			LeftEar.Enable(n"StartDisabled");
			RightEar.Enable(n"StartDisabled");
			HazeAkCompCutie.HazePostEvent(CutieStartLegRipAudioEvent);
		}

		if(FMath::IsNearlyEqual(PhaseNumber, 2.5f, 0.001f))
		{
			HazeAkCompCutie.HazePostEvent(CutieStopLegRipAudioEvent);
		}

		if(FMath::IsNearlyEqual(PhaseNumber, 3.0f, 0.001f))
		{
			HazeAkCompCutie.HazePostEvent(CutieStartDragAudioEvent);

			DoublePull.SwitchToSpline(SplineActor1.Spline, false);
			DragLeftLegCody.Enable(n"StartDisabled");
			DragRightLegMay.Enable(n"StartDisabled");
		}

		// Cutie Start Ear Rip Sound in Shelf_BP

		if(FMath::IsNearlyEqual(PhaseNumber, 4.5f, 0.001f))
		{
			HazeAkCompCutie.HazePostEvent(CutieStopEarRipAudioEvent);
		}

		if(FMath::IsNearlyEqual(PhaseNumber, 5.5f, 0.001f))
		{
			HazeAkCompCutie.HazePostEvent(CutieStopDragAudioEvent);
		}
   	}

	UFUNCTION()
   	void OnPhaseDeactivated(float PhaseNumber){}
	UFUNCTION()
   	void PlayerReleasedLeftArm(AHazePlayerCharacter Player){}

	UFUNCTION()
	void StartLegTrailVFX()
	{
		LegTrailVFXComponent.Activate();
	}
	UFUNCTION()
	void StopLegTrailVFX()
	{
		LegTrailVFXComponent.Deactivate();
	}

	UFUNCTION()
	void StartEarTrailVFX()
	{
		EarTrailVFXComponent.Activate();
	}
	UFUNCTION()
	void StopEarTrailVFX()
	{
		EarTrailVFXComponent.Deactivate();
	}


	UFUNCTION()
	void AddPullWidget()
	{
		MovementWidget = Cast<UCutieWidget>((Game::GetMay().AddWidget(MovementWidgetClass)));
		MovementWidget.SetOpacityInstantly(0);
		MovementWidget.UpdateImage();
		MovementWidget.AttachWidgetToComponent(Mesh, Mesh.GetSocketBoneName(n"Spline"));
		MovementWidget.SetWidgetRelativeAttachOffset(FVector(-20,0, 50));
	}
	UFUNCTION()
	void RemovePullWidget()
	{
		MovementWidget.RemoveWidget();
		bAllowShowWidget = false;
	}
	UFUNCTION()
	void AllowShowWidget(bool Allow)
	{
		bAllowShowWidget = Allow;
		if(!bAllowShowWidget)
		{
			if(MovementWidget != nullptr)
				MovementWidget.SetOpacity(0);

			bWidgetOpacityOne = false;
			bWidgetOpacityZero = true;
		}
	}
	


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(PhaseGlobal == 2)
		{
			fInterpFloatEar = FMath::FInterpTo(fInterpFloatEar, CutieFightCutieComponent.CutieTotalEarProgress, DeltaTime, 2.f);
			OnScrubSequencerEars.Broadcast(fInterpFloatEar);
			HazeAkCompCutie.SetRTPCValue("Rtpc_Character_NPC_Cutie_Rip_TotalProgress", CutieFightCutieComponent.CutieTotalEarProgress);
		}
		if(PhaseGlobal == 4)
		{
			fInterpFloatLeg = FMath::FInterpTo(fInterpFloatLeg, CutieFightCutieComponent.CutieTotalLegProgress, DeltaTime, 2.f);
			OnScrubSequencerLegs.Broadcast(fInterpFloatLeg);
			HazeAkCompCutie.SetRTPCValue("Rtpc_Character_NPC_Cutie_Rip_TotalProgress", CutieFightCutieComponent.CutieTotalLegProgress);
		}
		if(PhaseGlobal == 6)
		{
			fInterpFloatArm= FMath::FInterpTo(fInterpFloatArm, CutieFightCutieComponent.CutieTotalArmProgress, DeltaTime, 2.f);
			OnScrubSequencerArms.Broadcast(fInterpFloatArm);
		}
		if(bEarDoubleInteractComplete && PhaseGlobal == 2)
		{
			CameraShakeLogicEars();
		}
		if(bLegDoubleInteractComplete && PhaseGlobal == 4)
		{
			CameraShakeLogicLegs();
		}
		if(bArmDoubleInteractComplete && PhaseGlobal == 6)
		{
			CameraShakeLogicArms();
		}

		//PrintToScreen("DoublePull.bIsExertingPullEffort " + DoublePull.bIsExertingPullEffort);
		//PrintToScreen("DoublePull.CurrentEffort " + DoublePull.CurrentEffort);
		//PrintToScreen("TimeSpentDragging "+ TimeSpentDragging);
		
		float NormalizedCurrentEffort = HazeAudio::NormalizeRTPC01(DoublePull.CurrentEffort, 0.f, 1.3f);
		//PrintToScreen("cutie velocity " + NormalizedCurrentEffort);
		HazeAkCompCutie.SetRTPCValue("Rtpc_Character_NPC_Cutie_DoublePull_DragVelocity", NormalizedCurrentEffort);

		if(ExpectedLeftEarCD > 0)
		{
			if(Time::GetGameTimeSeconds() >= ExpectedLeftEarCD)
			{
				ExpectedLeftEarCD = -1;
				LeftEar.EnableForPlayer(Game::GetMay(), n"InteractionCooldown");
			}
		}
		if(ExpectedRightEarCD > 0)
		{
			if(Time::GetGameTimeSeconds() >= ExpectedRightEarCD)
			{
				ExpectedRightEarCD = -1;
				RightEar.EnableForPlayer(Game::GetCody(), n"InteractionCooldown");
			}
		}

		if(DoublePull.bIsExertingPullEffort)
		{
			TimeSpentDragging += DeltaTime;
			StartConstantCameraShakeDoublePull();
			ForcefeedbackBurstDoublePull(DeltaTime);

			if(PhaseGlobal != 3)
				return;
			if(TimeSpentDragging > 7)
				bNeverShowWidgetAgain = true;
			if(bWidgetOpacityOne && bAllowShowWidget && MovementWidget != nullptr)
			{
				MovementWidget.SetOpacity(0);
				bWidgetOpacityOne = false;
				bWidgetOpacityZero = true;
			}	

			if(!bAudioDoublePullStartVOTriggerd)
			{
				bAudioDoublePullStartVOTriggerd = true;
				if(this.HasControl())
				{
					AudioDoublePullStartVO();
				}
			}
			if(bAllowTriggerSecondSplineVO)
			{
				if(!bAudioDoublePullStartSecondSplineVOTriggerd)
				{
					bAudioDoublePullStartSecondSplineVOTriggerd = true;
					if(this.HasControl())
					{
						AudioDoublePullStartSecondSplineVO();
					}
				}
			}	
		}
		else
		{
			StopConstantCameraShakeDoublePull();

			if(PhaseGlobal != 3)
				return;
			if(bWidgetOpacityZero && bNeverShowWidgetAgain == false && bAllowShowWidget && MovementWidget != nullptr)
			{
				MovementWidget.SetOpacity(1);
				bWidgetOpacityOne = true;
				bWidgetOpacityZero = false;
			}	
		}
	}

	UFUNCTION(NetFunction)
	void AudioDoublePullStartVO()
	{
		OnDoublePullStartedVO.Broadcast();
	}
	UFUNCTION(NetFunction)
	void AudioDoublePullStartSecondSplineVO()
	{
		OnDoublePullStartedSecondSplineVO.Broadcast();
	}
		


	UFUNCTION(NetFunction)
	void NetOnCancledEarInteraction(UInteractionComponent InteractComponent, AHazePlayerCharacter Player)
	{
		if(Player == Game::GetMay())
		{
			ExpectedLeftEarCD = Time::GetGameTimeSeconds() + 1.5f;
			LeftEar.DisableForPlayer(Player, n"InteractionCooldown");
		}
		else
		{
			ExpectedRightEarCD = Time::GetGameTimeSeconds() + 1.5f;
			RightEar.DisableForPlayer(Player, n"InteractionCooldown");
		}
	}

	UFUNCTION()
	void OnInteractingEar(UInteractionComponent InteractComponent, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"Cutie", this);
	}
	UFUNCTION()
	void OnCancelInteractingEar(UInteractionComponent InteractComponent, AHazePlayerCharacter Player)
	{
		DoubleInteractCompEars.CancelInteracting(Player);
		NetOnCancledEarInteraction(InteractComponent, Player);
	}
	UFUNCTION()
	void OnCompletedInteractingEars()
	{
		bEarDoubleInteractComplete = true;
		if(HasControl())
		{
			NetOnBothPlayersGrabbedEars();
		}
	}
	UFUNCTION(NetFunction)
	void NetOnBothPlayersGrabbedEars()
	{
		OnBothPlayersGrabbedEars.Broadcast();
	}

	UFUNCTION()
    void OnInteractingLeg(UInteractionComponent Component, AHazePlayerCharacter Player) {}
	UFUNCTION()
	void OnCompletedInteractingLegs(){}
	UFUNCTION()
    void OnInteractingArm(UInteractionComponent Component, AHazePlayerCharacter Player){}
	UFUNCTION()
	void OnCompletedInteractingArms(){}
	UFUNCTION(NetFunction)
	void NetOnBothPlayersGrabbedArms(){}



	///Forcefeedback & camerashake
	UFUNCTION()
	void PlayForceFeedback(AHazePlayerCharacter Player)
	{
		Player.PlayForceFeedback(ForceFeedbackButtonMash, true, false, n"ButtonMashStruggle");
	}
	UFUNCTION()
	void StopForceFeedback(AHazePlayerCharacter Player)
	{
		Player.StopForceFeedback(ForceFeedbackButtonMash, n"ButtonMashStruggle");
	}
	UFUNCTION()
	void PlayForceFeedbackBurst(AHazePlayerCharacter Player)
	{
		Player.PlayForceFeedback(ForceFeedbackBurst, false, false, n"ButtonMashStruggleBurst");
	}
	UFUNCTION()
	void CameraShakeLogicEars()
	{
		if(CutieFightCutieComponent.CutieTotalEarProgress >= -1 && CutieFightCutieComponent.CutieTotalEarProgress < 0.25f)
		{
			if(CurrentCamerShakeIntensityEars != 1)
			{
				CurrentCamerShakeIntensityEars = 1;
				StartConstantCameraShake(1);
			}
		}
		if(CutieFightCutieComponent.CutieTotalEarProgress >= 0.25 && CutieFightCutieComponent.CutieTotalEarProgress < 0.60)
		{
			if(CurrentCamerShakeIntensityEars != 2)
			{
				CurrentCamerShakeIntensityEars = 2;
				StartConstantCameraShake(2);
			}
		}
		if(CutieFightCutieComponent.CutieTotalEarProgress >= 0.60)
		{
			if(CurrentCamerShakeIntensityEars != 3)
			{
				CurrentCamerShakeIntensityEars = 3;
				StartConstantCameraShake(3);
			}
		}
	}
	UFUNCTION()
	void CameraShakeLogicLegs()
	{
		if(CutieFightCutieComponent.CutieTotalLegProgress >= -1 && CutieFightCutieComponent.CutieTotalLegProgress < 0.25f)
		{
			if(CurrentCamerShakeIntensityLegs != 1)
			{
				CurrentCamerShakeIntensityLegs = 1;
				StartConstantCameraShake(1);
			}
		}
		if(CutieFightCutieComponent.CutieTotalLegProgress >= 0.25 && CutieFightCutieComponent.CutieTotalLegProgress < 0.60)
		{
			if(CurrentCamerShakeIntensityLegs != 2)
			{
				CurrentCamerShakeIntensityLegs = 2;
				StartConstantCameraShake(2);
			}
		}
		if(CutieFightCutieComponent.CutieTotalLegProgress >= 0.60)
		{
			if(CurrentCamerShakeIntensityLegs != 3)
			{
				CurrentCamerShakeIntensityLegs = 3;
				StartConstantCameraShake(3);
			}
		}
	}
	UFUNCTION()
	void CameraShakeLogicArms()
	{
		if(CutieFightCutieComponent.CutieTotalArmProgress >= -1 && CutieFightCutieComponent.CutieTotalArmProgress < 0.25f)
		{
			if(CurrentCamerShakeIntensityArms != 1)
			{
				CurrentCamerShakeIntensityArms = 1;
				StartConstantCameraShake(1);
			}
		}
		if(CutieFightCutieComponent.CutieTotalArmProgress >= 0.25 && CutieFightCutieComponent.CutieTotalArmProgress < 0.60)
		{
			if(CurrentCamerShakeIntensityArms != 2)
			{
				CurrentCamerShakeIntensityArms = 2;
				StartConstantCameraShake(2);
			}
		}
		if(CutieFightCutieComponent.CutieTotalArmProgress >= 0.60)
		{
			if(CurrentCamerShakeIntensityArms != 3)
			{
				CurrentCamerShakeIntensityArms = 3;
				StartConstantCameraShake(3);
			}
		}
	}
	UFUNCTION()
	void StartConstantCameraShake(int Intensity)
	{
		if(Intensity == 1)
		{
			if(ShakeInstanceIntensity1 == nullptr)
				ShakeInstanceIntensity1 = Game::GetMay().PlayCameraShake(CameraShakeConstantIntensity1, 1.f);
			//ShakeInstanceIntensity1.ShakeScale = 4;
			//ShakeInstanceIntensity1.LocOscillation.X.Frequency = 100;
			if(ShakeInstanceIntensity2 != nullptr)
			{
				Game::GetMay().StopCameraShake(ShakeInstanceIntensity2, false);
				ShakeInstanceIntensity2 = nullptr;
			}
			if(ShakeInstanceIntensity3 != nullptr)
			{
				Game::GetMay().StopCameraShake(ShakeInstanceIntensity3, false);
				ShakeInstanceIntensity3 = nullptr;
			}
		}
		if(Intensity == 2)
		{
			if(ShakeInstanceIntensity2 == nullptr)
				ShakeInstanceIntensity2 = Game::GetMay().PlayCameraShake(CameraShakeConstantIntensity2, 1.f);

			if(ShakeInstanceIntensity3 != nullptr)
			{
				Game::GetMay().StopCameraShake(ShakeInstanceIntensity3, false);
				ShakeInstanceIntensity3 = nullptr;
			}
				if(ShakeInstanceIntensity1 != nullptr)
			{
				Game::GetMay().StopCameraShake(ShakeInstanceIntensity1, false);
				ShakeInstanceIntensity1 = nullptr;
			}
		}
		if(Intensity == 3)
		{
			if(ShakeInstanceIntensity3 == nullptr)
				ShakeInstanceIntensity3 = Game::GetMay().PlayCameraShake(CameraShakeConstantIntensity3, 1.f);

			if(ShakeInstanceIntensity2 != nullptr)
			{
				Game::GetMay().StopCameraShake(ShakeInstanceIntensity2, false);
				ShakeInstanceIntensity2 = nullptr;
			}
			if(ShakeInstanceIntensity1 != nullptr)
			{
				Game::GetMay().StopCameraShake(ShakeInstanceIntensity1, false);
				ShakeInstanceIntensity1 = nullptr;
			}
		}
	}
	UFUNCTION()
	void StopConstantCameraShake()
	{
		if(ShakeInstanceIntensity1 != nullptr)
			Game::GetMay().StopCameraShake(ShakeInstanceIntensity1, true);
		if(ShakeInstanceIntensity2 != nullptr)
			Game::GetMay().StopCameraShake(ShakeInstanceIntensity2, true);
		if(ShakeInstanceIntensity3 != nullptr)
			Game::GetMay().StopCameraShake(ShakeInstanceIntensity3, true);
	}


	UFUNCTION()
	void StartConstantCameraShakeDoublePull()
	{
		if(ShakeInstanceDoublePull == nullptr)
		{
			ShakeInstanceDoublePull = Game::GetMay().PlayCameraShake(CameraShakeConstantDoublePull, 1.f);
		}
	}
	UFUNCTION()
	void StopConstantCameraShakeDoublePull()
	{
		if(ShakeInstanceDoublePull != nullptr)
		{
			Game::GetMay().StopCameraShake(ShakeInstanceDoublePull, false);
			ShakeInstanceDoublePull = nullptr;
		}
	}
	UFUNCTION()
	void ForcefeedbackBurstDoublePull(float DeltaTime)
	{
		Game::GetCody().SetFrameForceFeedback(0, 0.015);
		Game::GetMay().SetFrameForceFeedback(0, 0.015);

		DoublePullBurstForceFeedbackFloat += DeltaTime * 1.3f;
		if(DoublePullBurstForceFeedbackFloat > 1.0)
		{
			PlayForceFeedbackBurst(Game::GetCody());
			PlayForceFeedbackBurst(Game::GetMay());
			DoublePullBurstForceFeedbackFloat = 0;
		}
	}




    ///---------Double pull stuff----------
	UFUNCTION()
	void SetUpDoublePull()
	{
		DragLeftLegCody.DisableForPlayer(Game::GetMay(), n"NotForThisPlayer");
		DragRightLegMay.DisableForPlayer(Game::GetCody(), n"NotForThisPlayer");

		DoublePull.AddTrigger(DragLeftLegCody);
		DoublePull.AddTrigger(DragRightLegMay);

		AddCapability(n"DoublePullSplineCapability");

		DoublePull.OnEnterDoublePull.AddUFunction(this, n"TriggerEnterDoublePull");
		DoublePull.OnExitDoublePull.AddUFunction(this, n"TriggerExitDoublePull");
		DoublePull.OnCompleteDoublePull.AddUFunction(this, n"TriggerCompleteDoublePull");
	}

	UFUNCTION()
	void ResetDoublePull()
	{
		DoublePull.ResetDoublePull();
	}

	UFUNCTION()
	void SwitchToSpline(ASplineActor NewSpline, bool bTeleportToStart = false)
	{
		DoublePull.SwitchToSpline(UHazeSplineComponent::Get(NewSpline), bTeleportToStart);
	}

	UFUNCTION()
	void RemoveFromSpline()
	{
		DoublePull.Spline = nullptr;
	}

	UFUNCTION()
	void EnterDoublePull(AHazePlayerCharacter Player)
	{
		auto Trigger = Player.IsCody() ? DragLeftLegCody : DragRightLegMay;
		DoublePull.EnterDoublePull(Trigger, Player);
	}

	UFUNCTION()
	void ExitDoublePull(AHazePlayerCharacter Player)
	{
		if(Player == Game::GetCody() && bCodyIsDoublePulling == true)
			DoublePull.ExitDoublePull(Player);
		if(Player == Game::GetMay() && bMayIsDoublePulling == true)
			DoublePull.ExitDoublePull(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerEnterDoublePull(AHazePlayerCharacter Player)
	{
		OnEnterDoublePull.Broadcast(Player);
		OnPlayerGrabbedDrag.Broadcast(Player);

		if(Player == Game::GetCody())
			bCodyIsDoublePulling = true;
		if(Player == Game::GetMay())
			bMayIsDoublePulling = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerExitDoublePull(AHazePlayerCharacter Player)
	{
		OnExitDoublePull.Broadcast(Player);
		OnPlayerReleasedDrag.Broadcast(Player);

		if(Player == Game::GetCody())
			bCodyIsDoublePulling = false;
		if(Player == Game::GetMay())
			bMayIsDoublePulling = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerCompleteDoublePull()
	{
		OnCompleteDoublePull.Broadcast();
	}
}


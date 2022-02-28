import Cake.LevelSpecific.Garden.Greenhouse.Joy_CodyTakesOverJoy_AnimNotify;
import Cake.LevelSpecific.Garden.Greenhouse.JoyPotActor;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Cake.LevelSpecific.Garden.Greenhouse.JoyWidget;
event void FOnScrubSequencerPhaseOne(float Progress, int IntButtonMash);
event void FOnScrubSequencerPhaseTwo(float Progress, int IntButtonMash);
event void FOnScrubSequencerPhaseTwoBlob(float Progress, int IntButtonMash);
event void FOnScrubSequencerPhaseThree(float Progress, int IntButtonMash);
event void FOnCodyTookOverJoyPhaseOne();
event void FOnCodyTookOverJoyPhaseTwo();
event void FOnCodyTookOverJoyPhaseThree();
event void FOnCodyHalfWaybuttonMashPhaseOne());
event void FOnCodyHalfWaybuttonMashPhaseTwo();
event void FOnCodyHalfWaybuttonMashPhaseThree();
event void FOnCodyTellMayToAttackBlobPhaseOne());
event void FOnCodyTellMayToAttackBlobPhaseTwo();
event void FOnCodyTellMayToAttackBlobPhaseThree();

class AJoy: AHazeCharacter
{
	default CapsuleComponent.bGenerateOverlapEvents = false;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY()
	AActor BlobRightHand;
	UPROPERTY()
	AActor BlobBack;
	UPROPERTY()
	AActor BlobHead;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncFloatComponent;

	UPROPERTY()
	FOnScrubSequencerPhaseOne OnScrubSequencerPhaseOne;
	UPROPERTY()
	FOnScrubSequencerPhaseTwo OnScrubSequencerPhaseTwo;
	UPROPERTY()
	FOnScrubSequencerPhaseTwo OnScrubSequencerPhaseTwoBlob;
	UPROPERTY()
	FOnScrubSequencerPhaseThree OnScrubSequencerPhaseThree;
	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset MayWaterAimSetting;
	UPROPERTY()
	FOnCodyTookOverJoyPhaseOne OnCodyTookOverJoyPhase1;
	UPROPERTY()
	FOnCodyTookOverJoyPhaseTwo OnCodyTookOverJoyPhase2;
	UPROPERTY()
	FOnCodyTookOverJoyPhaseThree OnCodyTookOverJoyPhase3;
	UPROPERTY()
	FOnCodyHalfWaybuttonMashPhaseOne OnCodyHalfWaybuttonMashPhaseOne;
	UPROPERTY()
	FOnCodyHalfWaybuttonMashPhaseTwo OnCodyHalfWaybuttonMashPhaseTwo;
	UPROPERTY()
	FOnCodyHalfWaybuttonMashPhaseThree OnCodyHalfWaybuttonMashPhaseThree;
	UPROPERTY()
	FOnCodyTellMayToAttackBlobPhaseOne OnCodyTellMayToAttackBlobPhaseOne;
	UPROPERTY()
	FOnCodyTellMayToAttackBlobPhaseTwo OnCodyTellMayToAttackBlobPhaseTwo;
	UPROPERTY()
	FOnCodyTellMayToAttackBlobPhaseThree OnCodyTellMayToAttackBlobPhaseThree;

	UPROPERTY()
	AJoyPotActor PhaseOnePotActor;
	UPROPERTY()
	AJoyPotActor PhaseTwoPotActor;
	UPROPERTY()
	AJoyPotActor PhaseThreePotActor;

	ESummonDirections SummonDirection = ESummonDirections::Center;
	ECorruptionStages CorruptionStage = ECorruptionStages::First;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShakeBurst;
	UPROPERTY()
	UForceFeedbackEffect ForceFeedbackBurst;
	UCameraShakeBase ShakeInstance;
	UMaterialInstanceDynamic MaterialInstances;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioManagerCapabilityClass;

	UPROPERTY()
	TSubclassOf<UHazeCapability> JoyAudioCapabilityClass;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent LeftPlayerInputVectorSync;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent RightPlayerInputVectorSync;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent ButtonMashFloatSync;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent ButtonMashBlobloatSync;
	float ButtonMashProgress = 0;
	float ButtonMashProgressBlob = 0;
	float fInterpFloat;
	float fInterpFloatBlob;

	bool bButtonMashActive = false;
	int IntButtonMash = 0;
	UPROPERTY()
	int Phase = 1;
	bool ButtonMashShouldDeactivate = true;

	bool bCorruptionBlendingActive = false;
	float CurrentCorruptionBlendValue = 0;
	float NewCorruptionBlendValue = 0;

	bool bVineCorruptionBlendingActiveLeft = false;

	bool bBlendToCodyEyes = false;
	bool bBlendToJoyEyes = false;
	float CurrentEyeBlend;
	float TargetEyeBlend;
	float CorruptionBlendTimeMultiplier = 1;

	float CurrentVineCorruptionBlendValueLeft = 0;
	float NewVineCorruptionBlendValueLeft = 0;
	bool bVineCorruptionBlendingActiveMiddle = false;
	float CurrentVineCorruptionBlendValueMiddle = 0;
	float NewVineCorruptionBlendValueMiddle = 0;

	//Network fix
	bool bAllowButtonMashExit = false;
	

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
	{
		SetControlSide(Game::Cody);
//		FHazeAnimNotifyDelegate CodyTakesOverJoyDelegate;
//		CodyTakesOverJoyDelegate.BindUFunction(this, n"CodyTookOverJoy");
//		BindAnimNotifyDelegate(UAnimNotify_CodyTakesOverJoy::StaticClass(), CodyTakesOverJoyDelegate);
		ButtonMashFloatSync.OverrideControlSide(Game::GetCody());
		ButtonMashBlobloatSync.OverrideControlSide(Game::GetCody());
		LeftPlayerInputVectorSync.OverrideControlSide(Game::GetCody());
		RightPlayerInputVectorSync.OverrideControlSide(Game::GetCody());

		AddCapability(AudioManagerCapabilityClass);
		AddCapability(JoyAudioCapabilityClass);
	}
	
	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
	{
		StopCameraShakeCodyControllJoy();
		UWaterHoseComponent WaterComponent; 
		WaterComponent = Cast<UWaterHoseComponent>(Game::GetMay().GetComponentByClass(UWaterHoseComponent::StaticClass()));
		if(WaterComponent != nullptr)
			WaterComponent.SetCustomAimCameraSettings(nullptr);
	}

	UFUNCTION()
	void AddWaterHoseBossAim()
	{
		UWaterHoseComponent WaterComponent; 
		WaterComponent = Cast<UWaterHoseComponent>(Game::GetMay().GetComponentByClass(UWaterHoseComponent::StaticClass()));
		WaterComponent.SetCustomAimCameraSettings(MayWaterAimSetting);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		//PrintToScreen("CurrentCorruptionBlendValue " + CurrentCorruptionBlendValue);
		//PrintToScreen("Phase " + Phase);
		if(bButtonMashActive == true)
		{
			if(Game::GetCody().HasControl())
			{
				fInterpFloat = FMath::FInterpTo(fInterpFloat, ButtonMashProgress, DeltaSeconds * 1.f, 2.f);
				ButtonMashFloatSync.Value = fInterpFloat;
			}
			else
			{
				fInterpFloat = ButtonMashFloatSync.Value;
			}

			if(Game::GetCody().HasControl())
			{
				fInterpFloatBlob = FMath::FInterpTo(fInterpFloatBlob, ButtonMashProgressBlob, DeltaSeconds, 2.f);
				ButtonMashBlobloatSync.Value = fInterpFloatBlob;
			}
			else
			{
				fInterpFloatBlob = ButtonMashBlobloatSync.Value;
			}


		//	Print("ButtonMashFloatSync.Value " + ButtonMashFloatSync.Value );
		//	Print("ButtonMashBlobloatSync.Value  " + ButtonMashBlobloatSync.Value );
	
			if(Phase == 1)
			{
				if(IntButtonMash == 1)
				{
					ScrubSequencerEventPhaseOne(fInterpFloat);
				}
			}
			if(Phase == 2)
			{
				if(IntButtonMash == 2 or IntButtonMash == 3)
				{
					ScrubSequencerEventPhaseTwo(fInterpFloat);
					ScrubSequencerEventPhaseTwoBlob(fInterpFloatBlob);
				}
			}
			if(Phase == 3)
			{
				if(IntButtonMash == 4)
				{
					ScrubSequencerEventPhaseThree(fInterpFloat);
				}
			}
		}

		if(bCorruptionBlendingActive == true)
		{
			CurrentCorruptionBlendValue = FMath::FInterpTo(CurrentCorruptionBlendValue, NewCorruptionBlendValue + 0.1, DeltaSeconds, 0.35f * CorruptionBlendTimeMultiplier);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValue", CurrentCorruptionBlendValue);
			if(NewCorruptionBlendValue <= CurrentCorruptionBlendValue)
			{
				bCorruptionBlendingActive = false;
			}
		}
		if(bVineCorruptionBlendingActiveLeft == true)
		{
			CurrentVineCorruptionBlendValueLeft = FMath::FInterpTo(CurrentVineCorruptionBlendValueLeft, NewVineCorruptionBlendValueLeft + 0.1, DeltaSeconds, 0.65f);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendVineLeft", CurrentVineCorruptionBlendValueLeft);
			if(NewVineCorruptionBlendValueLeft <= CurrentVineCorruptionBlendValueLeft)
			{
				bVineCorruptionBlendingActiveLeft = false;
			}
		}
		if(bVineCorruptionBlendingActiveMiddle == true)
		{
			CurrentVineCorruptionBlendValueMiddle = FMath::FInterpTo(CurrentVineCorruptionBlendValueMiddle, NewVineCorruptionBlendValueMiddle + 0.1, DeltaSeconds, 0.65f);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendVineMiddle", CurrentVineCorruptionBlendValueMiddle);
			if(NewVineCorruptionBlendValueMiddle <= CurrentVineCorruptionBlendValueMiddle)
			{
				bVineCorruptionBlendingActiveMiddle = false;
			}
		}

		if(bBlendToCodyEyes == true)
		{
			CurrentEyeBlend = FMath::FInterpTo(CurrentEyeBlend, TargetEyeBlend + 0.1, DeltaSeconds, 1.85f);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValueCody", CurrentEyeBlend);
			//PrintToScreen("CurrentEyeBlend " + CurrentEyeBlend);
			if(TargetEyeBlend <= CurrentEyeBlend)
			{
				bBlendToCodyEyes = false;
			}
		}
		if(bBlendToJoyEyes == true)
		{
			CurrentEyeBlend = FMath::FInterpTo(CurrentEyeBlend, TargetEyeBlend - 0.1, DeltaSeconds, 1.35f);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValueCody", CurrentEyeBlend);
			//PrintToScreen("CurrentEyeBlend " + CurrentEyeBlend);
			if(TargetEyeBlend >= CurrentEyeBlend)
			{
				bBlendToJoyEyes = false;
			}
		}
	}

	UFUNCTION()
	void BlendCorruption(ECorruptionStages Stage)
	{
		if(Stage == ECorruptionStages::First)
		{
			CorruptionBlendTimeMultiplier = 1;
			bCorruptionBlendingActive = true;
			NewCorruptionBlendValue = 0.10f;
			System::SetTimer(this, n"StartLeftVineBlendCorruption", 1.f, false);
		}
		if(Stage == ECorruptionStages::Second)
		{
			CorruptionBlendTimeMultiplier = 1;
			bCorruptionBlendingActive = true;
			NewCorruptionBlendValue = 0.15f;
			System::SetTimer(this, n"StartMiddleVineBlendCorruption", 1.f, false);
		}
		if(Stage == ECorruptionStages::Third)
		{
			CorruptionBlendTimeMultiplier = 0.35f;
			bCorruptionBlendingActive = true;
			NewCorruptionBlendValue = 1.0f;
		}
	}
	UFUNCTION()
	void StartLeftVineBlendCorruption()
	{
		bVineCorruptionBlendingActiveLeft = true;
		NewVineCorruptionBlendValueLeft = 1.2f;
	}
	UFUNCTION()
	void StartMiddleVineBlendCorruption()
	{
		bVineCorruptionBlendingActiveMiddle = true;
		NewVineCorruptionBlendValueMiddle = 1.2f;
	}

	UFUNCTION()
	void BlendToCodysEyes()
	{
		bBlendToCodyEyes = true;
		TargetEyeBlend = 1;
	}
	UFUNCTION()
	void BlendToJoysEyes()
	{
		bBlendToJoyEyes = true;
		TargetEyeBlend = 0;
	}


	UFUNCTION()
	void InstantBlendCorruption(ECorruptionStages Stage)
	{
		if(Stage == ECorruptionStages::First)
		{
			CurrentCorruptionBlendValue = 0.10f;
			NewCorruptionBlendValue = 0.10f;
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValue", 0.10f);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValueAlpha", 1);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendVineLeft", 1);
		}
		if(Stage == ECorruptionStages::Second)
		{
			CurrentCorruptionBlendValue = 0.15f;
			NewCorruptionBlendValue = 0.15f;
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValue", 0.15f);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValueAlpha", 1);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendVineLeft", 1);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendVineMiddle", 1);
		}
		if(Stage == ECorruptionStages::Third)
		{
			CurrentCorruptionBlendValue = 1.0f;
			NewCorruptionBlendValue = 1.0f;
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValue", 1.0f);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendValueAlpha", 1);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendVineLeft", 1);
			Mesh.SetScalarParameterValueOnMaterials(n"BlendVineMiddle", 1);
		}
	}

	UFUNCTION()
	void CodyTookOverJoy()
	{
		if(Phase == 1)
		{
			OnCodyTookOverJoyPhase1.Broadcast();
			StartButtonMash(1);
		}
		if(Phase == 2)
		{
			OnCodyTookOverJoyPhase2.Broadcast();	
			StartButtonMash(2);
		}
		if(Phase == 3)
		{
 			OnCodyTookOverJoyPhase3.Broadcast();
			StartButtonMash(3);
		}
	}

	UFUNCTION()
	void PreActivateRefenceJoyButtonMash()
	{
		Game::GetCody().SetCapabilityAttributeObject(n"Joy", this);
	}
	UFUNCTION()
	void StartButtonMash(int PhaseNumber)
	{
		bButtonMashActive = true;
		SetAnimBoolParam(n"CodyTakesControl", true);
		ButtonMashShouldDeactivate = false;

		SetCapabilityAttributeNumber(n"AudioStartedButtonMash", PhaseNumber);
	}
	UFUNCTION()
	void JoyStopButtonMash()
	{
		ButtonMashShouldDeactivate = true;
		SetCapabilityActionState(n"AudioStoppedButtonMash", EHazeActionState::ActiveForOneFrame);
	}

	//VO 
	UFUNCTION(NetFunction)
	void VOCodyHalfWayButtonMashPhaseOne()
	{
		OnCodyHalfWaybuttonMashPhaseOne.Broadcast();
	}
	UFUNCTION(NetFunction)
	void VOCodyHalfWayButtonMashPhaseTwo()
	{
		OnCodyHalfWaybuttonMashPhaseTwo.Broadcast();
	}
	UFUNCTION(NetFunction)
	void VOCodyHalfWayButtonMashPhaseThree()
	{
		OnCodyHalfWaybuttonMashPhaseThree.Broadcast();
	}
	UFUNCTION(NetFunction)
	void VOCodyTellsMayToAttackBlobPhaseOne()
	{
		OnCodyTellMayToAttackBlobPhaseOne.Broadcast();
	}
	UFUNCTION(NetFunction)
	void VOCodyTellsMayToAttackBlobPhaseTwo()
	{
		OnCodyTellMayToAttackBlobPhaseTwo.Broadcast();
	}
	UFUNCTION(NetFunction)
	void VOCodyTellsMayToAttackBlobPhaseThree()
	{
		OnCodyTellMayToAttackBlobPhaseThree.Broadcast();
	}
	
	

	UFUNCTION()
	void SetPhaseNumber(int PhaseNumber)
	{
		Phase = PhaseNumber;
	//	if(this.HasControl())
	//	{
	//		NetSetPhaseNumber(PhaseNumber);
	//	}
	}
//	UFUNCTION(NetFunction)
//	void NetSetPhaseNumber(int PhaseNumber)
//	{
//		Phase = PhaseNumber;
//	}

	UFUNCTION()
	void StartSummonAnimation(ESummonDirections SummonDirectionLocal)
	{
		if(SummonDirectionLocal == ESummonDirections::LeftRight)
		{
			SetAnimBoolParam(n"SummonLeftRight", true);
		}
		if(SummonDirectionLocal == ESummonDirections::Center)
		{
			SetAnimBoolParam(n"SummonCenter", true);
		}

		SetCapabilityActionState(n"AudioSummonHammerPlants", EHazeActionState::Active);
	}
	
	UFUNCTION()
	void StartAnimationJoyThrowPot(int Pot)
	{
		if(Pot == 1)
		{
			PhaseOnePotActor.AttachToComponent(Mesh, n"LeftAttach", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			PhaseOnePotActor.AddActorLocalOffset(FVector(0, 0, 0));
			//System::SetTimer(this, n"DettachPotActorFromJoy", 5.f, false);
		}
		if(Pot == 2)
		{
			PhaseTwoPotActor.AttachToComponent(Mesh, n"LeftAttach", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			PhaseTwoPotActor.AddActorLocalOffset(FVector(0, 0, 0));
			//System::SetTimer(this, n"DettachPotActorFromJoy", 5.f, false);
		}
		if(Pot == 3)
		{
			PhaseThreePotActor.AttachToComponent(Mesh, n"LeftAttach", EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			PhaseThreePotActor.AddActorLocalOffset(FVector(0, 0, 0));
			//System::SetTimer(this, n"DettachPotActorFromJoy", 5.f, false);
		}
	}

	UFUNCTION()
	void PlayCameraShakeCodyControllJoy()
	{
		ShakeInstance = Game::GetCody().PlayCameraShake(CameraShake, 1.f);
		//Game::GetCody().PlayForceFeedback(ForceFeedback, true, false, n"JoyStruggle");
		Print("ShakeStarted ", 3.f);
	}
	UFUNCTION()
	void StopCameraShakeCodyControllJoy()
	{
		Print("ShakeStopped ", 3.f);
		Game::GetCody().StopForceFeedback(ForceFeedback, n"JoyStruggle");
		if(ShakeInstance != nullptr)
			Game::GetCody().StopCameraShake(ShakeInstance, true);
	}
	UFUNCTION()
	void PlayCameraShakeCodyControllJoyBurst()
	{
		Game::GetCody().PlayCameraShake(CameraShakeBurst, 1.f);
		Game::GetCody().PlayForceFeedback(ForceFeedbackBurst, false, false, n"JoyBurstStruggle");
	}


	UFUNCTION()
	void ScrubSequencerEventPhaseOne(float Progress)
	{
		OnScrubSequencerPhaseOne.Broadcast(Progress, IntButtonMash);
	}
	UFUNCTION()
	void ScrubSequencerEventPhaseTwo(float Progress)
	{
		OnScrubSequencerPhaseTwo.Broadcast(Progress, IntButtonMash);
	}
	UFUNCTION()
	void ScrubSequencerEventPhaseTwoBlob(float Progress)
	{
		OnScrubSequencerPhaseTwoBlob.Broadcast(Progress, IntButtonMash);
	}
	UFUNCTION()
	void ScrubSequencerEventPhaseThree(float Progress)
	{
		OnScrubSequencerPhaseThree.Broadcast(Progress, IntButtonMash);
	}
}

enum ESummonDirections
{
	LeftRight,
	Center
}

enum ECorruptionStages
{
	First,
	Second,
	Third
}


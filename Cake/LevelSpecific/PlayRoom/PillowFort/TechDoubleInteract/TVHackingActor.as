import Vino.Camera.Actors.StaticCamera;
import Cake.Environment.HazeSphere;
import Cake.LevelSpecific.PlayRoom.VOBanks.PillowFortVOBank;

enum ETVStateEnum
{
	NotPlaying,
	StartScreen,
	Level1,
	Level2,
	Level3,
	CounterHack,
	GameFailed
}

enum ECounterHackStates
{
	Level1,
	Level2,
	Level3,
	Level4
}

event void FOnHackCompleteEventSignature(AHazePlayerCharacter LeftPlayer, AHazePlayerCharacter RightPlayer, AHazePlayerCharacter FullScreenPlayer);
event void FOnCounterHackStartedEventSignature();
event void FOnCounterHackCompletedEventSignature();
event void FOnFinalHackLevelCompletedEventSignature();
event void FOnHackingInteractedEventSignature();
event void FOnHackingStateChangedEventSignature(ETVStateEnum State);
event void FOnHackingPlayerLeftInteractionEventSignature();

class ATVHackingActor : AHazeActor
{

//Components
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Settings")
	float ControlSpeed = 0.2;
	UPROPERTY(Category = "Settings")
	float PlayerSpeed = 0.4f;
	UPROPERTY(Category = "Settings")
	float HoldRequiredTime = 2.5f;
	UPROPERTY(Category = "Settings")
	float CompletionLeniency = 0.05f;

	bool bPlayer1Complete = false;
	bool bPlayer2Complete = false;
	bool bInteractionCompleted = false;
	bool bInteractionActive = false;
	bool bNextLevelPreloadStarted = false;

	float InteractionProgress = 0.f;
	int AmountOfGameplayLevels = 3;
	float ProgressPerLevel = 0.33f;

	UPROPERTY(Category = "Setup")
	int InteractiveMaterialIndex = 1;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	TSubclassOf<UHazeCapability> StartScreenCapability;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	TSubclassOf<UHazeCapability> GamePlayLevel1Capability;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)	
	TSubclassOf<UHazeCapability> GamePlayLevel2Capability;
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	TSubclassOf<UHazeCapability> GamePlayLevel3Capability;	
	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	TSubclassOf<UHazeCapability> CounterHackCapability;

	UPROPERTY()
	FOnHackCompleteEventSignature HackCompleteEvent;
	UPROPERTY()
	FOnCounterHackStartedEventSignature StartCounterHackEvent;
	UPROPERTY()
	FOnCounterHackCompletedEventSignature CompletedCounterHackEvent;
	UPROPERTY()
	FOnFinalHackLevelCompletedEventSignature FinalLevelCompleted;
	UPROPERTY()
	FOnHackingInteractedEventSignature OnHackingBothInteracted;
	UPROPERTY()
	FOnHackingStateChangedEventSignature StateChanged;
	UPROPERTY()
	FOnHackingPlayerLeftInteractionEventSignature PlayerLeftInteractionEvent;

	UPROPERTY(Category = "Setup")
	ETVStateEnum TVState = ETVStateEnum::StartScreen;

	UPROPERTY(Category = "Setup")
	ETVStateEnum DebugState = ETVStateEnum::StartScreen;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance StartScreen;
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance Level1Screen;
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance Level2Screen;
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance Level3Screen;
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance CounterHackScreen;
	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UMaterialInstance GameFailedScreen;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASceneCapture2D SceneCapture;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AStaticCamera InteractionCameraFullScreen;
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AStaticCamera InteractionCameraSplitScreen;
	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AStaticCamera InteractionCameraCounterHack;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	UPillowFortVOBank VOBankAsset;

	UPROPERTY(Category = "Settings")
	FLinearColor SpotlightCounterhackColor;
	UPROPERTY(Category = "Settings")
	FLinearColor HazeSphereCounterhackColor;

	//Camera Impulses
	UPROPERTY(Category = "Settings")
	FHazeCameraImpulse Counterhack1Impulse;
	UPROPERTY(Category = "Settings")
	FHazeCameraImpulse Counterhack2Impulse;
	UPROPERTY(Category = "Settings")
	FHazeCameraImpulse Counterhack3Impulse;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	ASpotLight TVSpotlight;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AHazeSphere TVHazeSphere;

	FVector2D Player1Input = FVector2D::ZeroVector;
	FVector2D Player2Input = FVector2D::ZeroVector;

	FVector2D Player1Position = FVector2D::ZeroVector;
	FVector2D Player2Position = FVector2D::ZeroVector;

	FVector2D Player1TargetPosition = FVector2D::ZeroVector;
	FVector2D Player2TargetPosition = FVector2D::ZeroVector;

	float Player1ButtonMashRate = 0.f;
	float Player2ButtonMashRate = 0.f;

	bool bBothPlayersInteracting = false;
	bool bHasReminderBarkFired = false;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent Player1SynchedMashRate;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent Player2SynchedMashRate;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent HackProgressSynchedFloat;
	default HackProgressSynchedFloat.Value = 1.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.bRenderWhileDisabled = true;
	default DisableComp.AutoDisableRange = 5000.f;

	AHazePlayerCharacter LeftPlayer;
	AHazePlayerCharacter RightPlayer;

	AHazePlayerCharacter FullScreenPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(StartScreenCapability);
		AddCapability(GamePlayLevel1Capability);
		AddCapability(GamePlayLevel2Capability);
		AddCapability(GamePlayLevel3Capability);
		AddCapability(CounterHackCapability);

		if(DebugState != TVState)
			if(HasControl())
				ChangeState(DebugState);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!ButtonMashActive && (LeftPlayer == nullptr || RightPlayer == nullptr))
			return;

		if(!LeftPlayer.HasControl())
		{
			Player1ButtonMashRate = Player1SynchedMashRate.Value;
		}
		else
		{
			Player2ButtonMashRate = Player2SynchedMashRate.Value;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		SceneCapture.CaptureComponent2D.bCaptureEveryFrame = false;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		SceneCapture.CaptureComponent2D.bCaptureEveryFrame = true;
	}

//	Input
	void HandlePlayer1Input(FVector2D Input)
	{
		Player1Input = Input;
	}

	void HandlePlayer2Input(FVector2D Input)
	{
		Player2Input = Input;
	}

	UFUNCTION()
	void HandlePlayer1ButtonMash(float ButtonMash)
	{
		if(LeftPlayer != nullptr && LeftPlayer.HasControl())
		{
			Player1SynchedMashRate.Value = ButtonMash;
			Player1ButtonMashRate = ButtonMash;
		}
		else if(LeftPlayer != nullptr && !LeftPlayer.HasControl())
		{
			Player1ButtonMashRate = Player1SynchedMashRate.Value;
		}
	}

	UFUNCTION()
	void HandlePlayer2ButtonMash(float ButtonMash)
	{
		if(RightPlayer != nullptr && RightPlayer.HasControl())
		{
			Player2SynchedMashRate.Value = ButtonMash;
			Player2ButtonMashRate = ButtonMash;
		}
		else if(RightPlayer != nullptr && !RightPlayer.HasControl())
		{
			Player2ButtonMashRate = Player2SynchedMashRate.Value;
		}
	}

	bool ButtonMashActive = false;

// 	States/Activations/Events
	void ActivateButtonMash()
	{
		StartCounterHackEvent.Broadcast();
		ButtonMashActive = true;
	}

	void DeactivateButtonMash()
	{
		CompletedCounterHackEvent.Broadcast();
		ButtonMashActive = false;
	}

	UFUNCTION(NetFunction)
	void SwitchInputEnabled(bool Enable)
	{
		if(Enable)
		{
			if(LeftPlayer != nullptr)
				LeftPlayer.UnblockCapabilities(n"HackingInput", this);
			if(RightPlayer != nullptr)
				RightPlayer.UnblockCapabilities(n"HackingInput", this);
		}
		else
		{
			if(LeftPlayer != nullptr)
				LeftPlayer.BlockCapabilities(n"HackingInput", this);
			if(RightPlayer != nullptr)
				RightPlayer.BlockCapabilities(n"HackingInput", this);
		}
	}

	void InteractedLeftRemote(AHazePlayerCharacter Player)
	{
		LeftPlayer = Player;
		SetCapabilityActionState(n"Player1Playing", EHazeActionState::Active);
		Player1SynchedMashRate.OverrideControlSide(Player);

		VerifyBothPlayersInteracting();
	}

	void InteractedRightRemote(AHazePlayerCharacter Player)
	{
		RightPlayer = Player;
		SetCapabilityActionState(n"Player2Playing", EHazeActionState::Active);
		Player2SynchedMashRate.OverrideControlSide(Player);

		VerifyBothPlayersInteracting();
	}

	void ExitedLeftRemote()
	{
		LeftPlayer = nullptr;
		SetCapabilityActionState(n"Player1Playing", EHazeActionState::Inactive);
		PlayerLeftInteractionEvent.Broadcast();
	}

	void ExitedRightRemote()
	{
		RightPlayer = nullptr;
		SetCapabilityActionState(n"Player2Playing", EHazeActionState::Inactive);
		PlayerLeftInteractionEvent.Broadcast();
	}

	void VerifyBothPlayersInteracting()
	{
		if(LeftPlayer != nullptr && RightPlayer != nullptr)
		{
			bBothPlayersInteracting = true;
			OnHackingBothInteracted.Broadcast();
		}
	}

	UFUNCTION(NetFunction)
	void ChangeState(ETVStateEnum NewState)
	{
		switch(NewState)
		{
			case(ETVStateEnum::NotPlaying):
				{
					ChangeMaterial(StartScreen);
					break;
				}
			case(ETVStateEnum::StartScreen):
				{
					ChangeMaterial(StartScreen);
					break;
				}
			case(ETVStateEnum::Level1):
				{	
					ChangeMaterial(Level1Screen);
					break;
				}
			case(ETVStateEnum::Level2):
				{
					ChangeMaterial(Level2Screen);
					break;
				}
			case(ETVStateEnum::Level3):
				{
					ChangeMaterial(Level3Screen);
					break;
				}
			case(ETVStateEnum::CounterHack):
				{
					ChangeMaterial(CounterHackScreen);
					break;
				}
			case(ETVStateEnum::GameFailed):
				{
					ChangeMaterial(GameFailedScreen);
					break;
				}
			default:
				break;
		}
		StateChanged.Broadcast(NewState);
		TVState = NewState;
	}

	UFUNCTION(BlueprintEvent)
	void StateSwitch()
	{

	}

	void CompleteGame()
	{
		ButtonMashActive = false;
		bInteractionCompleted = true;

		Game::May.DeactivateCameraByInstigator(this);
		Game::Cody.DeactivateCameraByInstigator(this);

		HackCompleteEvent.Broadcast(LeftPlayer, RightPlayer, FullScreenPlayer);
	}

	void DisableInteractionExit()
	{
		FinalLevelCompleted.Broadcast();
	}

//	Material / Shader Functions / Lights
	void ChangeMaterial(UMaterialInstance Material)
	{
		BaseMesh.SetMaterial(InteractiveMaterialIndex, Material);
	}

	UFUNCTION(NetFunction)
	void SetScalarParam(FName ParamName, float Value)
	{
		BaseMesh.SetScalarParameterValueOnMaterialIndex(InteractiveMaterialIndex, ParamName, Value);
	}

	UFUNCTION(NetFunction)
	void SetPositionParam(FName ParamName, FLinearColor Value)
	{
		BaseMesh.SetColorParameterValueOnMaterialIndex(InteractiveMaterialIndex, ParamName, Value);
	}

	void SwitchToCounterhackLightColor()
	{
		TVSpotlight.SpotLightComponent.SetLightColor(SpotlightCounterhackColor);
		TVHazeSphere.HazeSphereComponent.SetColor(TVHazeSphere.HazeSphereComponent.Opacity, TVHazeSphere.HazeSphereComponent.Softness, HazeSphereCounterhackColor);
	}

//	Camera

	UFUNCTION(NetFunction)
	void VerifyCameraToActivate(AHazePlayerCharacter Player)
	{
		if(InteractionCameraFullScreen != nullptr && InteractionCameraSplitScreen != nullptr)
		{
			FHazeCameraBlendSettings BlendSettings;
			BlendSettings.BlendTime = 1.f;

			if(LeftPlayer != nullptr && RightPlayer != nullptr)
			{
				InteractionCameraFullScreen.ActivateCamera(Player, BlendSettings, this);
				Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
				FullScreenPlayer = Player;
			}
			else
			{
				InteractionCameraSplitScreen.ActivateCamera(Player, BlendSettings, this);
			}
		}
	}

	UFUNCTION(NetFunction)
	void VerifyCameraToDeactivate(AHazePlayerCharacter Player, bool IsLeftPlayer)
	{
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;

		if(InteractionCameraFullScreen != nullptr && InteractionCameraSplitScreen != nullptr)
		{
			if(IsLeftPlayer)
			{
				if(RightPlayer != nullptr)
				{
					InteractionCameraSplitScreen.DeactivateCamera(Player);
					InteractionCameraFullScreen.DeactivateCamera(Player);
					InteractionCameraSplitScreen.ActivateCamera(RightPlayer, BlendSettings, this);				
					RightPlayer.ClearViewSizeOverride(this);
				}
				else
				{
					InteractionCameraSplitScreen.DeactivateCamera(Player);
				}

				Player.ClearViewSizeOverride(this);
			}
			else
			{
				if(LeftPlayer != nullptr)
				{
					InteractionCameraSplitScreen.DeactivateCamera(Player);
					InteractionCameraFullScreen.DeactivateCamera(Player);
					InteractionCameraSplitScreen.ActivateCamera(LeftPlayer, BlendSettings, this);				
					LeftPlayer.ClearViewSizeOverride(this);
				}
				else
				{
					InteractionCameraSplitScreen.DeactivateCamera(Player);
				}

				Player.ClearViewSizeOverride(this);
			}
		}
	}

	void ActivateCounterHackCamera()
	{
		FHazeCameraBlendSettings BlendSettings;
		BlendSettings.BlendTime = 1.f;

		InteractionCameraCounterHack.ActivateCamera(LeftPlayer, BlendSettings, this);
		InteractionCameraCounterHack.ActivateCamera(RightPlayer, BlendSettings, this);
	}

	void DeactivateCounterHackCamera()
	{
		InteractionCameraCounterHack.DeactivateCamera(LeftPlayer);
		InteractionCameraCounterHack.DeactivateCamera(RightPlayer);
	}

	void ShakeCounterHackCamera(ECounterHackStates CounterhackState)
	{
		FHazeCameraImpulse Impulse;

		switch(CounterhackState)
		{
			case(ECounterHackStates::Level2):
				Impulse = Counterhack1Impulse;
				break;
			case(ECounterHackStates::Level3):
				Impulse = Counterhack2Impulse;
				break;
			case(ECounterHackStates::Level4):
				Impulse = Counterhack3Impulse;
				break;
			default:
				break;
		}

		if(LeftPlayer != nullptr)
			LeftPlayer.ApplyCameraImpulse(Impulse, this);
		if(RightPlayer != nullptr)
			RightPlayer.ApplyCameraImpulse(Impulse, this);
	}

//	ForceFeedback
	void ApplyForceFeedback(float Value = 0.2f)
	{
		if(LeftPlayer != nullptr)
			LeftPlayer.SetFrameForceFeedback(Value , Value);
		if(RightPlayer != nullptr)
			RightPlayer.SetFrameForceFeedback(Value , Value);
	}

	void ApplySpecificForceFeedback(float Value)
	{
		if(LeftPlayer != nullptr)
			LeftPlayer.SetFrameForceFeedback(Value, Value);
		if(RightPlayer != nullptr)
			RightPlayer.SetFrameForceFeedback(Value, Value);
	}


//VO Events
	UFUNCTION(NetFunction)
	void TriggerReminderBark(FName EventName)
	{
		VOBankAsset.PlayFoghornVOBankEvent(EventName);
		bHasReminderBarkFired = true;
	}

	UFUNCTION(NetFunction)
	void TriggerStartScreenDialogue()
	{
		VOBankAsset.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomPillowFortHackingGameFirstScreenHint");
	}

	UFUNCTION(NetFunction)
	void TriggerHackingDialogue()
	{
		VOBankAsset.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomPillowFortHackingGameGeneric");
	}

	UFUNCTION(NetFunction)
	void TriggerCounterhackDialogue()
	{
		VOBankAsset.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomPillowFortHackingGameCounterHack");
	}

	UFUNCTION(NetFunction)
	void TriggerCounterHackExertDialogue()
	{
		VOBankAsset.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomPillowFortHackingGameCounterHackMidway");
	}
}
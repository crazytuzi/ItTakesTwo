import Peanuts.Fades.FadeStatics;
import Vino.Camera.Capabilities.LookatFocusPointComponent;
import Vino.Camera.CameraStatics;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;
event void FOnTransitionCompleteLeft(AHazePlayerCharacter Player);
event void FOnTransitionCompleteRight(AHazePlayerCharacter Player);
class AOldPictureToy : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)	
	UStaticMeshComponent Mesh;
	UPROPERTY(DefaultComponent)	
	USceneComponent FakePictureWheelRoot;
	UPROPERTY(DefaultComponent, Attach = FakePictureWheelRoot)	
	UStaticMeshComponent FakePictureWheel;
	FRotator StartFakePictureWheelRotation;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 15000.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TurnAudioEvent;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VODataBankAsset;

	UPROPERTY()
	FOnTransitionCompleteRight OnTransitionCompleteRight;
	UPROPERTY()
	FOnTransitionCompleteLeft OnTransitionCompleteLeft;
	UPROPERTY()
	TSubclassOf<UHazeCapability> PlayerCapability;

	UPROPERTY()
	AHazeCameraActor CameraLeft;
	UPROPERTY()
	AHazeCameraActor CameraRight;
	UPROPERTY()
	AHazeCameraActor CameraHiddeMain;
	AHazeCameraActor CurrentLeftCamera;
	AHazeCameraActor CurrentRightCamera;
	bool bSwitchingPicture = false;
	bool bCancelTriggerdLeft;
	bool bCancelTriggerdRight;

	UPROPERTY()
	float AutoDisableTimer = 15.f;
	float AutoDisableTimerTemp;

	UPROPERTY()
	FText RotateText;
	UPROPERTY()
	FText CancelText;
	

	UPROPERTY()
	AActor PictureWheelHidden;
	AHazePlayerCharacter LeftPlayer;
	AHazePlayerCharacter RightPlayer;

	FHazeAcceleratedFloat HiddenAcceleratedFloat;
	float CurrentHiddenWheelRotation;
	float TargetRotationHiddenWheel;
	int TimesSwitchedPicture = 0;
	int TimesSwitchedPictureForVO = 0;
	bool bCodyCapabilityActivate = false;
	bool bMayCapabilityActivate = false;
	bool bAllowPictureSwitch = true;
	float TimerAllowPictureSwitch = 2.25f;

	bool bPlayedInitalVoLineFromInteraction = false;
	bool bPlayedFirstPictureVO = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartFakePictureWheelRotation = FakePictureWheel.GetRelativeRotation();
	}

	UFUNCTION(BlueprintOverride) 
	void Tick(float DeltaSeconds)
	{
		if(bSwitchingPicture)
		{
		//	PrintToScreen("TargetRotationHiddenWheel " + TargetRotationHiddenWheel);
			HiddenAcceleratedFloat.SpringTo(TargetRotationHiddenWheel, 50, 1, DeltaSeconds);
			FHitResult Hit;
			PictureWheelHidden.SetActorRelativeRotation(FRotator(0,HiddenAcceleratedFloat.Value, 0), false, Hit, false);
			FakePictureWheel.SetRelativeRotation(FRotator(0, 0, HiddenAcceleratedFloat.Value));


			AutoDisableTimerTemp -= DeltaSeconds;
			if(AutoDisableTimerTemp < 0)
			{
				if(Game::GetMay().HasControl())
				{
					SetSwitchingPicture();
				}
			}

			if(bAllowPictureSwitch == false)
			{
				TimerAllowPictureSwitch -= DeltaSeconds;
				if(TimerAllowPictureSwitch <= 0)
				{
					bAllowPictureSwitch = true;
					TimerAllowPictureSwitch = 2.25f;
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void SetSwitchingPicture()
	{
		bSwitchingPicture = false;
		AutoDisableTimerTemp = AutoDisableTimer;
	}

	UFUNCTION(NetFunction)
	void SwitchPicture()
	{
		if(Game::GetMay().HasControl())
		{
			if(!bAllowPictureSwitch)
				return;
			
			NetSwitchPicture();
		}
	}
	UFUNCTION(NetFunction)
	void NetSwitchPicture()
	{
		bAllowPictureSwitch = false;
		AutoDisableTimerTemp = AutoDisableTimer;
		TargetRotationHiddenWheel = TimesSwitchedPicture * 45 + 45;
		TimesSwitchedPicture ++;
		TimesSwitchedPictureForVO ++;
		bSwitchingPicture = true;
		UHazeAkComponent::HazePostEventFireForget(TurnAudioEvent, GetActorTransform());

		PlayVoLines();
		if(TimesSwitchedPictureForVO >= 7)
		{
			TimesSwitchedPictureForVO = -1;
		}
	}

	UFUNCTION()
	void PreAddPictureToyRefence()
	{
		Game::GetCody().SetCapabilityAttributeObject(n"OldPictureToy", this);
		Game::GetMay().SetCapabilityAttributeObject(n"OldPictureToy", this);
	}


	//	UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
	//	FName EventName = n"FoghornSBMusicClassicHeavenReveal";
	//	PlayFoghornVOBankEvent(VOBank, EventName);


	UFUNCTION()
	void PlayVoLines()
	{
		if(TimesSwitchedPictureForVO == 0)
		{
			if(bPlayedFirstPictureVO == false)
			{
				bPlayedFirstPictureVO = true;

				if(bMayCapabilityActivate == true)
				{
					//May look at first pic alone
					PrintToScreen("May look at first pic alone", 4.f);
					UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
					FName EventName = n"FoghornDBMusicConcertHallOldPictureToyFirstPhotoSoloMay";
					PlayFoghornVOBankEvent(VOBank, EventName);
				}

				else if(bCodyCapabilityActivate == true)
				{
					//Cody look at first pic alone
					PrintToScreen("Cody look at first pic alone", 4.f);
					UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
					FName EventName = n"FoghornDBMusicConcertHallOldPictureToyFirstPhotoSoloCody";
					PlayFoghornVOBankEvent(VOBank, EventName);
				}
			}
		}
		if(TimesSwitchedPictureForVO == 2)
		{
			if(bCodyCapabilityActivate == true && bMayCapabilityActivate == true)
			{
				//May & Cody Look at third pic togehter
				//PrintToScreen("May & Cody Look at third pic togehter", 4.f);
				UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
				FName EventName = n"FoghornDBMusicConcertHallOldPictureToyCodyWithRose";
				PlayFoghornVOBankEvent(VOBank, EventName);
			}
		}
		if(TimesSwitchedPictureForVO == 3)
		{
			if(bCodyCapabilityActivate == true && bMayCapabilityActivate == true)
			{
				//Looking at 4th pic together
				//PrintToScreen("May & cody look at fourht pic together", 4.f);
				UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
				FName EventName = n"FoghornDBMusicConcertHallOldPictureToyMayWithRose";
				PlayFoghornVOBankEvent(VOBank, EventName);
			}
			else if(bMayCapabilityActivate)
			{
				//Looking at 4th pic
				//PrintToScreen("May looking at 4th photo alone", 4.f);
				UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
				FName EventName = n"FoghornDBMusicConcertHallOldPictureToySecondPhotoSoloMay";
				PlayFoghornVOBankEvent(VOBank, EventName);
			}
			else if(bCodyCapabilityActivate == true)
			{
				//Cody Look at foruth pic alone
				//PrintToScreen("Cody Look at fourth pic alone", 4.f);
				UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
				FName EventName = n"FoghornDBMusicConcertHallOldPictureToySecondPhotoSoloCody";
				PlayFoghornVOBankEvent(VOBank, EventName);
			}
		}
		if(TimesSwitchedPictureForVO == 7)
		{
			if(bCodyCapabilityActivate == true && bMayCapabilityActivate == true)
			{
				//May & Cody Look at sixt pic togehter
				//PrintToScreen("May & Cody Look at last pic togehter", 4.f);
				UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
				FName EventName = n"FoghornDBMusicConcertHallOldPictureToyThirdPhoto";
				PlayFoghornVOBankEvent(VOBank, EventName);
			}
			else
			{
				if(bMayCapabilityActivate == true)
				{
					//May look at sixt pic alone
					//PrintToScreen("May look at last pic alone", 4.f);
					UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
					FName EventName = n"FoghornDBMusicConcertHallOldPictureToyThirdPhotoSoloMay";
					PlayFoghornVOBankEvent(VOBank, EventName);
				}
				else if(bCodyCapabilityActivate == true)
				{
					//Cody look at sixt pic alone
					//PrintToScreen("Cody look at last pic alone", 4.f);
					UFoghornVOBankDataAssetBase VOBank = VODataBankAsset;
					FName EventName = n"FoghornDBMusicConcertHallOldPictureToyThirdPhotoSoloCody";
					PlayFoghornVOBankEvent(VOBank, EventName);
				}
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayInitialVOInteraction()
	{
		if(bPlayedInitalVoLineFromInteraction == true)
			return;

		bPlayedInitalVoLineFromInteraction = true;
		PlayVoLines();
	}
	

	UFUNCTION()
	void LeftLookInteractionActivated(AHazePlayerCharacter Player)
	{
		LeftPlayer = Player;
		bCancelTriggerdLeft = false;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		CurrentLeftCamera = CameraLeft;
		CameraLeft.ActivateCamera(LeftPlayer, Blend, this, EHazeCameraPriority::Script);
		System::SetTimer(this, n"FadeToBlackLeft", 1.5f, false);
		System::SetTimer(this, n"SwitchToHiddenCameraLeft", 2.25f, false);
	}
	UFUNCTION()
	void FadeToBlackLeft()
	{
		if(bCancelTriggerdLeft)
			return;

		FadeOutPlayer(LeftPlayer, 1.0f, 0.5f, 1.f);
	}
	UFUNCTION()
	void SwitchToHiddenCameraLeft()
	{
		if(bCancelTriggerdLeft)
			return;

		LeftPlayer.AddCapability(PlayerCapability);
		if(LeftPlayer == Game::GetCody())
		{
			bCodyCapabilityActivate = true;
		}
		else
		{
			bMayCapabilityActivate = true;
		}
//		LeftPlayer.SetCapabilityAttributeObject(n"OldPictureToy", this);

		FTutorialPrompt RotatePrompt;
		RotatePrompt.Action = ActionNames::MovementJump;
		RotatePrompt.DisplayType = ETutorialPromptDisplay::Action;
		RotatePrompt.Text = RotateText;
		ShowTutorialPrompt(LeftPlayer, RotatePrompt, LeftPlayer);
		FTutorialPrompt CancelPrompt;
		CancelPrompt.Action = ActionNames::Cancel;
		CancelPrompt.DisplayType = ETutorialPromptDisplay::Action;
		CancelPrompt.Text = CancelText;
		ShowTutorialPrompt(LeftPlayer, CancelPrompt, LeftPlayer);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.f;
		CurrentLeftCamera = CameraHiddeMain;
		CameraHiddeMain.ActivateCamera(LeftPlayer, Blend, this, EHazeCameraPriority::Script);
		OnTransitionCompleteLeft.Broadcast(LeftPlayer);

		if(Game::GetMay().HasControl())
		{
			NetPlayInitialVOInteraction();
		}
	}
	UFUNCTION()
	void LeftLookInteractionDeactivated(AHazePlayerCharacter Player)
	{
		if(CurrentLeftCamera == CameraLeft)
		{
			FinalExitLeftInteraction();
		}
		if(CurrentLeftCamera == CameraHiddeMain)
		{
			RemoveTutorialPromptByInstigator(LeftPlayer, LeftPlayer);
			Player.RemoveCapability(PlayerCapability);
			if(LeftPlayer == Game::GetCody())
			{
				bCodyCapabilityActivate = false;
			}
			else
			{
				bMayCapabilityActivate = false;
			}

			FadeOutPlayer(LeftPlayer, 0.75, 0.4f, 0.75f);
			System::SetTimer(this, n"FinalExitLeftInteraction", 0.75f, false);
		}
	}
	UFUNCTION()
	void FinalExitLeftInteraction()
	{
		if(CurrentLeftCamera == CameraLeft)
		{
			CameraLeft.DeactivateCamera(LeftPlayer, 1.0f);
		}
		if(CurrentLeftCamera == CameraHiddeMain)
		{
			CameraHiddeMain.DeactivateCamera(LeftPlayer, 0);
		}
	
		bCancelTriggerdLeft = true;
	}



	UFUNCTION()
	void RightLookInteractionActivated(AHazePlayerCharacter Player)
	{
		RightPlayer = Player;
		bCancelTriggerdRight = false;
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 2.f;
		CurrentRightCamera = CameraRight;
		CameraRight.ActivateCamera(Player, Blend, this, EHazeCameraPriority::Script);
		System::SetTimer(this, n"FadeToBlackRight", 1.5f, false);
		System::SetTimer(this, n"SwitchToHiddenCameraRight", 2.25f, false);
	}
	UFUNCTION()
	void FadeToBlackRight()
	{
		if(bCancelTriggerdRight)
			return;

		FadeOutPlayer(RightPlayer, 1.0f, 0.5f, 1.f);
	}
	UFUNCTION()
	void SwitchToHiddenCameraRight()
	{
		if(bCancelTriggerdRight)
			return;

		RightPlayer.AddCapability(PlayerCapability);
		if(RightPlayer == Game::GetCody())
		{
			bCodyCapabilityActivate = true;
		}
		else
		{
			bMayCapabilityActivate = true;
		}
		//RightPlayer.SetCapabilityAttributeObject(n"OldPictureToy", this);

		FTutorialPrompt RotatePrompt;
		RotatePrompt.Action = ActionNames::MovementJump;
		RotatePrompt.DisplayType = ETutorialPromptDisplay::Action;
		RotatePrompt.Text = RotateText;
		ShowTutorialPrompt(RightPlayer, RotatePrompt, RightPlayer);
		FTutorialPrompt CancelPrompt;
		CancelPrompt.Action = ActionNames::Cancel;
		CancelPrompt.DisplayType = ETutorialPromptDisplay::Action;
		CancelPrompt.Text = CancelText;
		ShowTutorialPrompt(RightPlayer, CancelPrompt, RightPlayer);

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.f;
		CurrentRightCamera = CameraHiddeMain;
		CameraHiddeMain.ActivateCamera(RightPlayer, Blend, this, EHazeCameraPriority::Script);
		OnTransitionCompleteRight.Broadcast(RightPlayer);

		if(Game::GetMay().HasControl())
		{
			NetPlayInitialVOInteraction();
		}
	}
	UFUNCTION()
	void RightLookInteractionDeactivated(AHazePlayerCharacter Player)
	{
		if(CurrentRightCamera == CameraRight)
		{
			FinalExitRightInteraction();
		}
		if(CurrentRightCamera == CameraHiddeMain)
		{
			RemoveTutorialPromptByInstigator(RightPlayer, RightPlayer);
			Player.RemoveCapability(PlayerCapability);
			if(RightPlayer == Game::GetCody())
			{
				bCodyCapabilityActivate = false;
			}
			else
			{
				bMayCapabilityActivate = false;
			}

			FadeOutPlayer(RightPlayer, 0.75f, 0.4f, 0.75f);
			System::SetTimer(this, n"FinalExitRightInteraction", 0.75f, false);
		}
	}
	UFUNCTION()
	void FinalExitRightInteraction()
	{
		if(CurrentRightCamera == CameraRight)
		{
			CameraRight.DeactivateCamera(RightPlayer, 1.0f);
		}
		if(CurrentRightCamera == CameraHiddeMain)
		{
			CameraHiddeMain.DeactivateCamera(RightPlayer, 0);
		}

		bCancelTriggerdRight = true;
	}
}

import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraPlayerComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraImage;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraWidget;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieVolumeTakeImageArea;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

enum ESelfieCameraState
{
	Default,
	Countdown,
	CorrectRotation,
	TakingImage,
	MoveImage
}

ASelfieCameraActor GetSelfieCameraActor()
{
	TArray<ASelfieCameraActor> SelfieCamArray;
	GetAllActorsOfClass(SelfieCamArray);

	return SelfieCamArray[0];
}

class ASelfieCameraActor : AHazeActor
{
	ESelfieCameraState SelfieCameraState;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CameraPivot;

	UPROPERTY(DefaultComponent, Attach = CameraPivot)
	UStaticMeshComponent MeshComp; //Camera

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent MeshAddonComp1; //Addon

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent MeshAddonComp2; //Addon

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent MeshAddonBackPart; //Addon

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UStaticMeshComponent MeshButton;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneComponent CameraLoc;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UBoxComponent BoxComp;
	default BoxComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshBase;

	UPROPERTY(DefaultComponent, Attach = CameraPivot)
	UInteractionComponent InteractionCompControlCam;
	default InteractionCompControlCam.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent, Attach = CameraPivot)
	UInteractionComponent InteractionCompTakeImage;
	default InteractionCompTakeImage.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent, Attach = CameraPivot)
	UStaticMeshComponent ImageStart;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UPointLightComponent TimerLightComp;
	default TimerLightComp.SetIntensity(0.f);
	default TimerLightComp.SetCastShadows(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent FlashLightComp;
	default FlashLightComp.bVisible = false;
	default FlashLightComp.SetCastShadows(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncYaw;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncPitch;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncZoom;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncZoomAlpha;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncRTCPRotation;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SmoothSyncRTCPZoom;

	UPROPERTY(Category = "Timed Light Settings")
	float TimedLightIntensity = 8500.f;

	UPROPERTY(Category = "Timed Light Settings")
	FLinearColor ColorNormal;

	UPROPERTY(Category = "Timed Light Settings")
	FLinearColor ColorReady;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;

	UPROPERTY(Category = "Animation")
	TPerPlayer<UAnimSequence> PlayerCameraPushButtonMH;

	UPROPERTY(Category = "LenseCam")
	AHazeCameraActor Camera;

	UPROPERTY(DefaultComponent, Attach = CameraPivot)
	UHazeCameraComponent CameraComp;
	default CameraComp.Settings.FOV = 60.f;
	default CameraComp.Settings.bUseFOV = true;

	UPROPERTY(Category = "Setup")
	ASelfieVolumeTakeImageArea TakeImageArea;
	
	UPROPERTY(Category = "Setup")
	TArray<ASelfieCameraImage> ImageStack;

	UPROPERTY(Category = "Setup")
	UForceFeedbackEffect SelfieCameraRumble;

	float StackZOffset = 1.5f;

	ASelfieCameraImage CurrentImage;

	USelfieCameraPlayerComponent PlayerCompInUse;

	AHazePlayerCharacter PlayerOnCamera;

	AHazePlayerCharacter PlayerPushedButton;

	UPROPERTY(Category = "LenseCam")
	TSubclassOf<AHazeActor> ImageClass;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	USceneCaptureComponent2D SceneCameraComponent;

	UPROPERTY(Category = "PlayerCapabilitySheet")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(Category = "PlayerCapabilitySheet")
	UHazeCapabilitySheet CameraCapabilitySheet;

	UPROPERTY(Category = "Widgets")
	TSubclassOf<USelfieCameraWidget> Widget;

	FVector CamStartLoc;

	UPROPERTY(meta = (MakeEditWidget))
	FTransform ImageFirstLocation;
	FVector FirstWorldLoc;
	FRotator FirstWorldRot;

	UPROPERTY(meta = (MakeEditWidget))
	FTransform ImageFinalLocation;
	FVector FinalWorldLoc;
	FRotator FinalWorldRot;

	UPROPERTY()
	FVector ButtonStartPos;

	UPROPERTY(Category = "Zoom Settings")
	float ZoomMaxFov = 60.f;

	UPROPERTY(Category = "Zoom Settings")
	float ZoomMinFov = 12.f;

	UPROPERTY(Category = "Achievement")
	float MinDot = 0.85f;

	UPROPERTY(Category = "Setup")
	float MinDistanceTransition = 100.f;

	float CamFOV;
	float FovStarting = 55.f;

	float StartingYaw;
	float StartingPitch;

	bool bTakingImage;
	bool bPlayerUsingCamera;
	bool bPlayerOnCamDuring;
	bool bPlayerLeaveAfterImage;
	bool bCanTakePicture;

	FNetworkIdentifierPart IDSelfieCameraActor;

	int netImageIndex = 0;

//*** AUDIO ***//

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartZoom;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopZoom; 

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartCameraPan;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopCameraPan;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartCameraTilt;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopCameraTilt;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TakeImage;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CountDownBeep;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RedButtonTakeImage;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent IncameraTakeImage;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MakeNetworked(this, IDSelfieCameraActor);

		AddCapabilitySheet(CameraCapabilitySheet);

		SceneCameraComponent.bCaptureEveryFrame = false;
		SceneCameraComponent.bCaptureOnMovement = false;

		Camera.AttachToComponent(SceneCameraComponent, NAME_None, EAttachmentRule::SnapToTarget);
		CamStartLoc = Camera.ActorLocation;

		InteractionCompControlCam.OnActivated.AddUFunction(this, n"CameraInteracted");
		InteractionCompTakeImage.OnActivated.AddUFunction(this, n"OnTakePictureInteracted");

		CamFOV = FovStarting;

		StartingYaw = ActorRotation.Yaw;
		StartingPitch = ActorRotation.Pitch;

		FlashLightComp.SetHiddenInGame(true);
		FlashLightComp.SetVisibility(true);

		ButtonStartPos = MeshButton.RelativeLocation;

		bCanTakePicture = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	 	Camera.ActorLocation = SceneCameraComponent.WorldLocation;
	 	Camera.ActorRotation = SceneCameraComponent.WorldRotation;
		SceneCameraComponent.FOVAngle = CamFOV;

		//If May is in view of scene capture (For when images are taken and printed to texture)
#if EDITOR		
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			PrintToScreen("Is May in View: " + IsInViewOfCamera(UHazeCameraComponent::Get(Camera), Game::May, CamFOV, 1));
#endif
		// For when camera is in use, we want 2/3 ratio
		FVector2D ScreenResolution = SceneView::GetFullViewportResolution(); 
		
		//Ensure this isn't stupidly tiny or wrong
		if (ScreenResolution.Y <= 0.f)
			return;
		else
		{
			float CamInUseAspectRatio = (ScreenResolution.X * 2.f) / (ScreenResolution.Y * 3.f);
			//Will need to check for both players while cam in use for VO activation
#if EDITOR		
		if (bHazeEditorOnlyDebugBool)
			PrintToScreen("Is May in View during use: " + IsInViewOfCamera(UHazeCameraComponent::Get(Camera), Game::May, CamFOV, CamInUseAspectRatio)); 
#endif
		}
	}

	UFUNCTION()
	void CameraInteracted(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"SelfieCam", this);
		Player.AddCapabilitySheet(PlayerCapabilitySheet);

		PlayerCompInUse = USelfieCameraPlayerComponent::Get(Player);

		InteractionCompControlCam.Disable(n"SelfieUsing");

		Player.AttachToComponent(InteractionCompControlCam, NAME_None, EAttachmentRule::KeepWorld);

		PlayerCompInUse.SelfieCameraActor = this;	
		PlayerCompInUse.SelfieCamera = Camera;

		bPlayerUsingCamera = true;

		InteractionCompTakeImage.DisableForPlayer(Player, n"InLookMode");

		PlayerOnCamera = Player;
	}
	
	UFUNCTION()
	void OnTakePictureInteracted(UInteractionComponent InputInteractionComp, AHazePlayerCharacter Player)
	{
		FHazeAnimationDelegate OnBlendingOutDelegate;

		if (Player.IsMay())
			OnBlendingOutDelegate.BindUFunction(this, n"ButtonPushAnimCompleteMay");
		else
			OnBlendingOutDelegate.BindUFunction(this, n"ButtonPushAnimCompleteCody");

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);
		Player.PlaySlotAnimation(Animation = PlayerCameraPushButtonMH[Player], BlendTime = 0.3f, OnBlendingOut = OnBlendingOutDelegate);	

		PlayerPushedButton = Player;	
		System::SetTimer(this, n"DelayedFeedback", 0.45f, false);

		CameraTakePicture(Player, InputInteractionComp);
	}

	UFUNCTION()
	void DelayedFeedback()
	{
		PlayerPushedButton.PlayForceFeedback(SelfieCameraRumble, false, true, n"PictureTakenRumble");
	}

	UFUNCTION()
	void CameraTakePicture(AHazePlayerCharacter Player, UInteractionComponent InputInteractionComp = nullptr)
	{
		if (!bCanTakePicture)
			return;

		bCanTakePicture = false;

		BP_ButtonPush();

		if (InputInteractionComp == nullptr)
			AudioIncameraTakeImage();
		else
			AudioRedButtonTakeImage();

		if (PlayerCompInUse != nullptr)
			PlayerCompInUse.bCanLook = false;

		bTakingImage = true;
		
		SceneCameraComponent.FOVAngle = CamFOV;

		SceneCameraComponent.CaptureSource = ESceneCaptureSource::SCS_SceneColorHDR;
	
		InteractionCompControlCam.Disable(n"CamControlSelfie");
		InteractionCompTakeImage.Disable(n"TakingSelfieImage");

		if (bPlayerUsingCamera)
			bPlayerOnCamDuring = true;

		CurrentImage = Cast<ASelfieCameraImage>(SpawnActor(ImageClass, ImageStart.WorldLocation, ActorRotation, bDeferredSpawn = true));
		CurrentImage.MakeNetworked(this, netImageIndex);
		CurrentImage.FinishSpawningActor();

		SceneCameraComponent.TextureTarget = CurrentImage.TextureImage;

		SelfieCameraState = ESelfieCameraState::Countdown;

		CurrentImage.AfterNetworkCapabilityAdd();
		CurrentImage.SetActorHiddenInGame(true);
		
		netImageIndex++;

		if (Player.IsMay())
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBTreeWaspNestCameraTakePhotoMay");
		else	
			PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBTreeWaspNestCameraTakePhotoCody");
	}	

	UFUNCTION()
	void InstantCameraTakePicture(AHazePlayerCharacter Player)
	{
		if (!bCanTakePicture)
			return;

		bCanTakePicture = false;
		
		AudioIncameraTakeImage();

		if (PlayerCompInUse != nullptr)
			PlayerCompInUse.bCanLook = false;

		bTakingImage = true;
		
		SceneCameraComponent.FOVAngle = CamFOV;

		SceneCameraComponent.CaptureSource = ESceneCaptureSource::SCS_SceneColorHDR;
	
		InteractionCompControlCam.Disable(n"CamControlSelfie");
		InteractionCompTakeImage.Disable(n"TakingSelfieImage");
	
		if (bPlayerUsingCamera)
			bPlayerOnCamDuring = true;

		CurrentImage = Cast<ASelfieCameraImage>(SpawnActor(ImageClass, ImageStart.WorldLocation, ActorRotation, bDeferredSpawn = true));
		CurrentImage.MakeNetworked(this, netImageIndex);
		CurrentImage.FinishSpawningActor();

		SceneCameraComponent.TextureTarget = CurrentImage.TextureImage;

		SelfieCameraState = ESelfieCameraState::CorrectRotation;

		CurrentImage.AfterNetworkCapabilityAdd();
		CurrentImage.SetActorHiddenInGame(true);
		
		netImageIndex++;

		Player.PlayForceFeedback(SelfieCameraRumble, false, true, n"PictureTakenRumble");

		CaptureImage();
	}

	UFUNCTION()
	void ButtonPushAnimCompleteMay()
	{
		Game::May.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION()
	void ButtonPushAnimCompleteCody()
	{
		Game::Cody.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(NetFunction)
	void NetPlayerCancelled(AHazePlayerCharacter Player)
	{
		Player.RemoveCapabilitySheet(PlayerCapabilitySheet);
		Player.DetachFromActor(EDetachmentRule::KeepWorld);

		bPlayerUsingCamera = false;
		PlayerCompInUse = nullptr;

		InteractionCompControlCam.EnableAfterFullSyncPoint(n"SelfieUsing");
		
		InteractionCompTakeImage.EnableForPlayer(Player, n"InLookMode");

		PlayerOnCamera = nullptr;
	}

	UFUNCTION()
	void CaptureImage()
	{
		if (CurrentImage == nullptr)
			return;

		CurrentImage.bPlayerInPicture = PlayerInView(UHazeCameraComponent::Get(Camera), CamFOV, 1);
#if EDITOR		
		if (bHazeEditorOnlyDebugBool)
			Print("bPlayerInPicture: " + CurrentImage.bPlayerInPicture);
#endif

		SceneCameraComponent.CaptureScene();
		FlashLightComp.SetHiddenInGame(false);

		System::SetTimer(this, n"DelayedTurnOffFlash", 0.12f, false);
		System::SetTimer(this, n"DelayedDeactivateImageTakeCamera", 4.f, false);

		bTakingImage = false;
		
		AudioTakeImage();
		AchievementCheck();
	}

	void EnableAllInteractions()
	{
		if (!bPlayerUsingCamera)
			bPlayerLeaveAfterImage = true;

		if (bPlayerOnCamDuring)
		{
			bPlayerOnCamDuring = false;
		}

		InteractionCompControlCam.EnableAfterFullSyncPoint(n"CamControlSelfie");
		InteractionCompTakeImage.EnableAfterFullSyncPoint(n"TakingSelfieImage");
		InteractionCompTakeImage.EnableAfterFullSyncPoint(n"InLookMode");

		bCanTakePicture = true;

		if (PlayerOnCamera != nullptr)
		{
			USelfieCameraPlayerComponent PlayerComp = USelfieCameraPlayerComponent::Get(PlayerOnCamera); 
			PlayerComp.bCanCancel = true;
			PlayerComp.ShowPlayerCancel(PlayerOnCamera);
		}
	}

	void BindThrowImageEvents()
	{
		for (ASelfieCameraImage Image : ImageStack)
		{
			if (Image == nullptr)
				continue;

			Image.OnSelfieCamThrowImage.Clear();
			Image.OnSelfieCamThrowImage.AddUFunction(this, n"OnImageThrown");
		}
	}

	UFUNCTION()
	void OnImageThrown(ASelfieCameraImage Image)
	{
		ImageStack.Remove(Image);

		if (ImageStack.Num() > 0)
			ImageStack[ImageStack.Num() - 1].EnableThrowInteraction();
	}

	void SetImageFallLoc(float ZOffset)
	{
		FVector ToAdd(0.f, 0.f, ZOffset);

		FirstWorldLoc = RootComponent.RelativeTransform.TransformPosition(ImageFirstLocation.Location);
		FirstWorldRot = RootComponent.RelativeTransform.TransformRotation(ImageFirstLocation.Rotation).Rotator();
		FinalWorldLoc = RootComponent.RelativeTransform.TransformPosition(ImageFinalLocation.Location) + ToAdd;
		FinalWorldRot = RootComponent.RelativeTransform.TransformRotation(ImageFinalLocation.Rotation).Rotator();
	}

	UFUNCTION()
	void DelayedDeactivateImageTakeCamera()
	{
		TakeImageArea.TakeImageSequenceDeactivated();
	}

	UFUNCTION()
	void DelayedTurnOffFlash()
	{
		FlashLightComp.SetHiddenInGame(true);
	}

	void TimerLightActivate(FLinearColor Color)
	{
		TimerLightComp.SetLightColor(Color);
		TimerLightComp.SetIntensity(TimedLightIntensity);
		
		System::SetTimer(this, n"DelayedTimerLightDeactivate", 0.25f, false);
	}

	UFUNCTION()
	void DelayedTimerLightDeactivate()
	{
		TimerLightComp.SetIntensity(0.f);
	}

	void AchievementCheck()
	{
		FVector MayDir = Game::May.ActorLocation - ActorLocation;
		FVector CodyDir = Game::Cody.ActorLocation - ActorLocation;
		MayDir.Normalize();
		CodyDir.Normalize();		

		float MayDot = ActorForwardVector.DotProduct(MayDir); 
		float CodyDot = ActorForwardVector.DotProduct(CodyDir); 

		if (MayDot >= MinDot)
			Online::UnlockAchievement(Game::May, n"TakeASelfie");

		if (CodyDot >= MinDot)
			Online::UnlockAchievement(Game::Cody, n"TakeASelfie");
	}

	UFUNCTION(BlueprintEvent)
	void BP_ButtonPush() {}

	bool PlayerInView(UHazeCameraComponent Camera, float FOV, float AspectRatio)
	{
		bool bMay = IsInViewOfCamera(Camera, Game::May, FOV, AspectRatio);
		bool bCody = IsInViewOfCamera(Camera, Game::Cody, FOV, AspectRatio);

		if (bMay || bCody)
			return true;
		else
			return false;
	}

	bool IsInViewOfCamera(UHazeCameraComponent Camera, AHazePlayerCharacter Player, float FOV, float AspectRatio)
	{
		if (Camera == nullptr)
			return false;

		if (Player == nullptr)
			return false;

		FTransform WorldToCameraLocal = Camera.WorldTransform.Inverse(); 

		float CapsuleHalfHeight = Player.CapsuleComponent.GetScaledCapsuleHalfHeight();
		CapsuleHalfHeight *= 0.4;

		FVector TopLocation = Player.CapsuleComponent.WorldLocation + (Player.CapsuleComponent.UpVector * CapsuleHalfHeight);
		TopLocation = WorldToCameraLocal.TransformPosition(TopLocation);

		FVector BotLocation = Player.CapsuleComponent.WorldLocation - (Player.CapsuleComponent.UpVector * CapsuleHalfHeight);
		BotLocation = WorldToCameraLocal.TransformPosition(BotLocation);

		FVector CameraCenterLineLocation = FVector((BotLocation.X + TopLocation.X) * 0.5f, 0.f, 0.f);

		FVector ProjectedLocation;
		float DummyFraction;
		Math::ProjectPointOnLineSegment(TopLocation, BotLocation, CameraCenterLineLocation, ProjectedLocation, DummyFraction);

		//Capsule still in view even if character out of sight. Reduce radius to help
		float AdjustedCapsuleRadius = Player.CapsuleComponent.GetScaledCapsuleRadius() * 0.8f; 
		ProjectedLocation += (CameraCenterLineLocation - ProjectedLocation).GetSafeNormal() * AdjustedCapsuleRadius;

		if (ProjectedLocation.X <= 0.f)
			return false; // Behind Camera

        float VerticalFOV = FMath::Clamp(FOV, 5.f, 89.f);
		float TanHalfVerticalFOV = FMath::Tan(FMath::DegreesToRadians(VerticalFOV * 0.5));

		if (FMath::Abs(ProjectedLocation.Z / ProjectedLocation.X) > TanHalfVerticalFOV)
			return false; // Above or below view

        float HorizontalFOV = FMath::Clamp(FMath::RadiansToDegrees(2 * FMath::Atan(TanHalfVerticalFOV * AspectRatio)), 5.f, 179.f);
		float TanHalfHorizontalFOV = FMath::Tan(FMath::DegreesToRadians(HorizontalFOV * 0.5));

		if (FMath::Abs(ProjectedLocation.Y / ProjectedLocation.X) > TanHalfHorizontalFOV)
			return false; // To left or right of view

		// Within view!
		return true;
	}

//*** AUDIO FUNCTIONS ***//

	UFUNCTION(NetFunction)
	void AudioStartZoom()
	{
		AkComp.HazePostEvent(StartZoom);
	}

	UFUNCTION(NetFunction)
	void AudioStopZoom()
	{
		AkComp.HazePostEvent(StopZoom);
	}

	UFUNCTION(NetFunction)
	void AudioStartCameraRotation()
	{
		AkComp.HazePostEvent(StartCameraPan);
		AkComp.HazePostEvent(StartCameraTilt);
	}

	UFUNCTION(NetFunction)
	void AudioStopCameraRotation()
	{
		AkComp.HazePostEvent(StopCameraPan);
		AkComp.HazePostEvent(StopCameraTilt);
	}

	void AudioTakeImage()
	{
		AkComp.HazePostEvent(TakeImage);
	}

	void AudioCountdownBeep()
	{
		AkComp.HazePostEvent(CountDownBeep);
	}

	void AudioZoomRTCP(float Value)
	{
		AkComp.SetRTPCValue("Rtpc_World_SideContent_Tree_Interactions_SelfieCamera_Zoom", Value);
	}

	void AudioCameraRotatePitchRTCP(float Value)
	{
		AkComp.SetRTPCValue("Rtpc_World_SideContent_Tree_Interactions_SelfieCamera_Tilt", Value);
	}

	void AudioCameraRotateYawRTCP(float Value)
	{
		AkComp.SetRTPCValue("Rtpc_World_SideContent_Tree_Interactions_SelfieCamera_Pan", Value);
	}

	void AudioRedButtonTakeImage()
	{
		AkComp.HazePostEvent(RedButtonTakeImage);
	}

	void AudioIncameraTakeImage()
	{
		AkComp.HazePostEvent(IncameraTakeImage);
	}
}
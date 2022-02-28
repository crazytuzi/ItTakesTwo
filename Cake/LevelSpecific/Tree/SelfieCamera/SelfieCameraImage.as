import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePlayerImageComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieImagePlayerInspectComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

event void FSelfieCamThrowImage(ASelfieCameraImage Image);

enum ESelfieImageMovementState
{
	Still,
	Moving
}

class ASelfieCameraImage : AHazeActor
{
	ESelfieImageMovementState SelfieImageMovementState;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshAnchor;

	UPROPERTY(DefaultComponent, Attach = MeshAnchor)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractCompThrowCody;
	default InteractCompThrowCody.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractCompThrowMay;
	default InteractCompThrowMay.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractCompInspect;
	default InteractCompInspect.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::AlwaysHost;

	UPROPERTY(Category = "VOBank")
	UFoghornVOBankDataAssetBase VOLevelBank;
	
	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet ImageCapabilitySheet;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerThrowCapabilitySheet;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerInspectCapabilitySheet;

	UPROPERTY(Category = "Animations")
	UAnimSequence MayIdleMH;

	UPROPERTY(Category = "Animations")
	UAnimSequence CodyIdleMH;

	FSelfieCamThrowImage OnSelfieCamThrowImage;

	AHazeCameraActor TargetCam;

	UMaterialInstanceDynamic MatInst;
	
	UPROPERTY(Category = Texture)
    UTextureRenderTarget2D TextureImage;

	bool bFadeImageIn;
	bool bPlayerInPicture;

	int netImageIndex;
	float currentFadeValue;
	float minFade = -0.3f;
	float maxFade = 1.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractCompThrowCody.OnActivated.AddUFunction(this, n"PlayerInteract");
		InteractCompThrowMay.OnActivated.AddUFunction(this, n"PlayerInteract");
		InteractCompInspect.OnActivated.AddUFunction(this, n"PlayerInspect");
		
		MatInst = MeshComp.CreateDynamicMaterialInstance(1);
		TextureImage = Rendering::CreateRenderTarget2D(1028.f, 1028.f);
		MatInst.SetTextureParameterValue(n"M1", TextureImage);

		currentFadeValue = minFade;
		MatInst.SetScalarParameterValue(n"FadeIn", currentFadeValue);

		InteractCompThrowMay.DisableForPlayer(Game::Cody, n"NotForCody");
		InteractCompThrowCody.DisableForPlayer(Game::May, n"NotForMay");
		InteractCompThrowMay.Disable(n"SelfieImageThrownToBoard");
		InteractCompThrowCody.Disable(n"SelfieImageThrownToBoard");
		InteractCompInspect.Disable(n"SelfieImageInspect");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bFadeImageIn)
		{
			currentFadeValue = FMath::FInterpConstantTo(currentFadeValue, maxFade, DeltaTime, 0.45f);
			MatInst.SetScalarParameterValue(n"FadeIn", currentFadeValue);
			
			if (currentFadeValue == maxFade)
				bFadeImageIn = false;
		}
	}

	void AfterNetworkCapabilityAdd()
	{
		AddCapabilitySheet(ImageCapabilitySheet);
	}

	UFUNCTION()
	void PlayerInteract(UInteractionComponent InputInteractCompThrow, AHazePlayerCharacter Player)
	{
		Player.AddCapabilitySheet(PlayerThrowCapabilitySheet);

		USelfiePlayerImageComponent PlayerComp = USelfiePlayerImageComponent::Get(Player);
		PlayerComp.OnSelfieThrowAnimCompleteEvent.AddUFunction(this, n"RemovePlayerImageCapability"); 
		PlayerComp.ImageRef = this;

		DisableThrowInteraction();
	}

	UFUNCTION()
	void PlayerInspect(UInteractionComponent InputInteractComp, AHazePlayerCharacter Player)
	{
		Player.AddCapabilitySheet(PlayerInspectCapabilitySheet);
		
		if (Player == Game::May)
			Player.PlaySlotAnimation(Animation = MayIdleMH, bLoop = true);
		else
			Player.PlaySlotAnimation(Animation = CodyIdleMH, bLoop = true);

		USelfieImagePlayerInspectComponent PlayerInspectComp = USelfieImagePlayerInspectComponent::Get(Player);
		PlayerInspectComp.OnSelfieImageCancelInspection.AddUFunction(this, n"PlayerCancelInspect");

		Player.SetCapabilityAttributeObject(n"SelfieImage", this);
		InteractCompInspect.Disable(n"BeingInspected");

		if (bPlayerInPicture)
		{
			if (Player.IsMay())
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBTreeWaspNestCameraInspectPhotoGenericMay");
			else
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBTreeWaspNestCameraInspectPhotoGenericCody");
		}
		else
		{
			if (Player.IsMay())
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBTreeWaspNestCameraInspectPhotoNoneMay");
			else
				PlayFoghornVOBankEvent(VOLevelBank, n"FoghornDBTreeWaspNestCameraInspectPhotoNoneCody");
		}
	}
	
	UFUNCTION()
	void PlayerCancelInspect(AHazePlayerCharacter Player)
	{
		Player.RemoveCapabilitySheet(PlayerInspectCapabilitySheet);
		Player.StopAllSlotAnimations(0.2f);
		InteractCompInspect.EnableAfterFullSyncPoint(n"BeingInspected");
	}

	UFUNCTION()
	void EnableThrowInteraction()
	{
		InteractCompThrowCody.EnableAfterFullSyncPoint(n"SelfieImageThrownToBoard");
		InteractCompThrowMay.EnableAfterFullSyncPoint(n"SelfieImageThrownToBoard");
	}

	void DisableThrowInteraction()
	{
		InteractCompThrowCody.Disable(n"SelfieImageThrownToBoard");
		InteractCompThrowMay.Disable(n"SelfieImageThrownToBoard");
	}

	UFUNCTION()
	void EnableImageInspect()
	{
		InteractCompInspect.EnableAfterFullSyncPoint(n"SelfieImageInspect");
	}

	UFUNCTION()
	void ThrowImage()
	{
		SelfieImageMovementState = ESelfieImageMovementState::Moving;
		OnSelfieCamThrowImage.Broadcast(this);
	}

	UFUNCTION()
	void RemovePlayerImageCapability(AHazePlayerCharacter Player)
	{
		Player.RemoveCapabilitySheet(PlayerThrowCapabilitySheet);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ImageLandedOnBoard() {}
}
import Vino.Interactions.InteractionComponent;
import Peanuts.Fades.FadeStatics;

event void FClockTownDoorEvent(AHazePlayerCharacter Player);

class AClockTownInteractableDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase LeftDoorRoot;

	UPROPERTY(DefaultComponent, Attach = LeftDoorRoot)
	UStaticMeshComponent LeftDoorMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase RightDoorRoot;

	UPROPERTY(DefaultComponent, Attach = RightDoorRoot)
	UStaticMeshComponent RightDoorMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlayerExitPoint;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayEnterAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence MayExitAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyEnterAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence CodyExitAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LeftDoorEnterAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence RightDoorEnterAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LeftDoorExitAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence RightDoorExitAnim;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent EnterDoorAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent ExitDoorAudioEvent;

	UPROPERTY()
	FClockTownDoorEvent OnDoorEntered;

	UPROPERTY()
	FClockTownDoorEvent OnDoorExit;

	UPROPERTY()
	AClockTownInteractableDoor TargetDoor;

	bool bOpening = true;
	AHazePlayerCharacter CurrentPlayer;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UPROPERTY()
	bool bSnapCameraOnExit = true;

	UPROPERTY()
	FRotator CameraSnapOffset = FRotator(-15.f, 180.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		LeftDoorMesh.SetCullDistance(Editor::GetDefaultCullingDistance(LeftDoorMesh) * CullDistanceMultiplier);
		RightDoorMesh.SetCullDistance(Editor::GetDefaultCullingDistance(RightDoorMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");
    }

    UFUNCTION(NotBlueprintCallable)
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		CurrentPlayer = Player;
		InteractionComp.Disable(n"Used");
		TargetDoor.InteractionComp.Disable(n"Used");

		UAnimSequence Anim = CurrentPlayer.IsMay() ? MayEnterAnim : CodyEnterAnim;
		CurrentPlayer.PlayEventAnimation(Animation = Anim, bPauseAtEnd = true);

		PlayDoorAnimation(LeftDoorRoot, LeftDoorEnterAnim);
		PlayDoorAnimation(RightDoorRoot, RightDoorEnterAnim);

		CurrentPlayer.BlockCapabilities(CapabilityTags::Collision, this);
		CurrentPlayer.BlockCapabilities(CapabilityTags::Movement, this);

		System::SetTimer(this, n"FadeToBlack", 1.5f, false);
		System::SetTimer(this, n"TeleportToExit", 2.8f, false);

		CurrentPlayer.OtherPlayer.DisableOutlineByInstigator(this);

		FHazePointOfInterest PoISettings;
		PoISettings.FocusTarget.Actor = this;
		PoISettings.FocusTarget.LocalOffset = FVector(-3000.f, 0.f, -250.f);
		PoISettings.Blend.BlendTime = 3.f;
		CurrentPlayer.ApplyPointOfInterest(PoISettings, this);

		CurrentPlayer.ApplyIdealDistance(300.f, FHazeCameraBlendSettings(6.f), this);
		FHazeCameraBlendSettings OffsetBlend;
		OffsetBlend.Type = EHazeCameraBlendType::Additive;
		OffsetBlend.BlendTime = 5.f;
		CurrentPlayer.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, -85.f), OffsetBlend, this);

		OnDoorEntered.Broadcast(CurrentPlayer);

		HazeAkComp.HazePostEvent(EnterDoorAudioEvent);
    }

	UFUNCTION(NotBlueprintCallable)
	void FadeToBlack()
	{
		FadeOutPlayer(CurrentPlayer);
	}

	UFUNCTION(NotBlueprintCallable)
	void TeleportToExit()
	{
		CurrentPlayer.BlockCapabilities(CapabilityTags::Visibility, this);
		CurrentPlayer.TeleportActor(TargetDoor.PlayerExitPoint.WorldLocation, TargetDoor.PlayerExitPoint.WorldRotation);

		ClearPlayerFades(CurrentPlayer, 0.5f);

		CurrentPlayer.ClearPointOfInterestByInstigator(this);
		CurrentPlayer.SnapCameraBehindPlayer(CameraSnapOffset);
		CurrentPlayer.ClearIdealDistanceByInstigator(this, 6.f);
		CurrentPlayer.ClearCameraOffsetOwnerSpaceByInstigator(this, 5.f);

		System::SetTimer(this, n"StartExiting", 1.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void StartExiting()
	{
		UAnimSequence Anim = CurrentPlayer.IsMay() ? MayExitAnim : CodyExitAnim;
		FHazeAnimationDelegate AnimDelegate;
		AnimDelegate.BindUFunction(this, n"ExitAnimFinished");
		CurrentPlayer.PlayEventAnimation(OnBlendingOut = AnimDelegate, Animation = Anim, BlendTime = 0.f);
				
		TargetDoor.PlayDoorAnimation(TargetDoor.LeftDoorRoot, LeftDoorExitAnim);
		TargetDoor.PlayDoorAnimation(TargetDoor.RightDoorRoot, RightDoorExitAnim);

		System::SetTimer(this, n"ShowPlayerAfterTeleport", 0.2f, false);

		TargetDoor.HazeAkComp.HazePostEvent(TargetDoor.ExitDoorAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void ShowPlayerAfterTeleport()
	{
		CurrentPlayer.UnblockCapabilities(CapabilityTags::Visibility, this);
	}

	void PlayDoorAnimation(UHazeSkeletalMeshComponentBase Door, UAnimSequence Anim)
	{
		FHazePlaySlotAnimationParams Params;
		Params.Animation = Anim;
		Params.BlendTime = 0.f;
		Door.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Params);
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitAnimFinished()
	{
		CurrentPlayer.UnblockCapabilities(CapabilityTags::Collision, this);
		CurrentPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		CurrentPlayer.OtherPlayer.EnableOutlineByInstigator(this);

		OnDoorExit.Broadcast(CurrentPlayer);

		System::SetTimer(this, n"EnableInteractionsAfterExit", 1.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void EnableInteractionsAfterExit()
	{
		TargetDoor.InteractionComp.EnableAfterFullSyncPoint(n"Used");
		InteractionComp.EnableAfterFullSyncPoint(n"Used");
	}
}
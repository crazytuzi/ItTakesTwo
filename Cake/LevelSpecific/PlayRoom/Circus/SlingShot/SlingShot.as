import Vino.Interactions.InteractionComponent;
import Vino.Pickups.PlayerPickupComponent;
import Vino.Pickups.PickupActor;


event void FSlingShotFiredEventSignature(AHazePlayerCharacter FullScreenPlayer);
event void FSlingShotInteractedEventSignature(AHazePlayerCharacter InteractingPlayer);

enum ESlingShotMoveState
{
	Pullback,
	SlideForward,
	NotMoving
};
class ASlingShotActor: AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BaseMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent, Attach = HandleParent)
	UStaticMeshComponent SlingHandle;

	UPROPERTY(DefaultComponent, Attach = HandleParent)
    UInteractionComponent InteractionLeft;
	
	UPROPERTY(DefaultComponent, Attach = HandleParent)
    UInteractionComponent ArmInteraction;


	UPROPERTY(DefaultComponent, Attach = SlingHandle)
	USceneComponent LeftRubberBandHandleAttachPoint;

	UPROPERTY(DefaultComponent, Attach = SlingHandle)
	USceneComponent RightRubberBandHandleAttachPoint;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightRubberBand;
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftRubberBand;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent PullBackPositionSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftPlayerHoldTriggerProgressSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightPlayerHoldTriggerProgressSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftPlayerMoveDirectionSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightPlayerMoveDirectionSync;

	UPROPERTY(DefaultComponent, Attach = HandleParent)
    UInteractionComponent InteractionRight;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent HandleParent;

	UPROPERTY(DefaultComponent, Attach = SlingHandle)
	UStaticMeshComponent Marble;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MaxPulledBackByOnePlayerPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent NoPlayerPullsPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MaxPulledBackByTwoPlayersPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShootPosition;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartInteractionEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopInteractionEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LoadMarbleAudioEvent;

	UPROPERTY()
	APickupActor PickupableMarble;

	UPROPERTY()
	ESlingShotMoveState MoveState;

	UPROPERTY()
	FHazePointOfInterest PointOfInterest;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset LeftCameraSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset RightCameraSettings;

	UPROPERTY()
	UAnimSequence ArmAnimationMay;

	UPROPERTY()
	UAnimSequence ArmAnimationCody;

	float TimeHeldInMaxPosition;

	UPROPERTY()
	FSlingShotInteractedEventSignature OnArmedSlingshot;

	UPROPERTY()
	FSlingShotInteractedEventSignature OnInteractLeft;

	UPROPERTY()
	FSlingShotInteractedEventSignature OnInteractedRight;

	AHazePlayerCharacter InteractingPlayerOnLeft;
	AHazePlayerCharacter InteractingPlayerOnRight;

	bool bHasShotMarble = false;
	bool HasShotWithDoubleInteract = false;

	UPROPERTY()
	FVector SlingHandleStartPos;

	UPROPERTY()
	bool bIsArmed = false;

	float LeftPlayerMoveDirection = 0;
	float RightPlayerMoveDirection  = 0;

	UPROPERTY()
	FSlingShotFiredEventSignature OnMarbleShot;

	AHazePlayerCharacter FullScreenPlayer;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapabilityType;

	UPROPERTY()
	TSubclassOf<UHazeCapability> SlingshotWidgetType;

	AHazePlayerCharacter ArmingPlayer;

	bool bReset;
	FVector SlingHandleResetLocation;

	bool GetIsBothPlayersPulling() property
	{
		if (InteractingPlayerOnLeft != nullptr && InteractingPlayerOnRight != nullptr)
		{
			return true;
		}
		
		else 
		{
			return false;
		}
	}

	bool GetIsOnePlayerInteracting() property
	{
		if (InteractingPlayerOnLeft != nullptr && InteractingPlayerOnRight == nullptr ||
		InteractingPlayerOnRight != nullptr && InteractingPlayerOnLeft == nullptr)
		{
			return true;
		}

		else
		{
			return false;
		}
	}

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Capability::AddPlayerCapabilityRequest(RequiredCapabilityType.Get());

		InteractionLeft.OnActivated.AddUFunction(this, n"InteractedLeft");
		InteractionRight.OnActivated.AddUFunction(this, n"InteractedRight");


		ArmInteraction.OnActivated.AddUFunction(this, n"InteractedArm");

		ArmInteraction.DisableForPlayer(Game::GetCody(), n"Marble");
		ArmInteraction.DisableForPlayer(Game::GetMay(), n"Marble");
		Marble.SetHiddenInGame(true);

		AddCapability(SlingshotWidgetType);
		AddCapability(n"SlingShotMovementCapability");
		
		SlingHandleResetLocation = SlingHandle.RelativeLocation;		
    }

	UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason Reason)
    {
		Capability::RemovePlayerCapabilityRequest(RequiredCapabilityType.Get());
	}

	UFUNCTION()
	void OnPickedupMarble(AHazePlayerCharacter Player, AActor PickedupActor)
	{

	}

	UFUNCTION()
	void InteractedArm(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		ArmInteraction.Disable(n"Armed");
		
		FHazeAnimationDelegate BlendOutDelegate;
		BlendOutDelegate.BindUFunction(this, n"OnArmBlendingOut");
		Player.PlayerHazeAkComp.HazePostEvent(LoadMarbleAudioEvent);

		UAnimSequence Animation = ArmAnimationCody;

		if (!Player.IsCody())
		{
			Animation = ArmAnimationMay;
		}

		Player.PlaySlotAnimation(FHazeAnimationDelegate(), BlendOutDelegate, Animation, false, EHazeBlendType::BlendType_Inertialization, 0.2f, 1.f);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		ArmingPlayer = Player;
		OnArmedSlingshot.Broadcast(Player);
	}

	UFUNCTION()
	void OnArmBlendingOut()
	{
		UPlayerPickupComponent::Get(ArmingPlayer).ForceDrop(false);
		UPlayerPickupComponent::Get(ArmingPlayer).OnPutDownEvent.AddUFunction(this, n"RemoveDroppedMarble");
		ArmingPlayer.UnblockCapabilities(CapabilityTags::Movement, this);
		ArmSlingShot();
	}

	UFUNCTION()
	void RemoveDroppedMarble(AHazePlayerCharacter Player, APickupActor PickupableMarble)
	{
		PickupableMarble.DestroyActor();
	}

	UFUNCTION()
	void ArmSlingShot()
	{
		bIsArmed = true;
		Marble.SetHiddenInGame(false);
	}

	UFUNCTION()
	void InteractedLeft(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		InteractingPlayerOnLeft = Player;
		InteractionLeft.Disable(n"Interacting");
		Player.SetCapabilityAttributeObject(n"SlingShot", this);

		Player.ApplyPointOfInterest(PointOfInterest, this);
		Player.ApplyCameraSettings(LeftCameraSettings, FHazeCameraBlendSettings(), this);

		LeftPlayerHoldTriggerProgressSync.OverrideControlSide(Player);
		LeftPlayerMoveDirectionSync.OverrideControlSide(Player);
		OnInteractLeft.Broadcast(Player);

		if (IsBothPlayersPulling)
		{
			SetFullScreen(Player);
		}
	}

	UFUNCTION()
	void ResetPointOfInterest(AHazePlayerCharacter Player)
	{
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION()
	void InteractedRight(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		InteractingPlayerOnRight = Player;
		InteractionRight.Disable(n"Interacting");
		Player.SetCapabilityAttributeObject(n"SlingShot", this);
		
		Player.ApplyPointOfInterest(PointOfInterest, this);
		Player.ApplyCameraSettings(RightCameraSettings, FHazeCameraBlendSettings(), this);

		RightPlayerHoldTriggerProgressSync.OverrideControlSide(Player);
		RightPlayerMoveDirectionSync.OverrideControlSide(Player);
		OnInteractedRight.Broadcast(Player);

		if (IsBothPlayersPulling)
		{
			SetFullScreen(Player);
		}
	}

	void SetFullScreen(AHazePlayerCharacter Player)
	{
		FullScreenPlayer = Player;
		FullScreenPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Normal, EHazeViewPointPriority::Gameplay);
		HazeAkComp.HazePostEvent(StartInteractionEvent);
	}

	void SetSplitScreen(AHazePlayerCharacter Player)
	{
		if(!HasShotWithDoubleInteract)
		{
			FullScreenPlayer.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Normal);
			FullScreenPlayer = nullptr;
		}
	}

	UFUNCTION()
	void SetMoveDirection(float Direction, AHazePlayerCharacter Player)
	{
		if (Player == InteractingPlayerOnLeft && Player.HasControl())
		{
			LeftPlayerMoveDirection = Direction;
			LeftPlayerMoveDirectionSync.Value = LeftPlayerMoveDirection;
		}

		else if (Player == InteractingPlayerOnRight && Player.HasControl())
		{
			RightPlayerMoveDirection = Direction;
			RightPlayerMoveDirectionSync.Value = RightPlayerMoveDirection;
		}
	}

	float GetPullAmount() property
	{
		return RightPlayerMoveDirection + LeftPlayerMoveDirection;
	}

	UFUNCTION()
	void StopInteracting(AHazeCharacter Character)
	{
		AHazePlayerCharacter PlayerCharacter = Cast<AHazePlayerCharacter>(Character);
		PlayerCharacter.ClearPointOfInterestByInstigator(this);

		PlayerCharacter.ClearCameraSettingsByInstigator(this);

		HazeAkComp.HazePostEvent(StopInteractionEvent);

		if (!HasShotWithDoubleInteract)
		{
			if (Character == InteractingPlayerOnLeft)
			{
				InteractionLeft.Enable(n"Interacting");
				LeftPlayerMoveDirection = 0;
				InteractingPlayerOnLeft = nullptr;
				
			}

			else
			{
				InteractionRight.Enable(n"Interacting");
				RightPlayerMoveDirection = 0;
				InteractingPlayerOnRight = nullptr;
			}
		}

		else
		{
			InteractingPlayerOnLeft = nullptr;
			InteractingPlayerOnRight = nullptr;
		}

		if (FullScreenPlayer != nullptr)
		{
			SetSplitScreen(PlayerCharacter);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SyncMoveDirectionValues();

		FVector TargetPosition = RightRubberBandHandleAttachPoint.GetWorldLocation();
		RightRubberBand.SetVectorParameterValueOnMaterials(n"TargetPosition",  TargetPosition);

		TargetPosition = LeftRubberBandHandleAttachPoint.GetWorldLocation();
		LeftRubberBand.SetVectorParameterValueOnMaterials(n"TargetPosition", TargetPosition);

		if (HasControl() && !bReset)
		{
			if (bIsArmed && !HasShotWithDoubleInteract)
			{
				EvaluateHandleCloseToMaxPosition(DeltaTime);

				if (HandleCloseToMaxPosition && HasControl() && TimeHeldInMaxPosition >= 1.5f)
				{
					NetShoot();
				}
			}
		}
	}

	void EvaluateHandleCloseToMaxPosition(float Delta)
	{
		if (HandleCloseToMaxPosition)
		{
			TimeHeldInMaxPosition += Delta;
		}
		else
		{
			TimeHeldInMaxPosition -= Delta;
		}

		TimeHeldInMaxPosition = FMath::Clamp(TimeHeldInMaxPosition , 0.f, 1.5f);
	}

	void SyncMoveDirectionValues()
	{
		RightPlayerMoveDirection = RightPlayerMoveDirectionSync.Value;
		LeftPlayerMoveDirection = LeftPlayerMoveDirectionSync.Value;
	}

	bool GetHandleCloseToMaxPosition() property
	{
		if (MaxPulledBackByTwoPlayersPosition.WorldLocation.Distance(HandleParent.WorldLocation) < 100)
		{
			return true;
		}

		else
		{
			return false;
		}
	}

	bool GetAllowCancel() property
	{
		float HandleDistance = MaxPulledBackByTwoPlayersPosition.WorldLocation.Distance(HandleParent.WorldLocation);
		PrintToScreen("" + HandleDistance);
		if (HandleDistance > 200)
		{
			return true;
		}

		else
		{
			return false;
		}
	}

	UFUNCTION(NetFunction)
	void NetShoot()
	{
		HasShotWithDoubleInteract = true;

		for (auto Player : Game::GetPlayers())
		{
			Player.SetCapabilityActionState(n"ShootMarble", EHazeActionState::Active);			
			Player.BlockCapabilities(n"SlingShot", this);
		}

		InteractionLeft.Disable(n"PuzzleIsDone");
		InteractionRight.Disable(n"PuzzleIsDone");
		

		OnMarbleShot.Broadcast(FullScreenPlayer);
	}

	UFUNCTION()
	void ResetSlingLocation()
	{
		SlingHandle.AttachToComponent(HandleParent, NAME_None, EAttachmentRule::SnapToTarget);
		SlingHandle.SetRelativeLocation(SlingHandleResetLocation);
		bReset = true;
		HandleParent.SetWorldLocation(NoPlayerPullsPosition.WorldLocation);
		PullBackPositionSync.Value = HandleParent.GetWorldLocation();
	}
};
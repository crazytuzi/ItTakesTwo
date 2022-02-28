import Vino.Interactions.InteractionComponent;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;

event void FOnDoubleBoxFullyPushed();
event void FOnDoubleBoxInteracted();

UCLASS(Abstract)
class APushableDoubleBox : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent Base;

    UPROPERTY(DefaultComponent, Attach = Base)
    UStaticMeshComponent Mesh;

    UPROPERTY(DefaultComponent, Attach = Base)
	UInteractionComponent RightInteraction;
    default RightInteraction.RelativeRotation = FRotator(0.f, -90.f, 0.f);
    default RightInteraction.RelativeLocation = FVector(400.f, 300.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent LeftInteraction;
    default LeftInteraction.RelativeRotation = FRotator(0.f, -90.f, 0.f);
    default LeftInteraction.RelativeLocation = FVector(-400.f, 300.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Base)
    UArrowComponent PushDirection;
    default PushDirection.RelativeRotation = FRotator(0.f, -90.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = Base)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent PositionSync;
	default PositionSync.NumberOfSyncsPerSecond = 20;

	UPROPERTY()
	FOnDoubleBoxInteracted OnRightSideInteracted;

	UPROPERTY()
	FOnDoubleBoxInteracted OnLeftSideInteracted;

	UPROPERTY()
	FOnDoubleBoxInteracted OnRightSideCancelled;

	UPROPERTY()
	FOnDoubleBoxInteracted OnLeftSideCancelled;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VOBank;

	UPROPERTY()
	bool bPlayReminderBarks = true;

    float MayPushPower;
    float CodyPushPower;

    float TotalPushPower;

	float MaxMovementSpeed = 300.f;

    UPROPERTY(meta = (MakeEditWidget))
    FVector MaxLocation;

	UPROPERTY()
	float TransitionValue = -1500.f;

    UPROPERTY()
    bool bPreviewMaxLocation = false;

	UPROPERTY()
	bool bUseForwardInput = true;

	UPROPERTY()
	bool bShowCancelPrompt = true;

	bool bCodyPushing = false;
	bool bMayPushing = false;
	bool bBothPlayersPushing = false;
	bool bFullyPushed = false;

	bool bIsMoving = false;

	UPROPERTY()
	FOnDoubleBoxFullyPushed OnDoubleBoxFullyPushed;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> RequiredCapability;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintEvent)
	void BP_StartMove()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_StopMove()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_FullyPushed()
	{}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetupTriggerComponent();

		Capability::AddPlayerCapabilityRequest(RequiredCapability);

		PositionSync.OnValueChanged.AddUFunction(this, n"OnPositionSyncChanged");
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapability);
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        if (bPreviewMaxLocation)
            Base.SetRelativeLocation(MaxLocation);
        else
            Base.SetRelativeLocation(FVector::ZeroVector);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float Delta)
    {
		if (bFullyPushed)
		{
			SetActorTickEnabled(false);
			return;
		}

		if (bCodyPushing && bMayPushing)
		{
			bBothPlayersPushing = true;
			bIsMoving = true;
			BP_StartMove();
		}
			
		else
		{
			bBothPlayersPushing = false;
			bIsMoving = false;
			BP_StopMove();
		}

        if(bBothPlayersPushing)
        {
			if (HasControl())
			{
				float NewOffset = Base.RelativeLocation.Y - 300.f * Delta;
				NewOffset = FMath::Clamp(NewOffset, MaxLocation.Y, 0.f);
				Base.SetRelativeLocation(FVector(0.f, NewOffset, 0.f));
				PositionSync.Value = NewOffset;

				if (NewOffset <= TransitionValue + 0.01f)
				{
					if (HasControl())
						NetFullyPushed();
				}
			}
        }
		else
		{
			SetActorTickEnabled(false);
		}
    }

	UFUNCTION()
	private void OnPositionSyncChanged()
	{
		if (!HasControl())
		{
			if (bFullyPushed)
				return;

			Base.SetRelativeLocation(FVector(0.f, PositionSync.Value, 0.f));
		}
	}

	UFUNCTION(NetFunction)
	private void NetFullyPushed()
	{
		bFullyPushed = true;
		OnDoubleBoxFullyPushed.Broadcast();
		if (bIsMoving)
			BP_StopMove();
		BP_FullyPushed();
	}

	UFUNCTION(NetFunction)
	void NetSetPushingStatus(AHazePlayerCharacter Player, bool bStatus)
	{
		Player.IsCody() ? bCodyPushing = bStatus : bMayPushing = bStatus;
		if (bStatus)
			SetActorTickEnabled(true);
	}

    void SetupTriggerComponent()
	{
        FHazeShapeSettings ActionShape;
        ActionShape.BoxExtends = FVector(100.f, 100.f, 100.f);
		ActionShape.Type = EHazeShapeType::Box;

        FHazeShapeSettings FocusShape;
        FocusShape.BoxExtends = FVector(600.f, 600.f, 600.f);
        FocusShape.Type = EHazeShapeType::Box;

		FTransform ActionTransform;
		ActionTransform.SetScale3D(FVector(1.f));

		FHazeDestinationSettings MovementSettings;
		//MovementSettings.MovementMethod = EHazeMovementMethod::Disabled;

		FHazeActivationSettings ActivationSettings;
		ActivationSettings.ActivationType = EHazeActivationType::Action;

		FHazeTriggerVisualSettings VisualSettings;
		VisualSettings.VisualOffset.Location = FVector(100.f, 0.f, 100.f);

		RightInteraction.AddActionShape(ActionShape, ActionTransform);
        RightInteraction.AddFocusShape(FocusShape, ActionTransform);
		RightInteraction.AddMovementSettings(MovementSettings);
		RightInteraction.AddActivationSettings(ActivationSettings);
		RightInteraction.SetVisualSettings(VisualSettings);

        LeftInteraction.AddActionShape(ActionShape, ActionTransform);
        LeftInteraction.AddFocusShape(FocusShape, ActionTransform);
		LeftInteraction.AddMovementSettings(MovementSettings);
		LeftInteraction.AddActivationSettings(ActivationSettings);
		LeftInteraction.SetVisualSettings(VisualSettings);

		FHazeTriggerActivationDelegate RightInteractionDelegate;
		RightInteractionDelegate.BindUFunction(this, n"RightInteractionActivated");
		RightInteraction.AddActivationDelegate(RightInteractionDelegate);

        FHazeTriggerActivationDelegate LeftInteractionDelegate;
        LeftInteractionDelegate.BindUFunction(this, n"LeftInteractionActivated");
        LeftInteraction.AddActivationDelegate(LeftInteractionDelegate);
	}

    UFUNCTION(NotBlueprintCallable)
	void RightInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
    {
        Player.SetCapabilityAttributeObject(n"DoubleBox", this);
        Player.SetCapabilityAttributeObject(n"Interaction", Component);
        Player.SetCapabilityActionState(n"PushingDoubleBox", EHazeActionState::Active);
        Component.Disable(n"Interacted");
		OnRightSideInteracted.Broadcast();
    }

    UFUNCTION(NotBlueprintCallable)
	void LeftInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
    {
        Player.SetCapabilityAttributeObject(n"DoubleBox", this);
        Player.SetCapabilityAttributeObject(n"Interaction", Component);
        Player.SetCapabilityActionState(n"PushingDoubleBox", EHazeActionState::Active);
        Component.Disable(n"Interacted");
		OnLeftSideInteracted.Broadcast();
    }

    void ReleaseBox(UHazeTriggerComponent Interaction)
    {
        Interaction.EnableAfterFullSyncPoint(n"Interacted");
		if (Interaction == LeftInteraction)
			OnLeftSideCancelled.Broadcast();
		else
			OnRightSideCancelled.Broadcast();
    }

    void ResetPushPower(AHazePlayerCharacter Player)
    {
        if(Player.IsCody())
            CodyPushPower = 0.f;
        else
            MayPushPower = 0.f;
    }
}
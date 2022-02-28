event void FOnInteractionComponentActivated(UInteractionComponent Component, AHazePlayerCharacter Player);

enum EInteractionExclusiveMode
{
	None,
	ExclusiveToMay,
	ExclusiveToCody,
};

/*
    The interaction component is a wrapper around
    the base trigger component that allows for
    settings to be specified in a more convenient way.
*/

UCLASS(HideCategories = "Activation Rendering Cooking Physics LOD AssetUserData Collision")
class UInteractionComponent : UHazeTriggerComponent
{
    /* Event that is broadcast when the trigger is activated. */
    UPROPERTY(meta = (BPCannotCallEvent))
    FOnInteractionComponentActivated OnActivated;

    /* Activation settings that determine when the interaction will be activated. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate", AdvancedDisplay)
	FHazeActivationSettings ActivationSettings;

	/* Whether to disable the interaction by default when it enters play. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate", meta = (InlineEditConditionToggle))
	bool bStartDisabled = false;

	/* Disable reason to disable with if the interaction enters play disabled. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate", meta = (EditCondition = "bStartDisabled"))
	FName StartDisabledReason = n"StartDisabled";

	/* Whether this interaction should be displayed as an exclusive interaction. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate")
	EInteractionExclusiveMode ExclusiveMode = EInteractionExclusiveMode::None;

	/* Must be in this volume to consider this interaction for usage. */
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "ActionArea")
	AVolume ActionVolume = nullptr;

	/* Automatically create an action shape of this type. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "ActionArea", meta = (ShowOnlyInnerProperties))
	FHazeShapeSettings ActionShape;
    default ActionShape.Type = EHazeShapeType::Box;
	default ActionShape.BoxExtends = FVector(100.f, 100.f, 100.f);
	default ActionShape.SphereRadius = 100.f;
	 
	/* The automatically created action shape should have this as its transform. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "ActionArea", meta = (MakeEditWidget))
	FTransform ActionShapeTransform = FTransform(FVector(0.f, 0.f, 100.f));

	/* Must be in this volume to consider this interaction for usage. */
	UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "FocusArea")
	AVolume FocusVolume = nullptr;

	/* Automatically create an action shape of this type. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "FocusArea", meta = (ShowOnlyInnerProperties))
	FHazeShapeSettings FocusShape;
    default FocusShape.Type = EHazeShapeType::Sphere;
	default FocusShape.BoxExtends = FVector(100.f, 100.f, 100.f);
	default FocusShape.SphereRadius = 100.f;
	 
	/* The automatically created action shape should have this as its transform. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "FocusArea", meta = (MakeEditWidget))
	FTransform FocusShapeTransform;
	default FocusShapeTransform.SetScale3D(FVector(7.f, 7.f, 7.f));

	/* Settings for the visual aspect of the interaction. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Visuals", meta = (ShowOnlyInnerProperties))
	FHazeTriggerVisualSettings Visuals;
    default Visuals.VisualOffset = FTransform(FVector(0.f, 0.f, 50.f));

	/* Movement settings that will be used when the interaction is activated. */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Movement", meta = ( ShowOnlyInnerProperties))
	FHazeDestinationSettings MovementSettings;

	/**
	 * Whether to use lazy shapes for the action and focus volumes.
	 * Lazy shapes avoid the physics system and are faster if the shapes move around a lot.
	 * They should not be used if the shapes don't move.
	 */
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Activate", AdvancedDisplay)
	bool bUseLazyTriggerShapes = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        // Set the configured action areas
        if (ActionVolume != nullptr)
            AddActionVolume(ActionVolume);

        if ((ActionShape.Type != EHazeShapeType::None) && !ActionShape.IsZeroSize() && ActionShapeTransform.GetScale3D().GetMin() >= SMALL_NUMBER)
		{
			if (bUseLazyTriggerShapes)
				AddLazyActionShape(ActionShape, ActionShapeTransform);
			else
				AddActionShape(ActionShape, ActionShapeTransform);
		}

        // Set the configured action areas
        if (FocusVolume != nullptr)
            AddFocusVolume(FocusVolume);

        if ((FocusShape.Type != EHazeShapeType::None) && !FocusShape.IsZeroSize() && FocusShapeTransform.GetScale3D().GetMin() >= SMALL_NUMBER)
		{
			if (bUseLazyTriggerShapes)
				AddLazyFocusShape(FocusShape, FocusShapeTransform);
			else
				AddFocusShape(FocusShape, FocusShapeTransform);
		}

        // Set trigger settings
        AddMovementSettings(MovementSettings);
        AddActivationSettings(ActivationSettings);
        SetVisualSettings(Visuals);

		if (bStartDisabled)
			Disable(StartDisabledReason);

		if (ExclusiveMode == EInteractionExclusiveMode::ExclusiveToCody)
			SetExclusiveForPlayer(EHazePlayer::Cody);
		else if (ExclusiveMode == EInteractionExclusiveMode::ExclusiveToMay)
			SetExclusiveForPlayer(EHazePlayer::May);

        // Bind the Activation delegate
        FHazeTriggerActivationDelegate Delegate;
        Delegate.BindUFunction(this, n"OnTriggerComponentActivated");
        AddActivationDelegate(Delegate);
    }

    UFUNCTION()
    void OnTriggerComponentActivated(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
    {
        OnActivated.Broadcast(this, PlayerCharacter);

#if TEST
		FString DebugText = "Trigger component " + GetName() + " on " + GetOwner().GetName() + " Activated";
		Debug::AddLoggerEntry(PlayerCharacter, DebugText, n"Interaction");
#endif
    }
};
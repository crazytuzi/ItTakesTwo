import Vino.Interactions.Widgets.InteractionWidget;

struct FActiveWidget
{
    UInteractionWidget Widget;
    UHazeTriggerComponent Trigger;
    FVector VisualOffset;
};

struct FExternalWidget
{
	USceneComponent Component;
	FVector VisualOffset;
	bool bAvailable = true;
	bool bFocused = false;
	uint LastFrame = 0;
	UInteractionWidget Widget;
	EHazeActivationType ActivationType;
};

struct FTriggerState
{
	TArray<UHazeTriggerComponent> VisibleTriggers;
	TArray<UHazeTriggerComponent> AvailableTriggers;
	TArray<UHazeTriggerComponent> FocusedTriggers;

	void Reset()
	{
		VisibleTriggers.Reset();
		AvailableTriggers.Reset();
		FocusedTriggers.Reset();
	}
};

// Component that goes on the player that takes care of
// displaying interaction widgets for nearby triggers.
class UInteractionWidgetsComponent : UActorComponent
{
    // Type of widget to use for interactions. Should be set by the actor adding this component.
    UPROPERTY(EditDefaultsOnly)
    TSubclassOf<UInteractionWidget> InteractionWidgetClass;

    // Widgets we are currently displaying on screen
    TArray<FActiveWidget> CurrentWidgets;
	TArray<FExternalWidget> ExternalWidgets;

	default TickGroup = ETickingGroup::TG_PostPhysics;

	bool bCanInteract = true;

	void ShowInteractionWidgetThisFrame(USceneComponent Component,
		bool bAvailable = false,
		bool bFocused = false,
		EHazeActivationType ActivationType = EHazeActivationType::Action,
		FVector Offset = FVector())
	{
		for (FExternalWidget& Existing : ExternalWidgets)
		{
			if (Existing.Component == Component)
			{
				Existing.VisualOffset = Offset;
				Existing.bFocused = bFocused;
				Existing.LastFrame = GFrameNumber;
				return;
			}
		}

		FExternalWidget NewExternal;
		NewExternal.Component = Component;
		NewExternal.VisualOffset = Offset;
		NewExternal.bFocused = bFocused;
		NewExternal.bAvailable = bAvailable;
		NewExternal.ActivationType = ActivationType;
		NewExternal.LastFrame = GFrameNumber;
		ExternalWidgets.Add(NewExternal);
	}

	void GatherTriggerState(FTriggerState& State)
	{
		// Add all the interactions for the player we're on
        UHazeTriggerUserComponent TriggerUser = UHazeTriggerUserComponent::Get(Owner);
		if (bCanInteract && TriggerUser != nullptr)
		{
			TriggerUser.GetAllVisibleTriggers(State.VisibleTriggers);
			TriggerUser.GetAllAvailableTriggers(State.AvailableTriggers);
			State.FocusedTriggers.Add(TriggerUser.GetFocusedTrigger(State.AvailableTriggers));
		}

		// It's possible that we're in full screen mode, and we're the full screen
		// owner. In this case, we should *also* display widgets for the other player's
		// interactions, and merge the two.
		if (SceneView::IsFullScreen() && SceneView::GetFullScreenPlayer() == Owner)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
			auto OtherWidgetsComp = UInteractionWidgetsComponent::Get(Player.OtherPlayer);
			if (OtherWidgetsComp != nullptr && OtherWidgetsComp.bCanInteract)
			{
				auto OtherTriggerUser = UHazeTriggerUserComponent::Get(Player.OtherPlayer);

				TArray<UHazeTriggerComponent> OtherVisible;
				OtherTriggerUser.GetAllVisibleTriggers(OtherVisible);
				for (auto Trigger : OtherVisible)
					State.VisibleTriggers.AddUnique(Trigger);

				TArray<UHazeTriggerComponent> OtherAvailable;
				OtherTriggerUser.GetAllAvailableTriggers(OtherAvailable);
				for (auto Trigger : OtherAvailable)
					State.AvailableTriggers.AddUnique(Trigger);

				State.FocusedTriggers.AddUnique(OtherTriggerUser.GetFocusedTrigger(OtherAvailable));
			}
		}
	}

	FTriggerState State;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		State.Reset();
		GatherTriggerState(State);

        // Create widgets for any triggers we weren't showing before
        for (UHazeTriggerComponent Trigger : State.VisibleTriggers)
        {
            UInteractionWidget Widget;
            int ActiveIndex = -1;

            // Check if we already have a widget for this trigger
            for (int i = 0, Num = CurrentWidgets.Num(); i < Num; ++i)
            {
                if (CurrentWidgets[i].Trigger == Trigger)
                {
                    ActiveIndex = i;
                    Widget = CurrentWidgets[i].Widget;
                }
            }

            // Make a new widget if needed
            if (Widget == nullptr)
            {
                if (ActiveIndex != -1)
                    CurrentWidgets.RemoveAt(ActiveIndex);

                FActiveWidget ActiveWidget;
                ActiveWidget.Trigger = Trigger;
                ActiveWidget.Widget = MakeWidget(Trigger, Trigger.VisualOffset.Location);
                ActiveWidget.VisualOffset = Trigger.VisualOffset.Location;
                CurrentWidgets.Add(ActiveWidget);

                Widget = ActiveWidget.Widget;
				Widget.bIsCodyOnlyTagged = ActiveWidget.Trigger != nullptr && ActiveWidget.Trigger.HasTag(n"CodyOnlyUse");
				Widget.bIsMayOnlyTagged = ActiveWidget.Trigger != nullptr && ActiveWidget.Trigger.HasTag(n"MayOnlyUse");

				if (Widget.bIsCodyOnlyTagged)
					Widget.OverrideWidgetPlayer(Game::Cody);
				else if (Widget.bIsMayOnlyTagged)
					Widget.OverrideWidgetPlayer(Game::May);

				Widget.InitTrigger();
            }
            else
            {
                // Update the visual offset if it has changed
                if (Trigger.VisualOffset.Location != CurrentWidgets[ActiveIndex].VisualOffset)
                {
                    CurrentWidgets[ActiveIndex].VisualOffset = Trigger.VisualOffset.Location;
                    CurrentWidgets[ActiveIndex].Widget.SetWidgetRelativeAttachOffset(Trigger.VisualOffset.Location);
                }
            }

            // Update state of the widget for this trigger
			Widget.ActivationType = Trigger.ActivationType;
            Widget.bIsTriggerAvailable = State.AvailableTriggers.Contains(Trigger);
			Widget.bIsTriggerFocused = State.FocusedTriggers.Contains(Trigger);
        }

        // Destroy widgets we no longer have the trigger for
        for (int i = CurrentWidgets.Num() - 1; i >= 0; --i)
        {
            if (State.VisibleTriggers.Contains(CurrentWidgets[i].Trigger))
                continue;

            RemoveWidget(CurrentWidgets[i].Widget);
            CurrentWidgets.RemoveAt(i);
        }

		UpdateExternalWidgets();
    }

	void UpdateExternalWidgets()
	{
		for (int i = ExternalWidgets.Num() - 1; i >= 0; --i)
		{
			FExternalWidget& ExternalWidget = ExternalWidgets[i];
			if (ExternalWidget.LastFrame < GFrameNumber)
			{
				if (ExternalWidget.Widget != nullptr)
					RemoveWidget(ExternalWidget.Widget);
				ExternalWidgets.RemoveAt(i);
			}
			else
			{
				if (ExternalWidget.Widget == nullptr)
					ExternalWidget.Widget = MakeWidget(ExternalWidget.Component, ExternalWidget.VisualOffset);

				// Update state of the widget for this trigger
				ExternalWidget.Widget.ActivationType = ExternalWidget.ActivationType;
				ExternalWidget.Widget.bIsTriggerAvailable = ExternalWidget.bAvailable;
				ExternalWidget.Widget.bIsTriggerFocused = ExternalWidget.bFocused;
			}
		}
	}

    /* Create a new interaction widget belonging to the specified trigger. */
    UInteractionWidget MakeWidget(USceneComponent Component, FVector Offset)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
        UInteractionWidget Widget = Cast<UInteractionWidget>(Player.AddWidget(InteractionWidgetClass));

        Widget.AttachWidgetToComponent(Component, NAME_None);
        Widget.SetWidgetRelativeAttachOffset(Offset);

        return Widget;
    }

    /* Remove a widget that was added for a trigger before. */
    void RemoveWidget(UInteractionWidget Widget)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(GetOwner());
        Player.RemoveWidget(Widget);
    }
};

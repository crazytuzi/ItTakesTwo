import Vino.Pickups.Putdown.PickupPutdownLocation;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;
import Peanuts.ButtonMash.Progress.ButtonMashProgress;

event void FOnScratchboardStateChanged(AScratchboard Scratchboard);
event void FOnPlayerScratch(AScratchboard Scratchboard, AHazePlayerCharacter PlayerCharacter);

class AScratchboard : APickupPutdownLocation
{
	UPROPERTY()
	FOnScratchboardStateChanged OnProgressMaximum;

	UPROPERTY()
	FOnScratchboardStateChanged OnProgressDepleted;

	UPROPERTY()
	FOnPlayerScratch OnPlayerScratch;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeSmoothSyncFloatComponent SyncedProgress;

	UPROPERTY()
	TSubclassOf<UButtonMashProgressWidget> ProgressWidgetClass = Asset("/Game/GUI/ButtonMash/WBP_ButtonMashProgress.WBP_ButtonMashProgress_C");

	UButtonMashProgressWidget ProgressWidget;
	UButtonMashSilentHandle MashHandle;

	UPROPERTY()
	float ButtonMashDecayRate = 0.3f;

	// Value applied when the button mash starts.
	UPROPERTY()
	float StartValue = 0.1f;

	float TargetProgress = 0.0f;
	float CurrentProgress = 0.0f;

	bool bIsButtonMashing = false;

	bool bInteractorHasControl = false;

	UFUNCTION()
	bool HandleTriggerCondition(UHazeTriggerComponent TriggerComponent, AHazePlayerCharacter PlayerCharacter)
	{
		if(CurrentlyPlacedActor == nullptr)
		{
			return Super::HandleTriggerCondition(TriggerComponent, PlayerCharacter);
		}

		return true;
	}
	
	void HandleActivateInteraction(UInteractionComponent InteractionComponent, AHazePlayerCharacter PlayerCharacter)
	{
		if(!IsOccupied())
		{
			Super::HandleActivateInteraction(InteractionComponent, PlayerCharacter);
			return;
		}

		PlayerCharacter.SetCapabilityAttributeObject(n"ActiveScratchboard", this);
	}

	void OnStartScratching(AHazePlayerCharacter PlayerCharacter)
	{
		devEnsure(ProgressWidgetClass.IsValid(), "The button mash UI widget has not been set for this Scratchboard: " + GetName());
		ProgressWidget = Cast<UButtonMashProgressWidget>(PlayerCharacter.AddWidget(ProgressWidgetClass));
		ProgressWidget.AttachWidgetToComponent(RootComp);
		ProgressWidget.SetWidgetShowInFullscreen(true);
		CurrentProgress = 0.0f;
		TargetProgress = 0.0f;
		IncrementScratch(StartValue, PlayerCharacter);
		bIsButtonMashing = true;
		bInteractorHasControl = PlayerCharacter.HasControl();
	}

	void IncrementScratch(float ScratchValue, AHazePlayerCharacter PlayerCharacter)
	{
		TargetProgress = FMath::Min(TargetProgress + ScratchValue, 1.1f);
		NetOnPlayerScratch(PlayerCharacter);

		if(TargetProgress >= 1.0f)
		{
			NetOnProgressMaximum();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bInteractorHasControl)
		{
			TargetProgress = FMath::Max(TargetProgress - (ButtonMashDecayRate * DeltaTime), 0.0f);
			CurrentProgress = FMath::FInterpConstantTo(CurrentProgress, TargetProgress, 1.5f, DeltaTime);
			SyncedProgress.Value = CurrentProgress;
		}
		else
		{
			CurrentProgress = SyncedProgress.Value;
		}

		if(bIsButtonMashing && IsOutOfScratch())
		{
			ProgressWidget.SetProgress(0.0f);
			ProgressWidget.FadeOut();
			ProgressWidget = nullptr;
			bIsButtonMashing = false;

			if(bInteractorHasControl)
			{
				NetOnProgressDepleted();
			}
		}

		if(ProgressWidget != nullptr)
		{
			ProgressWidget.SetProgress(FMath::Min(CurrentProgress, 1.0f));
		}
	}

	void HandlePlayerPlacedObject(AHazePlayerCharacter PlayerCharacter)
	{
		Super::HandlePlayerPlacedObject(PlayerCharacter);

		if(CurrentlyPlacedActor == nullptr)
		{
			return;
		}

		CurrentlyPlacedActor.InteractionComponent.Disable(n"ActorPickedUp");
	}

	bool IsOutOfScratch() const
	{
		return FMath::IsNearlyZero(CurrentProgress, 0.01f);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Progress Maximum"))
	void BP_OnProgressMaximum(AScratchboard Scratchboard){}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Progress Depleted"))
	void BP_OnProgressDepleted(AScratchboard Scratchboard){}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Player Scratch"))
	void BP_OnPlayerScratch(AScratchboard Scratchboard, AHazePlayerCharacter Player){}

	void Internal_OnProgressMaximum()
	{
		BP_OnProgressMaximum(this);
		OnProgressMaximum.Broadcast(this);
	}

	void Internal_OnProgressDepleted()
	{
		BP_OnProgressDepleted(this);
		OnProgressDepleted.Broadcast(this);
	}

	void Internal_OnPlayerScratch(AHazePlayerCharacter PlayerCharacter)
	{
		BP_OnPlayerScratch(this, PlayerCharacter);
		OnPlayerScratch.Broadcast(this, PlayerCharacter);
	}

	UFUNCTION(BlueprintPure)
	float GetScratchProgress() const
	{
		return FMath::Clamp(CurrentProgress, 0.0f, 1.0f);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetOnProgressMaximum()
	{
		Internal_OnProgressMaximum();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetOnProgressDepleted()
	{
		Internal_OnProgressDepleted();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetOnPlayerScratch(AHazePlayerCharacter PlayerCharacter)
	{
		Internal_OnPlayerScratch(PlayerCharacter);
	}
}

import Peanuts.Foghorn.FoghornStatics;

event void FVOBarkTriggerEvent(AHazeActor Actor);

UCLASS(hideCategories="Activation")
class UVOBarkTriggerComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY(Category = "VOBark")
	UFoghornVOBankDataAssetBase FoghornDataAsset;

	// Default event name used if triggered by non-player or if may/cody event names are not set
	UPROPERTY(Category = "VOBark")
	FName EventName = NAME_None;

	// If set, this event will be used if May is triggering the bark
	UPROPERTY(Category = "VOBark")
	FName MayEventName = NAME_None;

	// If set, this event will be used if Cody is triggering the bark
	UPROPERTY(Category = "VOBark")
	FName CodyEventName = NAME_None;

	// Who should speak the bark (Cody and May barks do not need this)
	UPROPERTY(Category = "VOBark")
	AActor VOSourceActor;

	// If > 0 the bark will not trigger until the conditions for this trigger has been true for this many seconds.
	UPROPERTY(Category = "VOBark")
	float Delay = 0.f;

	// If true, any delay count down will be reset when the conditions for this trigger becomes false. If false, countdown remains at the value it had when conditions failed.
	UPROPERTY(Category = "VOBark")
	bool bResetDelayOnLeave = true;

	// IF true we will repeat bark until disabled, ignoring max trígger count.
	UPROPERTY(Category = "VOBark")
	bool bRepeatForever = false;

	// VO event can be retriggered this many times.
	UPROPERTY(Category = "VOBark", meta = (EditCondition="!bRepeatForever"))
	int MaxTriggerCount = 1;

	// Delays for any barks after the first one. If empty, we always use the normal delay.
	// If there are more barks than entries in this list we will always use the last delay. 
	UPROPERTY(Category = "VOBark")
	TArray<float> RetriggerDelays;

	UPROPERTY(Category = "VOBark")
	FVOBarkTriggerEvent OnVOBarkTriggered;

	// We do this only to move the Player Trigger Category higher in the details view
	UPROPERTY(Category = "Player Trigger", AdvancedDisplay)
	bool bThisBoolDoesNothing;

	// We do this only to move the Actor Trigger Category higher in the details view
	UPROPERTY(Category = "Actor Trigger", AdvancedDisplay)
	bool bThisBoolDoesNothingEither;

	// We do this only to move the LookAt Trigger Category higher in the details view
	UPROPERTY(Category = "LookAt", AdvancedDisplay)
	bool bThisBoolDoesNothingEitherToo;

	AHazeActor Barker;
	bool bTriggerLocally = false;
	float Timer = 0.f;
	int TriggerCount = 0;
	float CurrentDelay;
	bool bBothPlayerBark = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentDelay = Delay;
	}
	
	void OnStarted()
	{
		SetComponentTickEnabled(true);
	}

	void OnEnded()
	{
		Barker = nullptr;

		if (bResetDelayOnLeave)
			Timer = 0.f;

		SetComponentTickEnabled(false);
	}

	void SetBarker(AHazeActor Actor, bool bBothPlayers = false)
	{
		Barker = Actor;
		bBothPlayerBark = bBothPlayers;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bRepeatForever && (TriggerCount >= MaxTriggerCount))
		{
			SetComponentTickEnabled(false);			
			return;
		}
		
		Timer += DeltaTime;

		if (Timer >= CurrentDelay)
		{
			if (bTriggerLocally)
				PlayBark(Barker);
			else if (HasControl())
				NetPlayBark(Barker);
		}

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			PrintToScreen("VOBark Trigger: " + Owner.Name + " DelayedTime: " + Timer, 0.f, FLinearColor::Green);
#endif
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPlayBark(AHazeActor BarkingActor)
	{
		PlayBark(BarkingActor);
	}

	void PlayBark(AHazeActor BarkingActor)
	{
		if (RetriggerDelays.Num() > 0)
			CurrentDelay = RetriggerDelays[FMath::Min(TriggerCount, RetriggerDelays.Num() - 1)];
		TriggerCount++;
		Timer = 0.f;

		FName BarkEventName = EventName;
		if ((BarkingActor == Game::GetCody()) && (CodyEventName != NAME_None))
			BarkEventName = CodyEventName;
		if ((BarkingActor == Game::GetMay()) && (MayEventName != NAME_None))
			BarkEventName = MayEventName;

		if ((FoghornDataAsset != nullptr) && (BarkEventName != NAME_None))
			PlayFoghornVOBankEvent(FoghornDataAsset, BarkEventName, VOSourceActor);

		// Note that we trigger event even if we do not have a data asset.
		// We can thus use this as an more elaborate trigger if needed.
		OnVOBarkTriggered.Broadcast(BarkingActor);

		// Check this after broadcasting the first, in case that should trigger something 
		// that could stop the second bark.
		if (bBothPlayerBark)
		{
			AHazePlayerCharacter PlayerBarker = Cast<AHazePlayerCharacter>(BarkingActor);
			if ((PlayerBarker != nullptr) && (PlayerBarker.OtherPlayer != nullptr))
			{
				// Only play other player bark if we have a specific event name for that player
				FName OtherBark = (PlayerBarker.OtherPlayer.IsCody()) ? CodyEventName : MayEventName;
				if (OtherBark != NAME_None)
				{
					if (FoghornDataAsset != nullptr)	
						PlayFoghornVOBankEvent(FoghornDataAsset, OtherBark, PlayerBarker.OtherPlayer);
					OnVOBarkTriggered.Broadcast(PlayerBarker.OtherPlayer);
				}
			}
		}

		if (!bRepeatForever && (TriggerCount >= MaxTriggerCount))
			SetComponentTickEnabled(false);

#if EDITOR
		//bHazeEditorOnlyDebugBool = true;
		if (bHazeEditorOnlyDebugBool)
			PrintToScreen("VOBark Trigger by: " + BarkingActor.Name, 2.f, FLinearColor::Green);
#endif
	}
}
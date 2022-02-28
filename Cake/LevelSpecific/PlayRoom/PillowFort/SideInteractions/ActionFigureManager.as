import Cake.LevelSpecific.PlayRoom.PillowFort.SideInteractions.ActionFigureActor;
import Vino.Buttons.GroundPoundButton;
import Peanuts.Foghorn.FoghornDirectorDataAssetBase;
import Peanuts.Foghorn.FoghornStatics;

event void FOnActionFigureSequenceTriggeredSignature();

struct FActionFigureEvent
{
	UPROPERTY()
	UAkAudioEvent AudioEvent;

	UPROPERTY()
	UFoghornBarkDataAsset VOAsset;

	UPROPERTY()
	float EventDuration = 5.f;

	UPROPERTY()
	UAnimSequence Animation;
}

class AActionFigureManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActionFigureActor LeoFigure;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AGroundPoundButton LeoButton;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AActionFigureActor VincentFigure;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AGroundPoundButton VincentButton;



	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TArray<FActionFigureEvent> LeoEvents;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	TArray<FActionFigureEvent> VincentEvents;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FActionFigureEvent FirstDoubleEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Setup")
	FActionFigureEvent SecondDoubleEvent;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	float StartBufferTime = 2.f;

	UPROPERTY()
	FOnActionFigureSequenceTriggeredSignature SequenceTriggeredEvent;

	FTimerHandle StartBufferTimerHandle;

	FTimerHandle LeoResetTimerHandle;
	FTimerHandle VincentResetTimerHandle;
	FTimerHandle DoubleInteractResetTimerHandle;

	bool bLeoPlaying = false;
	bool bVincentPlaying = false;
	bool bLeoStarted = false;
	bool bVincentStarted = false;

	UPROPERTY()
	bool bSequenceHasPlayed = false;
	
	int DoubleInteractCount = 0;

	int LastLeoIndexUsed = 0;
	int LastVincentIndexUsed = 0;

	float ResetTime = 1.f;
	float NetworkTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		auto EditorBillboard = UBillboardComponent::Create(this);
		EditorBillboard.bIsEditorOnly = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(!HasControl())
			return;

		if(LeoButton != nullptr && LeoFigure != nullptr)
			LeoButton.OnButtonGroundPoundCompleted.AddUFunction(this, n"OnLeoButtonGroundPounded");
		if(VincentButton != nullptr && VincentFigure != nullptr)
			VincentButton.OnButtonGroundPoundCompleted.AddUFunction(this, n"OnVincentButtonGroundPounded");
	}

	UFUNCTION()
	void OnLeoButtonGroundPounded(AHazePlayerCharacter Player)
	{
		if(IsNetworked())
			NetworkTime = Network::GetPingRoundtripSeconds() / 2;

		if(!System::IsTimerActiveHandle(StartBufferTimerHandle))
			StartBufferTimerHandle = System::SetTimer(this, n"Control_VerifyEvent", StartBufferTime + NetworkTime, false);

		bLeoStarted = true;
	}

	UFUNCTION()
	void OnVincentButtonGroundPounded(AHazePlayerCharacter Player)
	{
		if(IsNetworked())
			NetworkTime = Network::GetPingRoundtripSeconds() / 2;

		if(!System::IsTimerActiveHandle(StartBufferTimerHandle))
			StartBufferTimerHandle = System::SetTimer(this, n"Control_VerifyEvent", StartBufferTime + NetworkTime, false);
		
		bVincentStarted = true;
	}

	UFUNCTION()
	void Control_VerifyEvent()
	{
		System::ClearAndInvalidateTimerHandle(StartBufferTimerHandle);

		if(bVincentStarted && bLeoStarted)
		{	
			VerifyDoubleInteract();
		}
		else if(bLeoStarted)
		{
			int index = LastLeoIndexUsed;

			while(index == LastLeoIndexUsed)
				index = FMath::RandRange(0, LeoEvents.Num() - 1);

			if(LeoEvents.IsValidIndex(index))
			{
				bLeoStarted = false;
				Net_PlayEventLeo(LeoEvents[index]);
				LeoResetTimerHandle = System::SetTimer(this, n"Net_ResetButtonLeo", LeoEvents[index].AudioEvent.HazeMaximumDuration + ResetTime, false);
				LastLeoIndexUsed = index;
			}
		}
		else if(bVincentStarted)
		{
			int index = LastVincentIndexUsed;

			while(index == LastVincentIndexUsed)
				index = FMath::RandRange(0, VincentEvents.Num() - 1);

			if(VincentEvents.IsValidIndex(index))
			{
				bVincentStarted = false;
				Net_PlayEventVincent(VincentEvents[index]);
				VincentResetTimerHandle = System::SetTimer(this, n"Net_ResetButtonVincent", VincentEvents[index].AudioEvent.HazeMaximumDuration + ResetTime, false);
				LastVincentIndexUsed = index;
			}
		}
		else 
			return;
	}

	//Check how many times we interacted + Play interact.
	void VerifyDoubleInteract()
	{
		switch (DoubleInteractCount)
		{
				case 0:
					Net_TriggerSequence();
					bLeoStarted = false;
					bVincentStarted = false;
					DoubleInteractCount = 1;
					break;
				case 1:
					Net_PlayEventLeo(FirstDoubleEvent);
					DoubleInteractResetTimerHandle = System::SetTimer(this, n"Net_ResetBothButtons", FirstDoubleEvent.AudioEvent.HazeMaximumDuration + ResetTime, false);
					bLeoStarted = false;
					bVincentStarted = false;
					DoubleInteractCount = 2;
					break;
				case 2:
					Net_PlayEventVincent(SecondDoubleEvent);
					DoubleInteractResetTimerHandle = System::SetTimer(this, n"Net_ResetBothButtons", SecondDoubleEvent.AudioEvent.HazeMaximumDuration + ResetTime, false);
					bLeoStarted = false;
					bVincentStarted = false;
					DoubleInteractCount = 1;
					break;

				default:
					Net_ResetBothButtons();
					break;
		}
	}

	UFUNCTION(NetFunction)
	void Net_TriggerSequence()
	{
		SequenceTriggeredEvent.Broadcast();
	}

	UFUNCTION(NetFunction)
	void Net_PlayEventLeo(FActionFigureEvent Event)
	{
		//LeoFigure.AkComp.HazePostEvent(Event.AudioEvent);
		PlayFoghornBark(Event.VOAsset, LeoFigure);
	}

	UFUNCTION(NetFunction)
	void Net_PlayEventVincent(FActionFigureEvent Event)
	{
		//VincentFigure.AkComp.HazePostEvent(Event.AudioEvent);
		PlayFoghornBark(Event.VOAsset, VincentFigure);
	}

	UFUNCTION(NetFunction)
	void Net_ResetButtonLeo()
	{
		LeoButton.ResetButton();
	}

	UFUNCTION(NetFunction)
	void Net_ResetButtonVincent()
	{
		VincentButton.ResetButton();
	}

	UFUNCTION(NetFunction)
	void Net_ResetBothButtons()
	{
		LeoButton.ResetButton();
		VincentButton.ResetButton();
	}

	//Called Locally post sequence.
	UFUNCTION()
	void ResetBothButtons()
	{
		LeoButton.ResetButton();
		VincentButton.ResetButton();
	}
}
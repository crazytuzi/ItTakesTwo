import Vino.Camera.Actors.StaticCamera;

enum EMenuAmbienceTransitionState 
{
	None,
	MenuStart,
	RoseRoom
}

class AMainMenuAmbienceManager : AHazeActor
{
	UPROPERTY(DefaultComponent, NotEditable)
	UHazeAkComponent MenuHazeAkComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeListenerComponent MenuListenerComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UHazeListenerComponent SecondMenuListenerComp;

	UPROPERTY()
	AStaticCamera StartSceneCamera;

	UPROPERTY()
	AStaticCamera RoseRoomCamera;	

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MaySelectedMoveSlow;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MaySelectedMoveFast;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayUnselectedMoveSlow;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayUnselectedMoveFast;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodySelectedMoveSlow;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodySelectedMoveFast;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyUnselectedMoveSlow;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyUnselectedMoveFast;

	private TArray<UHazeListenerComponent> Listeners;

	private bool bIsLerpingListeners = false;
	private float FinalLerpDuration = 0.f;
	private float CurrentLerpDuration = 0.f;
	private EMenuAmbienceTransitionState CurrentTransitionState;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Listeners.Add(MenuListenerComp);
		Listeners.Add(SecondMenuListenerComp);

		for(auto& Listener : Listeners)
		{
			Listener.SetWorldLocation(StartSceneCamera.GetActorLocation());
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bIsLerpingListeners)
			return;

		if(CurrentLerpDuration >= FinalLerpDuration)
		{
			bIsLerpingListeners = false;
			CurrentLerpDuration = 0.f;
			return;
		}

		const float Alpha = CurrentLerpDuration / FinalLerpDuration;
		FVector TargetFrameLocation = FMath::Lerp(GetListenerStartPosition(), GetListenerTargetPosition(), Alpha);

		for(auto& Listener : Listeners)
		{
			Listener.SetWorldLocation(TargetFrameLocation);			
		}	

		CurrentLerpDuration += DeltaSeconds;	
	}

	void StartLerpingListeners(EMenuAmbienceTransitionState TransitionState, float Duration)
	{
		if(TransitionState == EMenuAmbienceTransitionState::None)
			return;
			
		CurrentTransitionState = TransitionState;
		FinalLerpDuration = Duration;
		bIsLerpingListeners = true;
	}

	FVector GetListenerStartPosition()
	{
		switch(CurrentTransitionState)
		{
			case(EMenuAmbienceTransitionState::MenuStart):
				return RoseRoomCamera.GetActorLocation();

			case(EMenuAmbienceTransitionState::RoseRoom):
				return StartSceneCamera.GetActorLocation();
		}

		return StartSceneCamera.GetActorLocation();
	}

	FVector GetListenerTargetPosition()
	{
		switch(CurrentTransitionState)
		{
			case(EMenuAmbienceTransitionState::MenuStart):
				return StartSceneCamera.GetActorLocation();

			case(EMenuAmbienceTransitionState::RoseRoom):
				return RoseRoomCamera.GetActorLocation();
		}

		return StartSceneCamera.GetActorLocation();
	}

	UFUNCTION(BlueprintCallable)
	void PlayCharacterSelected(EHazePlayer Player, bool bOtherCharacterSelected)
	{
		UAkAudioEvent SelectionEvent;

		if(Player == EHazePlayer::May)
		{
			if(bOtherCharacterSelected)
			{
				SelectionEvent = MaySelectedMoveFast;
			}
			else
			{
				SelectionEvent = MaySelectedMoveSlow;	
			}
		}
		else if(bOtherCharacterSelected)
		{
			SelectionEvent = CodySelectedMoveFast;
		}
		else
		{
			SelectionEvent = CodySelectedMoveSlow;
		}

		UHazeAkComponent::HazePostEventFireForget(SelectionEvent, FTransform());		
	}

	UFUNCTION(BlueprintCallable)
	void PlayCharacterUnselected(EHazePlayer Player)
	{
		UAkAudioEvent SelectionEvent;
		if(Player == EHazePlayer::May)
		{			
			SelectionEvent = MayUnselectedMoveFast;
		}
		else
		{
			SelectionEvent = CodyUnselectedMoveSlow;
		}

		UHazeAkComponent::HazePostEventFireForget(SelectionEvent, FTransform());	
	}

}
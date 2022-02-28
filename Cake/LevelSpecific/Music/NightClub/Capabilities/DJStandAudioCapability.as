import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;

enum EDJStandAudioState
{
	Inactive,
	HasActivated,
	IsInteracting,
	Finished
}

class UDJStandAudioCapability : UHazeCapability
{

	UPROPERTY()
	UAkAudioEvent OnStationActivatedEvent;

	UPROPERTY()
	UAkAudioEvent OnStartInteractionEvent;

	UPROPERTY()
	UAkAudioEvent OnStopInteractionEvent;

	UPROPERTY()
	UAkAudioEvent OnStationSuccessEvent;	
	
	UPROPERTY()
	UAkAudioEvent OnStationFailEvent;
	
	UPROPERTY()
	UAkAudioEvent OnIncreaseProgressEvent;

	UPROPERTY()
	UAkAudioEvent OnDecreaseProgressEvent;

	UPROPERTY()
	UAkAudioEvent OnStartAnimationEvent;

	UPROPERTY()
	UAkAudioEvent OnStopAnimationEvent;

	UPROPERTY(VisibleAnywhere)
	FString ProgressRtpcName = "Rtpc_Gadgets_DJStand_Interaction_Progress";

	ADJVinylPlayer DJStand;
	UHazeAkComponent DJStandHazeAkComp;
	private EDJStandAudioState CurrentAudioState = EDJStandAudioState::Inactive;
	private float LastStationProgressValue = 0.f;
	private bool bDjAnimationHandled = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DJStand = Cast<ADJVinylPlayer>(Owner);
		DJStandHazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
		DJStand.OnSuccess.AddUFunction(this, n"OnStationSuccess");
		DJStand.OnFailure.AddUFunction(this, n"OnStationFail");

		FVector2D ScreenPos;
		SceneView::ProjectWorldToScreenPosition(SceneView::GetFullScreenPlayer(), DJStand.GetActorLocation(), ScreenPos);
		const float NormalizedHorizontalPos = HazeAudio::NormalizeRTPC(ScreenPos.X, 0.f, 1.f, -1.f, 1.f);
		HazeAudio::SetPlayerPanning(DJStandHazeAkComp, nullptr, NormalizedHorizontalPos);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(DJStand == nullptr || !DJStand.bIsDJStandActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DJStandHazeAkComp.HazePostEvent(OnStationActivatedEvent);
		CurrentAudioState = EDJStandAudioState::HasActivated;
		bDjAnimationHandled = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioInteractionStarted") == EActionStateStatus::Active)
		{
			if(CurrentAudioState == EDJStandAudioState::HasActivated)
			{
				DJStandHazeAkComp.HazePostEvent(OnStartInteractionEvent);
				CurrentAudioState = EDJStandAudioState::IsInteracting;
				LastStationProgressValue = DJStand.Progress;
			}
		}

		if(ConsumeAction(n"AudioInteractionStopped") == EActionStateStatus::Active)
		{
			if(CurrentAudioState == EDJStandAudioState::IsInteracting && DJStand.AvailablePlayers.Num() == 0)
			{
				DJStandHazeAkComp.HazePostEvent(OnStopInteractionEvent);
				CurrentAudioState = DJStand.bIsDJStandActive ? EDJStandAudioState::HasActivated : EDJStandAudioState::Inactive;
			}
		}

		if(ConsumeAction(n"AudioAnimationStarted") == EActionStateStatus::Active)
		{
			DJStandHazeAkComp.HazePostEvent(OnStartAnimationEvent);
			bDjAnimationHandled = false;
		}

		if(ConsumeAction(n"AudioAnimationStopped") == EActionStateStatus::Active)
		{
			DJStandHazeAkComp.HazePostEvent(OnStopAnimationEvent);
			bDjAnimationHandled = true;
		}

		if(CurrentAudioState != EDJStandAudioState::IsInteracting)
			return;

		const float CurrentProgress = DJStand.Progress;
		
		if(CurrentProgress != LastStationProgressValue)
		{
			DJStandHazeAkComp.SetRTPCValue(ProgressRtpcName, CurrentProgress);
			LastStationProgressValue = CurrentProgress;
		}	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!DJStand.bIsDJStandActive && bDjAnimationHandled)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CurrentAudioState = EDJStandAudioState::Finished;	
	}

	UFUNCTION()
	void OnStationSuccess(ADJVinylPlayer DJStand, AHazePlayerCharacter PlayerCharacter, float BassDropValue)
	{
		DJStandHazeAkComp.HazePostEvent(OnStationSuccessEvent);		
	}

	UFUNCTION()
	void OnStationFail(ADJVinylPlayer DJStand, AHazePlayerCharacter PlayerCharacter, float BassDropValue)
	{
		DJStandHazeAkComp.HazePostEvent(OnStationFailEvent);
	}
}
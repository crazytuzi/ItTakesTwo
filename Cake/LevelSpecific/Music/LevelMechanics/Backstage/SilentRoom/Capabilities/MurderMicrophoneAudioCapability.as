import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophonesAudioStatics;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.Capabilities.MurderMicrophone;

class UMurderMicrophoneAudioCapability : UHazeCapability
{
	AMurderMicrophone MurderMicHead;
	UMurderMicrophonesAudioManager MurderMicAudioManager;

	UPROPERTY()
	TMap<int32, UAkAudioEvent> HeadStateEvents;

	UPROPERTY(Category = "Movement Events")
	UAkAudioEvent StartMovementEvent;

	UPROPERTY(Category = "Movement Events")
	UAkAudioEvent StopMovementEvent;

	private EMurderMicrophoneHeadState LastHeadState;
	private FHazeAudioEventInstance LastStatePostEvent;

	private float LastHeadDistExtended;
	private float LastHeadTilt;
	private float LastMovementDirection;
	private float LastDistToBase;
	FVector LastLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MurderMicHead = Cast<AMurderMicrophone>(Owner);
		MurderMicAudioManager = GetMurderMicAudioManager();
		MurderMicAudioManager.RegisterMurderMicrophone(MurderMicHead);
	}	

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MurderMicHead.IsSnakeDestroyed())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MurderMicHead == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(MurderMicHead.IsSnakeDestroyed())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UAkAudioEvent StartingState;
		HeadStateEvents.Find(int(MurderMicHead.CurrentState), StartingState);
		LastStatePostEvent = MurderMicHead.HazeAkComp.HazePostEvent(StartingState);

		if (!MurderMicHead.HazeAkComp.HazeIsEventActive(StartMovementEvent.ShortID))
			MurderMicHead.HazeAkComp.HazePostEvent(StartMovementEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MurderMicHead.HazeAkComp.HazePostEvent(StopMovementEvent);
		if (LastStatePostEvent.PlayingID != 0)
			MurderMicHead.HazeAkComp.HazeStopEvent(LastStatePostEvent.PlayingID);
		MurderMicAudioManager.UnregisterMurderMicrophone(MurderMicHead);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		EMurderMicrophoneHeadState HeadState = EMurderMicrophoneHeadState::Sleeping;
		HandleStateChanged(HeadState);	
		HandleHeadRtpc();
	}

	void HandleStateChanged(EMurderMicrophoneHeadState& OutHeadState)
	{		
		if(!DidStateChange(OutHeadState))
			return;

		UAkAudioEvent NewStateEvent;
		HeadStateEvents.Find(int(OutHeadState), NewStateEvent);

		if(NewStateEvent == nullptr)
			return;

		LastStatePostEvent = MurderMicHead.HazeAkComp.HazePostEvent(NewStateEvent);
	}

	bool DidStateChange(EMurderMicrophoneHeadState& OutNewState)
	{
		if(LastHeadState != MurderMicHead.CurrentState)
		{
			const bool bWasHypnotized = LastHeadState == EMurderMicrophoneHeadState::Hypnosis;
			const bool bIsHypnotized = MurderMicHead.CurrentState == EMurderMicrophoneHeadState::Hypnosis;
			
			const bool bWasAggro = LastHeadState == EMurderMicrophoneHeadState::Aggressive;
			const bool bIsAggro = MurderMicHead.CurrentState == EMurderMicrophoneHeadState::Aggressive;

			OutNewState = MurderMicHead.CurrentState;
			LastHeadState = MurderMicHead.CurrentState;

			if(bWasHypnotized)
				MurderMicAudioManager.RemoveHypnotizedMicrophone(MurderMicHead);
			if(bIsHypnotized)
				MurderMicAudioManager.AddHypnotizedMicrophone(MurderMicHead);

			if(bWasAggro)
				MurderMicAudioManager.RemoveAggressiveMicrophone(MurderMicHead);
			if(bIsAggro)
				MurderMicAudioManager.AddAggressiveMicrophone(MurderMicHead);

			return true;
		}

		return false;
	}

	void HandleHeadRtpc()
	{
		const float HeadDistToBase = MurderMicHead.DistanceToBase2D / MurderMicHead.MaxLength;
		if(HeadDistToBase != LastHeadDistExtended)
		{
			MurderMicHead.HazeAkComp.SetRTPCValue("Rtpc_Cha_Enm_MurderMicrophone_Cord_Extended_Length", HeadDistToBase);
			LastHeadDistExtended = HeadDistToBase;
		}

		const float HeadMovementDelta = HazeAudio::NormalizeRTPC01(FMath::Abs(MurderMicHead.DistanceToBase2D - LastDistToBase), 0.f, 60.f);
		MurderMicHead.HazeAkComp.SetRTPCValue("Rtpc_Cha_Enm_MurderMicrophone_Cord_Extended_Delta", HeadMovementDelta);

		const float HeadMovementDirection = FMath::Sign(MurderMicHead.DistanceToBase2D - LastDistToBase);
		if(LastMovementDirection != HeadMovementDirection)
		{
			MurderMicHead.HazeAkComp.SetRTPCValue("Rtpc_Cha_Enm_MurderMicrophone_Head_Movement_Direction", HeadMovementDirection);
			LastMovementDirection = HeadMovementDirection;
		}

		FVector WorldUp = MurderMicHead.HeadUpVector;
		FVector HeadLocation = MurderMicHead.GetActorLocation();
		FVector HeadVelo = (HeadLocation - LastLocation).GetSafeNormal();
		const float HeadTilt = WorldUp.DotProduct(HeadVelo);

		if(HeadTilt != LastHeadTilt)
		{
			MurderMicHead.HazeAkComp.SetRTPCValue("Rtpc_Cha_Enm_MurderMicrophone_Head_Tilt", HeadTilt);
			LastHeadTilt = HeadTilt;
		}

		LastLocation = HeadLocation;
		LastDistToBase = MurderMicHead.DistanceToBase2D;

		/*
		if (MurderMicHead.CurrentState == EMurderMicrophoneHeadState::Sleeping)
			return;

		PrintToScreen("Length: " + HeadDistToBase);
		PrintToScreen("Delta: " + HeadMovementDelta);
		PrintToScreen("Direction: " + HeadMovementDirection);
		PrintToScreen("Tilt: " + HeadTilt);
		*/		
	}

}
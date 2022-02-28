class UMurderMicrophonesAudioManager : UActorComponent
{
	TArray<AHazeActor> MurderMicrophones;
	int32 HypnotizedCount = 0;
	int32 AggressiveCount = 0;
	default SetComponentTickEnabled(false);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Reset::RegisterPersistentComponent(this);
	}

	void RegisterMurderMicrophone(AHazeActor& Microphone)
	{
		MurderMicrophones.AddUnique(Microphone);
	}

	void AddAggressiveMicrophone(AHazeActor& Microphone)
	{
		if(AggressiveCount == 0)
			AkGameplay::SetState(n"MStg_Music_Backstage", n"MStt_Music_Backstage_Microphones_Active");
		
		AggressiveCount++;
	}

	void RemoveAggressiveMicrophone(AHazeActor& Microphone)
	{
		AggressiveCount--;
		if(AggressiveCount == 0)
			AkGameplay::SetState(n"MStg_Music_Backstage", n"MStt_Music_Backstage_Microphones_Passive");
	}

	void AddHypnotizedMicrophone(AHazeActor& Microphone)
	{
		if(HypnotizedCount == 0)
			UHazeAkComponent::HazeSetGlobalRTPCValue("RTPC_Backstage_Charm", 1.f);
		
		HypnotizedCount ++;	
	}

	void RemoveHypnotizedMicrophone(AHazeActor& Microphone)
	{
		HypnotizedCount --;
		if(HypnotizedCount == 0)
			UHazeAkComponent::HazeSetGlobalRTPCValue("RTPC_Backstage_Charm", 0.f);				
	}

	void UnregisterMurderMicrophone(AHazeActor& Microphone)
	{
		MurderMicrophones.RemoveSwap(Microphone);
		if(MurderMicrophones.Num() == 0)
			Reset::UnregisterPersistentComponent(this);
	}
}
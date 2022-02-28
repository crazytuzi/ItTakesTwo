import Peanuts.Audio.AudioStatics;

class UAudioExamples : AHazeActor
{
	/*

	AudioStatics houses a lot of great wrappers, variables and other static values that is useful 
	when adding audio functionality to actors or components. The Library is accessed through namespace HazeAudio::

	*/

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MyAudioEvent;
	
	FHazeAudioEventInstance MyEventInstance;

	UPROPERTY(NotVisible)
	FString MyRtpcName = HazeAudio::RTPC::CharacterSpeakerPanningLR.Name;

	// Use (when) as the name suggests.
	UPROPERTY(NotVisible)
	FHazeAkRTPC MyRtpcNameThatWillBeUsedInTick = HazeAudio::RTPC::CharacterSpeakerPanningLR;

	UFUNCTION()
	void HazeAkComponent()
	{
		// ----- Posting Events -----

			// ----- Managed -----
			HazeAkComp = UHazeAkComponent::GetOrCreate(this);
			MyEventInstance = HazeAkComp.HazePostEvent(MyAudioEvent, EventTag = n"Hapschaiki");
			TArray<FHazeAudioEventInstance> MyOtherEventInstances = HazeAkComp.GetEventInstancesByTag(n"Hapschaiki");
			
			//HazeAkComp.HazePostEventQueued(MyAudioEvent, EventTag = n"QueuedHapsch");
			
			// ----- Unmanaged -----
		
				// If location is from an actor
				//UHazeAkComponent::HazePostEventFireForget(MyAudioEvent, MyActor.GetActorTransform());

				// If location is from a component
				//UHazeAkComponent::HazePostEventFireForget(MyAudioEvent, MyComponent.GetWorldTransform());

				// if location is from a vector (Hit results for example)
				//UHazeAkComponent::HazePostEventFireForget(MyAudioEvent, FTransform(MyVector)));

			//FireAndForgetWithRtpcs

			TMap<FString, float> Rtpcs;
			Rtpcs.Add("Rtpc_Gameplay_Explosions_Shared_VolumeOffset", -8.f);

			UHazeAkComponent::HazePostEventFireForgetWithRtpcs(MyAudioEvent, FTransform(), Rtpcs);

			// ----- Do not stop on destroy -----

			HazeAkComp.SetStopWhenOwnerDestroyed(false);
		
		// ----- Setting parameters -----


		//HazeAkComp.SetRTPCValue(FString HazeAudio::RTPC::MyRTPCName, float ValueToSet, int InterpolationTimeMS);
		//HazeAkComp.SetSwitch(FString HazeAudio::Switch::MySwitchGroup, FString HazeAudio::Switch::MySwitch);

		//UHazeAkComponent::HazeSetGlobalRTPCValue(FString HazeAudio::RTPC::MyRTPCString, float ValueToSet, int InterpolationTimeMS);	


		// TrackVelocity - Rtpc_Object_Velocity
		//HazeAkComp.SetTrackVelocity(bTrackVelocity, MaxSpeed);

		// ----- Operations on Event Instances ----- 

		int32 MyPlayingID = MyEventInstance.PlayingID;

		//HazeAkComp.HazeStopEvent(MyPlayingID, 3000.f, EAkCurveInterpolation::InvSCurve);
		//HazeAkComp.SeekOnPlayingEvent(MyAudioEvent, MyPlayingID, 50.f, bRandomSeek = true, bSeekToNearestMarker = false);
		
		float OutRTPCValue;
		//float CurrentRTPCValue = HazeAkComp.GetRTPCValue(HazeAudio::RTPC::MyRtpcString, MyPlayingID, ERTPCValueType::PlayingID, OutRTPCValue, ERTPCValueType::PlayingID);



		//Add PlayerHazeAkComp

		UPlayerHazeAkComponent PlayerHazeAkComp;

		//PlayerHazeAkComp = UHazeAkComponent::GetOrCreate(Player);

		//Cast PlayerHazeAkComp

		AHazePlayerCharacter OwningPlayer = Cast<AHazePlayerCharacter>(Owner);



	}


}


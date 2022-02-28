import Vino.Audio.Music.MusicCallbackSubscriberComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SqueezeBox.SqueezeBox;

struct FNoteEventData
{
	UPROPERTY()
	UAkAudioEvent NoteEvent;

	UPROPERTY()
	FName NoteName;
}

class USqueezeBoxNoteTrackingAudioCapability : UHazeCapability
{
	UPROPERTY()
	TArray<FNoteEventData> NoteEventDatas;
	
	ASqueezeBox SqueezeBox;
	UMusicCallbackSubscriberComponent CallbackSubComp;

	UAkAudioEvent CurrentNoteEvent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SqueezeBox = Cast<ASqueezeBox>(Owner);
		CallbackSubComp = UMusicCallbackSubscriberComponent::GetOrCreate(Owner);
		CallbackSubComp.OnMusicSyncCustomCue.AddUFunction(this, n"OnNoteChanged");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SqueezeBox.bActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SqueezeBox.bActive)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CallbackSubComp.OnMusicSyncCustomCue.UnbindObject(this);
	}

	UFUNCTION()
	void OnNoteChanged(FName CueName)
	{
		for(auto NoteEventData : NoteEventDatas)
		{
			if(NoteEventData.NoteName.ToString().ToLower() == CueName.ToString().ToLower())
			{
				CurrentNoteEvent = NoteEventData.NoteEvent;
				break;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ConsumeAction(n"AudioStartSpawnProjectile") == EActionStateStatus::Active)
		{
			SqueezeBox.HazeAkComp.HazePostEvent(CurrentNoteEvent);
		}
	}	
}
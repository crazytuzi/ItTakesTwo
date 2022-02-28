import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

class UGameSettingsApplicator: UHazeGameSettingsApplicatorBase
{
	UFUNCTION(BlueprintOverride)
	bool ApplyAudioSpeakerTypeSettings(EHazeAudioSpeakerType SpeakerType)
	{
		UHazeAudioManager AudioManager = GetAudioManager();
		return AudioManager.SetAudioSpeakerTypeSetting(SpeakerType);
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioChannelSetupSettings(EHazeAudioChannelSetup ChannelType)
	{
		UHazeAudioManager AudioManager = GetAudioManager();
		return AudioManager.SetAudioChannelSetupSetting(ChannelType);
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioDynamicRangeSettings(EHazeAudioDynamicRange DynamicRange)
	{
		UHazeAudioManager AudioManager = GetAudioManager();
		return AudioManager.SetAudioDynamicRangeSetting(DynamicRange);
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioMasterVolume(float Value)
	{
		UHazeAudioManager AudioManager = GetAudioManager();
		AudioManager.SetAudioMasterVolume(Value);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioVoiceVolume(float Value)
	{
		UHazeAudioManager AudioManager = GetAudioManager();
		AudioManager.SetAudioVoiceVolume(Value);
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ApplyAudioMusicVolume(float Value)
	{
		UHazeAudioManager AudioManager = GetAudioManager();
		AudioManager.SetAudioMusicVolume(Value);
		return true;
	}
}
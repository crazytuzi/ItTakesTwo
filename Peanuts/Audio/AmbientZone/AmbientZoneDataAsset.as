class UAmbientZoneDataAsset : UDataAsset
{
	UPROPERTY(Category="Quad")
	float AttenuationScalingFactor = 1;

	UPROPERTY(Category="Quad")
	float OcclusionRefreshInterval = 0;

	UPROPERTY(Category="Quad")
	bool bUseReverbVolumes = true;

	UPROPERTY(Category="Quad")
	UAkAudioEvent QuadEvent;

	UPROPERTY(Category="Reverb")
	UAkAuxBus ReverbBus;

	UPROPERTY(Category="Reverb")
	bool bStealReverbSends = false;

	UPROPERTY(Category="Reverb")
	float SendLevel = 1;

	UPROPERTY(Category="Reflection/Delay")
	UAmbientZoneStaticReflectionData StaticReflection;
}

struct FRandomSpotSound
{
	UPROPERTY()
	float MinRepeatRate;

	UPROPERTY()
	float MaxRepeatRate;

	float CurrentTime;
	float NextTime;

	UPROPERTY()
	float MinLength;

	UPROPERTY()
	float MaxLength;

	UPROPERTY()
	UAkAudioEvent Event;
}

class URandomSpotSoundsDataAsset : UDAtaAsset
{
	UPROPERTY()
	TArray<FRandomSpotSound> SpotSounds;
}

class UAmbientZoneStaticReflectionData : UDataAsset
{
	UPROPERTY()
	FReflectionTraceValues FrontLeftValues;
	UPROPERTY()
	FReflectionTraceValues FrontRightValues;
}
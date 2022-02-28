import Cake.LevelSpecific.Music.MusicTargetingCapability;
import Cake.LevelSpecific.Music.Singing.SingingSettings;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class UPowerfulSongTargetingCapability : UMusicTargetingCapability
{
	default CapabilityTags.Add(n"PowerfulSong");

	USingingSettings Settings;

	default ActivationPointClass = USongReactionComponent::StaticClass();

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
		Settings = USingingSettings::GetSettings(Owner);
	}

	float GetTargetingMaxTrace() const
	{
		return Settings.SingingRange;
	}

	FVector GetTraceStartPoint() const
	{
		return Owner.ActorCenterLocation;
	}
	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!TargetingComp.bIsTargeting)
			Player.UpdateActivationPointAndWidgets(USongReactionComponent::StaticClass());
	}
}

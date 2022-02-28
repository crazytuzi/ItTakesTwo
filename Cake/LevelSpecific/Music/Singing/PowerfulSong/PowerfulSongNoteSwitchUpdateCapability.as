import Peanuts.Audio.AudioStatics;
import Vino.Audio.Music.MusicCallbackSubscriberComponent;
import Cake.LevelSpecific.Music.Singing.SingingComponent;

class UPowerfulSongNoteSwitchUpdateCapability : UHazeCapability
{
	UMusicCallbackSubscriberComponent SubComp;	
	USingingComponent SingComp;
	UHazeAkComponent HazeAkComp;

	default CapabilityTags.Add(n"PowerfulSongNoteSwitchUpdateCapability");

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{	
		SubComp = UMusicCallbackSubscriberComponent::GetOrCreate(Owner);
		SingComp = USingingComponent::Get(Owner);	
		HazeAkComp = UHazeAkComponent::Get(Owner);	
	}
}
import Vino.Audio.Music.MusicCallbackSubscriberComponent;
import Cake.LevelSpecific.Music.NightClub.NightclubBeatFXComponent;
class NightclubBeatFXCapability : UHazeCapability

{
	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityTags.Add(n"NightclubBeatFXCapability");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UMusicCallbackSubscriberComponent MusicSubComp;

	UNightclubBeatFXComponent BeatComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MusicSubComp = UMusicCallbackSubscriberComponent::GetOrCreate(Player);
		BeatComp = UNightclubBeatFXComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
		// return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
		// return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MusicSubComp.OnMusicSyncBeat.AddUFunction(this, n"CallBeatWasMade");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MusicSubComp.OnMusicSyncBeat.Unbind(this, n"CallBeatWasMade");
		BeatComp.ClearPreviousFX();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
	}

	UFUNCTION()
	void CallBeatWasMade(FAkSegmentInfo Info)
	{
		BeatComp.BeatWasMade();
	}

}
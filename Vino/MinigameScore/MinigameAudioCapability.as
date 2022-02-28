import Peanuts.Audio.AudioStatics;
import Vino.MinigameScore.MinigameAudioComponent;

class UMinigameAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(MinigameCapabilityTags::Minigames);
	
	UMinigameAudioComponent MiniGameAudioComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MiniGameAudioComp = UMinigameAudioComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MiniGameAudioComp.MiniGameComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!MiniGameAudioComp.MiniGameComp.bPlayersInRange)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	/*

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UObject RawObject;
		if(ConsumeAttribute(n"OnPlayerJoined", RawObject))
		{
			AHazePlayerCharacter JoiningPlayer = Cast<AHazePlayerCharacter>(RawObject);
			if(JoiningPlayer != nullptr)
				JoiningPlayer.PlayerHazeAkComp.HazePostEvent(UISounds.OnPlayerJoinEvent);
		}
	}
	*/
	
}
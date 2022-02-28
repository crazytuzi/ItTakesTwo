import Peanuts.Audio.AudioStatics;

class UDefaultPlayerPanningCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"Audio";
	default CapabilityTags.Add(n"AudioPanning");

	AHazePlayerCharacter Player;
	UPlayerHazeAkComponent HazeAkComp;	

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner, n"PlayerHazeAkComponent"); 
	}

	UFUNCTION(BlueprintOverride)
    EHazeNetworkActivation ShouldActivate() const
    {
        return EHazeNetworkActivation::ActivateLocal;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		HazeAudio::SetPlayerPanning(HazeAkComp, Player);
	}

}
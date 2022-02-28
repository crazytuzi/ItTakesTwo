import Cake.LevelSpecific.Music.Smooch.Smooch;

class USmoochAudioCapability : UHazeCapability
{	
	USmoochUserComponent SmoochComp;
	AHazePlayerCharacter Player;
	private float LastUserSmoochProgress;
	TArray<FPlayAudioOnSmoochProgress> ProgressDatas;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SmoochComp = USmoochUserComponent::Get(Owner);
		ProgressDatas = Player.IsMay() ? SmoochComp.MayAudioSmoochProgressDatas : SmoochComp.CodyAudioSmoochProgressDatas;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(FPlayAudioOnSmoochProgress& ProgressData : ProgressDatas)
		{
			if(!ShouldPlayAudio(ProgressData))
				continue;

			Player.PlayerHazeAkComp.HazePostEvent(ProgressData.ProgressAudioEvent);
		}

		LastUserSmoochProgress = SmoochComp.Progress;

	}

	bool ShouldPlayAudio(const FPlayAudioOnSmoochProgress& SmoochAudioProgress)
	{
		if(SmoochComp.Progress >= SmoochAudioProgress.ProgressToPlayAudio && LastUserSmoochProgress < SmoochAudioProgress.ProgressToPlayAudio)
			return true;
		else if(SmoochComp.Progress <= SmoochAudioProgress.ProgressToPlayAudio && LastUserSmoochProgress > SmoochAudioProgress.ProgressToPlayAudio)
			return true;

		return false;
	}

}
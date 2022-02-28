import Cake.LevelSpecific.Clockwork.Townsfolk.StaticTownsFolkActor;

class ATownsfolkDerbySpectator : AStaticTownsFolkActor
{
	UPROPERTY()
	UAnimSequence WaitingMh;

	UPROPERTY()
	UAnimSequence RaceActiveMh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayWaitMh();
	}

	UFUNCTION()
	void PlayWaitMh()
	{
		PlayEventAnimation(Animation = WaitingMh, bLoop = true, BlendTime = 1.f);
	}

	UFUNCTION()
	void PlayRaceActiveMh()
	{
		PlayEventAnimation(Animation = RaceActiveMh, bLoop = true, BlendTime = 1.f);
	}
}
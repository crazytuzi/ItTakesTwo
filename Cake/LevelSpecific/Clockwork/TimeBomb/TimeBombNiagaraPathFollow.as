class ATimeBombNiagaraPathFollow : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UNiagaraComponent NiagaraComp;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventStartTrail;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EventEndTrail;

	void RenderForPlayer(AHazePlayerCharacter Player)
	{
		if (Player == Game::May)
		{
			NiagaraComp.SetRenderedForPlayer(Player, true);
			NiagaraComp.SetRenderedForPlayer(Game::Cody, false);
		}
		else
		{
			NiagaraComp.SetRenderedForPlayer(Player, true);
			NiagaraComp.SetRenderedForPlayer(Game::May, false);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		AudioStartTrail();
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		AudioEndTrail();
	}

	void AudioStartTrail()
	{
		AkComp.HazePostEvent(EventStartTrail);
	}
	
	void AudioEndTrail()
	{
		AkComp.HazePostEvent(EventEndTrail);
	}
}
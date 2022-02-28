import Cake.LevelSpecific.Music.KeyBird.KeyBirdBehaviorComponent;

event void FKeyBirdTeam_StealKeyStart(AHazeActor KeyBird, AHazeActor Target);
event void FKeyBirdTeam_StealKeyStop(AHazeActor KeyBird, AHazeActor Target, bool bSuccess);

enum EKeyBirdTeamCounterType
{
	KeySeeker,
	KeyStealer,
	None
}

class UKeyBirdTeam : UHazeAITeam
{
	// Birds that are currently attempting to locate a key with no follow target.
	private TArray<AHazeActor> Seekers;
	// Birds that are currently attempting to steal a key from a player.
	private TArray<AHazeActor> Stealers;

	bool IsBirdSeeking(AHazeActor KeyBird) const
	{
		return Seekers.Contains(KeyBird);
	}

	int GetNumKeySeekers() const property
	{
		return Seekers.Num();
	}

	int GetNumKeyStealers() const property
	{
		return Stealers.Num();
	}

	FKeyBirdTeam_StealKeyStart OnKeyBirdStealKeyStart;
	FKeyBirdTeam_StealKeyStop OnKeyBirdStealKeyStop;
	
	UFUNCTION(BlueprintOverride)
	void OnMemberJoined(AHazeActor Member)
	{
		UKeyBirdBehaviorComponent KeyBirdBehavior = UKeyBirdBehaviorComponent::Get(Member);
		KeyBirdBehavior.OnKeyBirdStealKeyStart.AddUFunction(this, n"Handle_KeyBirdStealKeyStart");
		KeyBirdBehavior.OnKeyBirdStealKeyStop.AddUFunction(this, n"Handle_KeyBirdStealKeyStop");
		KeyBirdBehavior.OnKeyBirdSeekKeyStart.AddUFunction(this, n"Handle_KeyBirdSeekKeyStart");
		KeyBirdBehavior.OnKeyBirdSeekKeyStop.AddUFunction(this, n"Handle_KeyBirdSeekKeyStop");
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		UKeyBirdBehaviorComponent KeyBirdBehavior = UKeyBirdBehaviorComponent::Get(Member);
		
		KeyBirdBehavior.OnKeyBirdStealKeyStart.Unbind(this, n"Handle_KeyBirdStealKeyStart");
		KeyBirdBehavior.OnKeyBirdStealKeyStop.Unbind(this, n"Handle_KeyBirdStealKeyStop");
		KeyBirdBehavior.OnKeyBirdSeekKeyStart.Unbind(this, n"Handle_KeyBirdSeekKeyStart");
		KeyBirdBehavior.OnKeyBirdSeekKeyStop.Unbind(this, n"Handle_KeyBirdSeekKeyStop");

		RemoveSeeker(Member);
		RemoveStealer(Member);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_KeyBirdStealKeyStart(AHazeActor KeyBird, AHazeActor Target)
	{
		AddStealer(KeyBird);
		OnKeyBirdStealKeyStart.Broadcast(KeyBird, Target);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_KeyBirdStealKeyStop(AHazeActor KeyBird, AHazeActor Target, bool bSuccess)
	{
		RemoveStealer(KeyBird);
		OnKeyBirdStealKeyStop.Broadcast(KeyBird, Target, bSuccess);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_KeyBirdSeekKeyStart(AHazeActor KeyBird, AHazeActor Target)
	{
		AddSeeker(KeyBird);
	}

	UFUNCTION(NotBlueprintCallable)
	private void Handle_KeyBirdSeekKeyStop(AHazeActor KeyBird, AHazeActor Target, bool bSuccess)
	{
		RemoveSeeker(KeyBird);
	}

	private void AddSeeker(AHazeActor NewSeeker)
	{
		if(!Seekers.Contains(NewSeeker))
		{
			Seekers.Add(NewSeeker);
		}
	}

	private void RemoveSeeker(AHazeActor SeekerToRemove)
	{
		Seekers.Remove(SeekerToRemove);
	}

	private void AddStealer(AHazeActor NewStealer)
	{
		if(!Stealers.Contains(NewStealer))
		{
			Stealers.Add(NewStealer);
		}
	}

	private void RemoveStealer(AHazeActor StealerToRemove)
	{
		Stealers.Remove(StealerToRemove);
	}
}

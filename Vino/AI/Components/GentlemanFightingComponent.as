struct FGentlemanSemaphore
{
	TArray<UObject> Claimants;
};

// Component to set on player or team when you need to synchronize 
// attacks between several AIs. Remember to adhere to the Queensberry rules!
class UGentlemanFightingComponent : UActorComponent
{

    // Keeps track of which opponents are considering attacking us
    TArray<AHazeActor> Opponents;
    int32 GetNumOtherOpponents(AHazeActor PotentialOpponent)
    {
        if (Opponents.Contains(PotentialOpponent))
            return Opponents.Num() - 1;
        return Opponents.Num();
    }

    // Keeps track of when, if ever an action with the given tag was performed
    private TMap<FName, float> LastActionTimes;

    // Let's us know action is being performed
    void ReportAttack(const FName& Tag)
    {
        LastActionTimes.Add(Tag, Time::GetGameTimeSeconds());
    }

    // When was action last reported?
    float GetLastActionTime(const FName& Tag)
    {
        float LastTime = 0.f;
        LastActionTimes.Find(Tag, LastTime);
        return LastTime;
    }

    private TMap<FName, FGentlemanSemaphore> ActionSemaphore;
	
	UPROPERTY(BlueprintHidden, EditAnywhere)
	private TMap<FName, int> MaxAllowedClaimants;

	void SetMaxAllowedClaimants(const FName& Tag, int MaxNumber)
	{
		MaxAllowedClaimants.Add(Tag, MaxNumber);
	}

	int GetMaxAllowedClaimants(const FName& Tag)
	{
		int NumClaimants = 1;
		MaxAllowedClaimants.Find(Tag, NumClaimants);
		return NumClaimants;
	}

    // Check if action is available to claim 
    bool IsActionAvailable(const FName& Tag)
    {
		int MaxNumber = 1;
		MaxAllowedClaimants.Find(Tag, MaxNumber);
		if (MaxNumber <= 0)
			return false;

		TArray<UObject> Claimants;
		if (GetClaimants(Tag, Claimants))
			return (Claimants.Num() < MaxNumber);
			
        return true;
    }

	bool HasBeenClaimed() const
	{
		for(auto& Semaphore : ActionSemaphore)
		{
			if(Semaphore.GetValue().Claimants.Num() > 0 )
			{
				return true;
			}
		}
		return false;
	}

	bool IsClaimingAnyAction(UObject Claimant) const
	{
		for(auto& Semaphore : ActionSemaphore)
		{
			if(Semaphore.GetValue().Claimants.Contains(Claimant))
			{
				return true;
			}
		}
		return false;
	}

	void GetAllActionSemaphoreTags(TArray<FName>& OutTags) const
	{
		for(auto& Semaphore : ActionSemaphore)
		{
			OutTags.Add(Semaphore.GetKey());
		}
	}

	void ClearClaimantFromAllSemaphores(UObject Claimant) const
	{
		for(auto& Semaphore : ActionSemaphore)
		{
			Semaphore.GetValue().Claimants.RemoveSwap(Claimant);
		}
	}

	// Check if claimant has already claimed action
	bool IsClaimingAction(const FName& Tag, UObject Claimant)
	{
		FGentlemanSemaphore Claimants;
		if (ActionSemaphore.Find(Tag, Claimants)) 
		{
			return Claimants.Claimants.Contains(Claimant);
		}
		return false;
	}

	// Get all claimants of given tag
	bool GetClaimants(const FName& Tag, TArray<UObject>& Claimants)
	{
		FGentlemanSemaphore Semaphore;
		if (ActionSemaphore.Find(Tag, Semaphore))
		{
			Claimants = Semaphore.Claimants;
			return true;
		}
		return false;
	}

    // Try to claim action. Return true if successful, false if action was unavailable
    bool ClaimAction(const FName& Tag, UObject Claimant)
    {
		int MaxAllowed = 1;
		MaxAllowedClaimants.Find(Tag, MaxAllowed);
		if (MaxAllowed <= 0)
			false;

		if (!ActionSemaphore.Contains(Tag))
		{
			// No entry, so no claimants yet
			FGentlemanSemaphore Semaphore;
			Semaphore.Claimants.Add(Claimant);
			ActionSemaphore.Add(Tag, Semaphore);
			return true;
		}

        // Do we already claim this action?
		FGentlemanSemaphore& Semaphore = ActionSemaphore.FindOrAdd(Tag);
		if (Semaphore.Claimants.Contains(Claimant))
			return true;

		if (Semaphore.Claimants.Num() < MaxAllowed)
		{
			// Fewer than max claimants, claim
			Semaphore.Claimants.Add(Claimant);
			return true;
		}

		// Action is claimed by too many others
		return false;
    }

    // Let us know given object no longer wants to claim action, making it available for others
    void ReleaseAction(const FName& Tag, UObject Claimant)
    {	
		ActionSemaphore.FindOrAdd(Tag).Claimants.RemoveSwap(Claimant);
    }

//	// DEBUG
//	UFUNCTION(BlueprintOverride)
//	void Tick(const float Dt)
//	{
//		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Owner);
//		PrintToScreen("-----------------------------------------", Color = FLinearColor::Red);
//		for(auto IterOpponent : Opponents)
//			PrintToScreen("    Opponent: " + IterOpponent.GetName(), 0.f, FLinearColor::Teal);
//		PrintToScreen("Num Opponents: " + Opponents.Num(), 0.f, FLinearColor::Teal);
//		for(auto AS : ActionSemaphore)
//		{
//			for(auto IterClaimant : AS.GetValue().Claimants)
//				PrintToScreen("    Claimant: " + IterClaimant.GetName(), 0.f, FLinearColor::White);
//			PrintToScreen("ActionSemaphore: " + AS.GetKey() + " | " + "Num Claimants: " + AS.GetValue().Claimants.Num(), 0.f, FLinearColor::White);
//		}
//		PrintToScreen("Owner: " + Owner.GetName(), 0.f, FLinearColor::Yellow);
//	}

}







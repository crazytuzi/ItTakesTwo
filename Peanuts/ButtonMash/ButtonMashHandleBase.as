class UButtonMashHandleBase
{
	// External data
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;
	
	UPROPERTY(BlueprintReadOnly)
	float MashRateControlSide;
	
	UPROPERTY(BlueprintReadOnly)
	float MashRateRemoteSide;

	UPROPERTY(BlueprintReadOnly)
	bool bIsValid;

	UPROPERTY()
	bool bSyncOverNetwork = false;

	UPROPERTY()
	bool bIsExclusive = false;

	// Stores which capabilities are tied to this handle, so that they can
	// be removed when cleaning up
	TArray<TSubclassOf<UHazeCapability>> PushedCapabilities;

	UFUNCTION()
	void PushCapability(TSubclassOf<UHazeCapability> Capability)
	{
		if (!devEnsure(bIsValid, "Trying to push capabilities on an invalid ButtonMash handle"))
			return;

		PushedCapabilities.Add(Capability);
	}

	void StartUp()
	{
		for(TSubclassOf<UHazeCapability> Capability : PushedCapabilities)
			Player.AddCapability(Capability);
	}

	void CleanUp()
	{
		for(TSubclassOf<UHazeCapability> Capability : PushedCapabilities)
			Player.RemoveCapability(Capability);

		PushedCapabilities.Empty();
	}

	void Reset()
	{
		MashRateControlSide = 0.f;
	}

	UFUNCTION(Category = "ButtonMash")
	bool HasRecentInput()
	{
		return MashRateControlSide > KINDA_SMALL_NUMBER;
	}
}
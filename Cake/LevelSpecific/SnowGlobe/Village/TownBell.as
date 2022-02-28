event void FOnTownBellChimeSignature(AHazePlayerCharacter Player, bool bFirstChime);

class ATownBell : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent SceneRoot;

	UPROPERTY()
	FOnTownBellChimeSignature OnBellChime;

	UPROPERTY(BlueprintReadWrite)
	bool bHasChimed;

	UFUNCTION()
	void ChimeBell(AHazePlayerCharacter Player)
	{
		if ((Player == nullptr && HasControl()) || 
			(Player != nullptr && Player.HasControl()))
			NetChimeBell(Player);
	}

	UFUNCTION(NetFunction)
	void NetChimeBell(AHazePlayerCharacter Player)
	{
		OnBellChime.Broadcast(Player, !bHasChimed);
		BP_OnBellChime(Player, !bHasChimed);
		bHasChimed = true;
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBellChime(AHazePlayerCharacter Player, bool bFirstChime)
	{ }

	UFUNCTION()
	void Awake()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION()
	void Sleep()
	{
		SetActorTickEnabled(false);
	}
}
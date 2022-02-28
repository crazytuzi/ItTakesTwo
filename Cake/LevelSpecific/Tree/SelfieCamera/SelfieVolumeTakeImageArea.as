class ASelfieVolumeTakeImageArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "Cam Settings")
	AHazeCameraActor Cam;

	TArray<AHazePlayerCharacter> Players;

	UFUNCTION()
	void AddSelfieImagePlayer(AHazePlayerCharacter Player)
	{
		if (!Players.Contains(Player))
			Players.Add(Player);
	}

	UFUNCTION()
	void RemoveSelfieImagePlayer(AHazePlayerCharacter Player)
	{
		if (Players.Contains(Player))
			Players.Remove(Player);
	}

	UFUNCTION()
	void TakeImageSequenceActivated()
	{
		for (AHazePlayerCharacter Player : Players)
		{
			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 2.75f;
			Cam.ActivateCamera(Player, Blend, this);
		}
	}

	UFUNCTION()
	void TakeImageSequenceDeactivated(AHazePlayerCharacter InPlayer = nullptr)
	{
		if (InPlayer != nullptr)
		{
			Cam.DeactivateCamera(InPlayer, 1.5f);
		}
		else
		{
			for (AHazePlayerCharacter Player : Players)
			{
				Cam.DeactivateCamera(Player, 1.5f);
			}
		}
	}
}
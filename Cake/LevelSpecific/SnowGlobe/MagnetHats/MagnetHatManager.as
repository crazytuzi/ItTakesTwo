import Cake.LevelSpecific.SnowGlobe.MagnetHats.MagnetHat;

class AMagnetHatManager : AHazeActor
{
	UPROPERTY(Category = "MagnetHats")
	TArray<AMagnetHat> Hats;

	UPROPERTY(Category = "Player Feedback")
	UForceFeedbackEffect ForceFeedback;

	bool bPlayersFreeOfHats;
	bool bMayPirateAchievement;
	bool bCodyPirateAchievement;

	bool bHaveAchievement;

	int PlayerCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AMagnetHat Hat : Hats)
		{
			Hat.OnNewAttached.AddUFunction(this, n"HatAchievementCheck");	
		}
	}

	UFUNCTION()
	void PlayerHatCheck()
	{
		if (PlayerCount > 0)
		{
			bPlayersFreeOfHats = false;
		}
		else if (PlayerCount <= 0)
		{
			bPlayersFreeOfHats = true;
			PlayerCount = 0;
		}
	}

	UFUNCTION()
	void HatAchievementCheck(AHazePlayerCharacter Player, AMagnetHat MagnetHat)
	{
		if (MagnetHat.MagnetHatType == EMagnetHatType::PirateHat)
			Online::UnlockAchievement(Player, n"PiratesLifeForMe");
	}

	UFUNCTION()
	void RemoveHatFromPlayers(AHazePlayerCharacter Player)
	{
		for (AMagnetHat Hat : Hats)
		{
			if (Hat.TargetPlayer == nullptr)
				continue;

			if (Hat.TargetPlayer != Player)
				continue;

			Hat.MagnetHatMovementState = EMagnetHatMovementState::Default;
		}
	}
}
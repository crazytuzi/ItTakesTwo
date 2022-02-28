
class UGlobalHUDOverlayWidget : UHazeUserWidget
{
	bool bStartedSaving = false;
	float LastSaveGameTime = 0.f;

	bool bHasGameStartedProper = false;
	float GameStartedTimer = 0.f;

	UPROPERTY()
	UIdentityEngagementWidget Engagement_Menu;
	UPROPERTY()
	UIdentityEngagementWidget Engagement_May;
	UPROPERTY()
	UIdentityEngagementWidget Engagement_Cody;

	UPROPERTY()
	UWidget MemoryWarningWidget;

	UFUNCTION(BlueprintEvent)
	void BP_OnStartedSaving() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnFinishedSaving() {}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float Timer)
	{
		auto Lobby = Lobby::GetLobby();

		/** Update the save indicator **/
		if (!bHasGameStartedProper)
		{
			if (!Game::IsInLoadingScreen() && Lobby != nullptr && Lobby.HasGameStarted())
			{
				GameStartedTimer += Timer;
				if (GameStartedTimer > 4.f)
					bHasGameStartedProper = true;
			}
		}
		else
		{
			if (Lobby == nullptr || !Lobby.HasGameStarted())
			{
				bHasGameStartedProper = false;
				GameStartedTimer = 0.f;
			}
		}

		if (!bStartedSaving)
		{
			// Start saving when we've recently saved at a progress point
			if (Save::HasRecentlySaved() && bHasGameStartedProper)
			{
				if (Time::RealTimeSeconds > LastSaveGameTime)
				{
					bStartedSaving = true;
					BP_OnStartedSaving();
					LastSaveGameTime = Time::RealTimeSeconds;
				}
			}
		}
		else
		{
			// Finish the save once no profiles are dirty anymore
			if (!IsAnyProfileDirty() && Time::RealTimeSeconds > LastSaveGameTime + 1.0)
			{
				bStartedSaving = false;
				BP_OnFinishedSaving();
				LastSaveGameTime = Time::RealTimeSeconds + 4.0;
			}
		}

		/** Update identity engagement UI **/
		if (Lobby == nullptr || !Lobby.HasGameStarted())
		{
			if (Online::PrimaryIdentity != nullptr && Online::PrimaryIdentity.Engagement != EHazeIdentityEngagement::Engaged)
			{
				Engagement_Menu.Identity = Online::PrimaryIdentity;
				Engagement_Menu.SetVisibility(ESlateVisibility::HitTestInvisible);
			}
			else
			{
				Engagement_Menu.SetVisibility(ESlateVisibility::Collapsed);
			}

			Engagement_May.SetVisibility(ESlateVisibility::Collapsed);
			Engagement_Cody.SetVisibility(ESlateVisibility::Collapsed);
		}
		else
		{
			for (auto CheckPlayer : Game::Players)
			{
				auto Identity = Lobby::GetIdentityForPlayer(CheckPlayer);
				UIdentityEngagementWidget Widget = CheckPlayer.IsCody() ? Engagement_Cody : Engagement_May;
				if (Identity != nullptr && Identity.Engagement != EHazeIdentityEngagement::Engaged)
				{
					Widget.Identity = Identity;
					Widget.SetVisibility(ESlateVisibility::HitTestInvisible);
				}
				else
				{
					Widget.SetVisibility(ESlateVisibility::Collapsed);
				}
			}

			Engagement_Menu.SetVisibility(ESlateVisibility::Collapsed);
		}

#if TEST
		if (MemoryWarningWidget != nullptr)
		{
			MemoryWarningWidget.SetVisibility(
				Debug::ShouldWarnMemoryBudget() && !Debug::IsUXTestBuild()
					? ESlateVisibility::HitTestInvisible
					: ESlateVisibility::Collapsed
			);
		}
#endif
	}

	bool IsAnyProfileDirty()
	{
		for (auto Profile : Lobby::GetIdentitiesInGame())
		{
			if (!Profile.IsLocal())
				continue;
			if (Profile::IsProfileDirty(Profile))
				return true;
		}
		return false;
	}
};

class UIdentityEngagementWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	UHazePlayerIdentity Identity;
};
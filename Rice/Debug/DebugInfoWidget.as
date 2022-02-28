
class UDebugInfoWidget : UHazeUserWidget
{
	FString PrevProgressText;
	FName PrevProgressPoint;

	bool bShown = true;
	TPerPlayer<bool> ShowDebug;

	FString DataCL;
	float UpdateTimer = 0.f;

	FString AppId;

	UFUNCTION(BlueprintEvent)
	UWidget GetRootPanel() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetTextWidget() property
	{
		return nullptr;
	}

	UFUNCTION(BlueprintEvent)
	UTextBlock GetPlayerText(AHazePlayerCharacter ForPlayer)
	{
		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		AppId = Game::GetUniqueAppId();
		UpdateText();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geometry, float DeltaTime)
	{
		UpdateTimer -= DeltaTime;
		if (UpdateTimer <= 0.f)
		{
			UpdateTimer = 3.f;
			UpdateText();
		}

		for (auto CheckPlayer : Game::Players)
		{
			if (CheckPlayer.GetDebugFlag(n"PrintDebugLocation"))
			{
				if (!ShowDebug[CheckPlayer])
				{
					GetPlayerText(CheckPlayer).SetVisibility(ESlateVisibility::HitTestInvisible);
					ShowDebug[CheckPlayer] = true;
				}
				UpdatePlayerDebug(CheckPlayer);
			}
			else if (ShowDebug[CheckPlayer])
			{
				GetPlayerText(CheckPlayer).SetVisibility(ESlateVisibility::Collapsed);
				ShowDebug[CheckPlayer] = false;
			}
		}

		bool bShouldShow = Debug::AreOnScreenMessagesEnabled() || Debug::IsUXTestBuild();
		if (bShown != bShouldShow)
		{
			bShown = !bShown;
			if (bShown)
				RootPanel.SetVisibility(ESlateVisibility::HitTestInvisible);
			else
				RootPanel.SetVisibility(ESlateVisibility::Collapsed);
		}
	}

	void UpdateText()
	{
		FString Text;
		if (Debug::IsUXTestBuild())
			Text += "UX TEST\n";

		if (Network::IsNetworked())
		{
			Text += "Ping: ";
			Text += int(Debug::GetConnectionRoundTripPingSeconds() * 1000.f);
			float Loss = Debug::GetConnectionPacketLoss();
			if (Loss > 0.001f)
			{
				Text += "ms | Loss: ";
				Text += String::Conv_FloatToStringOneDecimal(Loss * 100.f);
				Text +="%\n";
			}
			else
			{
				Text += "ms\n";
			}

			int SimulatedLag = Console::GetConsoleVariableInt("Haze.ConnectionLagSettings");
			if (SimulatedLag == 1)
				Text += "Simulate: ADDED LAG\n";
			else if (SimulatedLag == 2)
				Text += "Simulate: BAD CONNECTION\n";
		}

		Text += Progress::DebugGetActiveProgressPoint();
		Text += "\n";

		if (!AppId.IsEmpty())
		{
			Text += AppId;
			Text += "\n";
		}

		FHazeBuildInfo BuildInfo  = Game::GetHazeBuildVersionStatics();
		if (BuildInfo.Build == "0")
		{
			Text += "Local Build";
		}
		else
		{
			if (DataCL.IsEmpty()) {
				FHazeBuildInfo BuildFileInfo = Game::ReadHazeBuildInfoFile();
				DataCL = BuildFileInfo.DataCL;
			}

			Text += Game::GetPlatformName() + " build " + BuildInfo.Build + " on Code " + BuildInfo.CodeHash;
			if (DataCL != "0") {
				Text += " Data " + DataCL;
			}
		}

		TextWidget.SetText(FText::FromString(Text));
	}

	void UpdatePlayerDebug(AHazePlayerCharacter DebugPlayer)
	{
		UTextBlock Widget = GetPlayerText(DebugPlayer);
		FVector Location = DebugPlayer.ActorLocation;

		FString PosStr;
		PosStr.Reserve(32);
		PosStr += int(Location.X);
		PosStr += ",";
		PosStr += int(Location.Y);
		PosStr += ",";
		PosStr += int(Location.Z);

		Widget.SetText(FText::FromString(PosStr));
	}
};
import Peanuts.Foghorn.FoghornVoiceLineHelpers;
import Peanuts.Foghorn.FoghornDebugStatics;

EHazeSubtitlePriority LaneToSubtitlePriority(EFoghornLaneName Lane)
{
	switch (Lane)
	{
		case EFoghornLaneName::First:
			return EHazeSubtitlePriority::High;
		
		case EFoghornLaneName::Second:
			return EHazeSubtitlePriority::Medium;
		
		case EFoghornLaneName::Third:
			return EHazeSubtitlePriority::Low;
	}

	return EHazeSubtitlePriority::Medium;
}

class UFoghornSubtitles
{
	const FName MaySouceTag = n"MayBark";
	const FName CodySouceTag = n"CodyBark";
	const FName OtherSouceTag = n"NPCBark";

	private TArray<AHazePlayerCharacter> SubtitlePlayers;
	private EHazeSubtitlePriority SubtitlePriority = EHazeSubtitlePriority::Medium;
	private UHazeSubtitleAsset CurrentSubtitleAsset = nullptr;

	UFoghornSubtitles(EFoghornLaneName Lane)
	{
		SubtitlePriority = LaneToSubtitlePriority(Lane);
	}

	private FName FindSourceTag(AActor SpeakingActor)
	{
		if (SpeakingActor.IsA(AHazePlayerCharacter::StaticClass()))
		{
			auto Player = Cast<AHazePlayerCharacter>(SpeakingActor);
			if (Player.IsMay())
			{
				return MaySouceTag;
			}
			else if (Player.IsCody())
			{
				return CodySouceTag;
			}
		}

		return OtherSouceTag;
	}

	private void SetupPlayers()
	{
		SubtitlePlayers.Append(Game::GetPlayers());
	}

	void DisplayTextSubtitle(FText SubtitleText, AActor SpeakingActor)
	{
		ClearSubtitles();

		FHazeSubtitleLine SubtitleLine;
		SubtitleLine.Text = SubtitleText;
		SubtitleLine.SourceTag = FindSourceTag(SpeakingActor);

		SetupPlayers();
		for (auto Player : SubtitlePlayers)
		{
			Subtitle::ShowSubtitle(Player, SubtitleLine, 0.0f, this, SubtitlePriority);
		}
	}

	void DisplayAssetSubtitle(UHazeSubtitleAsset SubtitleAsset, AActor SpeakingActor)
	{
		ClearSubtitles();

		SetupPlayers();
		CurrentSubtitleAsset = SubtitleAsset;
	}

	void ClearSubtitles()
	{
		for (AHazePlayerCharacter Player : SubtitlePlayers)
		{
			if (IsActorValid(Player))
				Subtitle::ClearSubtitlesByInstigator(Player, this);
		}
		SubtitlePlayers.Reset();
		CurrentSubtitleAsset = nullptr;
	}

	void Tick(float TimeInAsset)
	{
		if (CurrentSubtitleAsset != nullptr)
		{
			for (auto Player : SubtitlePlayers)
			{
				Subtitle::ShowSubtitlesFromAsset(Player, CurrentSubtitleAsset, TimeInAsset, this, SubtitlePriority);
			}
		}
	}

};
import Cake.LevelSpecific.Music.NightClub.RythmBoardComponent;

namespace RhythmStatics
{
	UFUNCTION(BlueprintCallable, Category = Rhythm)
	void PushRhytmIcon(EHazePlayer PlayerType, ERhythmButtonType ButtonType)
	{
		AHazePlayerCharacter Player = Game::GetPlayer(PlayerType);

		if(Player == nullptr)
		{
			return;
		}

		URythmBoardComponent RythmBoardComponent = URythmBoardComponent::Get(Player);

		if(RythmBoardComponent == nullptr)
		{
			return;
		}

		RythmBoardComponent.PushIcon(ButtonType);
	}
}

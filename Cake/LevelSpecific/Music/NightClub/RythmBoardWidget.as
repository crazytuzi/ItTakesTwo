import Cake.LevelSpecific.Music.NightClub.RythmLineWidget;
import Cake.LevelSpecific.Music.NightClub.RythmButtonType;

class URythmBoardWidget : UHazeUserWidget
{
	UPROPERTY()
	TArray<URythmLineWidget> ActiveRythmLines;

	bool ButtonPressed(ERhythmButtonType ButtonType)
	{
		for(URythmLineWidget CurrentLine : ActiveRythmLines)
		{
			if(CurrentLine.ButtonType == ButtonType)
			{
				return CurrentLine.ButtonPressed();
			}
		}

		return false;
	}

	void PushRythmIcon(ERhythmButtonType ButtonType)
	{
		for(URythmLineWidget CurrentLine : ActiveRythmLines)
		{
			if(CurrentLine.ButtonType == ButtonType)
			{
				CurrentLine.PushRytmIcon();
			}
		}
	}
}

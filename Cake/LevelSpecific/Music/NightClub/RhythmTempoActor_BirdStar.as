import Cake.LevelSpecific.Music.NightClub.RhythmTempoActor;

class ARhythmTempoActor_BirdStar : ARhythmTempoActor
{
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UWidgetComponent WidgetComp;
	default WidgetComp.WidgetClass = Asset("/Game/GUI/InputIcon/WBP_InputButton.WBP_InputButton_C");

	void RefreshWidget(AHazePlayerCharacter InPlayer) override
	{
		if(InPlayer != Player)
		{
			UHazeInputButton InputButton = Cast<UHazeInputButton>(WidgetComp.GetUserWidgetObject());
			InputButton.ActionName = ActionName;
			InputButton.OverrideWidgetPlayer(InPlayer);
			Player = InPlayer;
		}
	}

	protected void CreateWidget(AHazePlayerCharacter InPlayer) override
	{

	}

	protected void RemoveWidget(AHazePlayerCharacter InPlayer) override
	{

	}
}

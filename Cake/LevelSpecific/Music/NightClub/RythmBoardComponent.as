import Cake.LevelSpecific.Music.NightClub.RythmBoardWidget;

class URythmBoardComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<URythmBoardWidget> RythmBoardClass;

	URythmBoardWidget RythmBoardWidget;

	AHazePlayerCharacter PlayerCharacter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerCharacter = Cast<AHazePlayerCharacter>(Owner);
		AddRythmBoardToUI();
	}

	void AddRythmBoardToUI()
	{
		RythmBoardWidget = Cast<URythmBoardWidget>(PlayerCharacter.AddWidget(RythmBoardClass));
	}

	void RemoveRythmBoardFromUI()
	{
		if(RythmBoardWidget != nullptr)
		{
			PlayerCharacter.RemoveWidget(RythmBoardWidget);
		}
	}

	void PushIcon(ERhythmButtonType ButtonType)
	{
		if(RythmBoardWidget != nullptr)
		{
			RythmBoardWidget.PushRythmIcon(ButtonType);
		}
	}
}

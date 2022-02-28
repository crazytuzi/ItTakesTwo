import Peanuts.Triggers.PlayerTrigger;
import Vino.Interactions.InteractionComponent;

class UCastleAbilityTutorialWidget : UHazeUserWidget
{
	UPROPERTY()
	FName ActionName;
	UPROPERTY()
	FText PromptText;
	UPROPERTY()
	EHazePlayer PlayerColor;

	UFUNCTION(BlueprintEvent)
	void Update() {}
};

class ACastleAbilityTutorialVolume : APlayerTrigger
{
	UPROPERTY(Category = "Castle Ability Tutorial")
	FName ActionName;
	UPROPERTY(Category = "Castle Ability Tutorial")
	FText PromptText;
	UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Castle Ability Tutorial")	
	EHazePlayer PlayerColor = EHazePlayer::May;
	UPROPERTY(Category = "Castle Ability Tutorial")
	TSubclassOf<UCastleAbilityTutorialWidget> WidgetType;

	private TPerPlayer<UCastleAbilityTutorialWidget> Widgets;

	UPROPERTY()
	AHazeActor TutorialLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPlayerEnter.AddUFunction(this, n"AddTutorial");
		OnPlayerLeave.AddUFunction(this, n"RemoveTutorial");
		Super::BeginPlay();
	}

	UFUNCTION()
	private void AddTutorial(AHazePlayerCharacter Player)
	{
		auto Widget = Cast<UCastleAbilityTutorialWidget>(Player.AddWidget(WidgetType));
		Widget.ActionName = ActionName;
		Widget.PromptText = PromptText;
		Widget.PlayerColor = PlayerColor;
		Widget.Update();
		Widget.AttachWidgetToComponent(TutorialLocation.RootComponent);
		//Widget.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, 0.f));
		Widget.SetWidgetShowInFullscreen(true);
		Widgets[Player] = Widget;
	}

	UFUNCTION()
	private void RemoveTutorial(AHazePlayerCharacter Player)
	{
		if (Widgets[Player] != nullptr)
		{
			Player.RemoveWidget(Widgets[Player]);
			Widgets[Player] = nullptr;
		}
	}
};

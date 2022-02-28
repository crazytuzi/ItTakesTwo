import Vino.MinigameScore.MinigameComp;

//Example script for using MinigameComp functions
class MinigameExamples : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComp;

	///*** CREATING IN-GAME WIDGETS ON SCREEN ***///
	// An example of how this could be setup - with player who scored and an actor or world location where you want the widget to appear + the score
	void CreatingScoreWidgetExample(AHazePlayerCharacter Player, FVector HitTargetLocation, int Score)
	{
		// These are the settings for how the widget will behave I.E. movement type, speed, duration
		FMinigameWorldWidgetSettings MinigameWorldSettings;
		
		MinigameWorldSettings.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
		MinigameWorldSettings.TextJuice = EInGameTextJuice::BigChange; //Animation 'juice' that will be added later
		MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::Cody; // Set color to May or Cody... or some other setting
		MinigameWorldSettings.MoveSpeed = 30.f; // Starting move speed
		MinigameWorldSettings.TimeDuration = 0.5f; // How long it should last for before it fades out or completely disappears
		MinigameWorldSettings.FadeDuration = 0.6f; // Opacity fade time
		MinigameWorldSettings.TargetHeight = 140.f; // If movement type is 'ToHeight', the height it will reach before stopping
		
		// For numbers only
		MinigameComp.CreateMinigameWorldWidgetNumber(EMinigameTextPlayerTarget::May, Score, HitTargetLocation, MinigameWorldSettings);

		// If you want to combine text and numbers, or just have text - Converting though is a little expensive
		MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Cody, "+ " + String::Conv_IntToString(Score), HitTargetLocation, MinigameWorldSettings);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Bind function to events
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"InitiateGame"); // When both players have readied up during tutorial
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"GameCancelledExample"); // When either player has pressed cancel instead 
		// This will automatically remove the tutorial window and make the highscore boxes visible
		MinigameComp.OnTutorialCancelFromPlayer.AddUFunction(this, n"PlayerCancelledExample"); // Gives reference to the specific player who cancelled
	}

	///*** SETTING UP TUTORIAL SCREEN ***///
	// You could have a function like this that gets called once players are 'ready' to play
	UFUNCTION()
	void TutorialScreenSetupExample()
	{
		// Activates the tutorial screen until players choose to ready up, which then broadcasts OnMinigameTutorialComplete
		// If a player cancelled, both OnMinigameTutorialCancelled and OnMinigameTutorialPlayerCancelled will broadcast
		MinigameComp.ActivateTutorial();

		//IMPORTANT NOTE!!! 
		//Tutorial instructions are set on the MinigameComp near the top of the 'Mini Game Setup' section in Details. Write what instructions you want there
	}

	UFUNCTION()
	void GameCancelledExample()
	{
		//Remove/undo added capabilities or conditions you may have set before this point
	}

	UFUNCTION()
	void PlayerCancelledExample(AHazePlayerCharacter Player)
	{
		//Remove/undo added capabilities or conditions you may have set before this point
		//Take reference for player who cancelled
	}

	UFUNCTION()
	void SpecificPlayerCancelledExample(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION()
	void InitiateGameExample()
	{
		//Do minigame start game stuff here...
		MinigameComp.StartCountDown();
		//Blah blah blah...
	}
}
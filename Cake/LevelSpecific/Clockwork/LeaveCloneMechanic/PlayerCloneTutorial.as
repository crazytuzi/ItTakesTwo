import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.PlayerTimeSequenceComponent;

class APlayerCloneTutorial : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent LeaveCloneTutorial;
	default LeaveCloneTutorial.SetCollisionProfileName(n"TriggerPlayerOnly");

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent TeleportTutorial;
	default TeleportTutorial.SetCollisionProfileName(n"TriggerPlayerOnly");

	UPROPERTY(Category = "Tutorial")
	FText LeaveCloneTutorialText;

	UPROPERTY(Category = "Tutorial")
	FText TeleportTutorialText;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	private bool bCompletedCloneTutorial = false;
	private bool bCompletedTeleportTutorial = false;
	private bool bShowingTeleportPrompt = false;
	private bool bHasCloneInArea = false;

	private bool bInsideLeaveCloneArea = false;
	private bool bInsideTeleportArea = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        LeaveCloneTutorial.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapLeaveClone");
        LeaveCloneTutorial.OnComponentEndOverlap.AddUFunction(this, n"EndOverlapLeaveClone");

        TeleportTutorial.OnComponentBeginOverlap.AddUFunction(this, n"BeginOverlapTeleportArea");
        TeleportTutorial.OnComponentEndOverlap.AddUFunction(this, n"EndOverlapTeleportArea");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		bHasCloneInArea = false;
		auto SequenceComp = UTimeControlSequenceComponent::Get(Game::May);
		if (SequenceComp != nullptr)
		{
			if (SequenceComp.IsCloneActive())
			{
				if (FMath::IsPointInBox(
					SequenceComp.Clone.ActorLocation,
					LeaveCloneTutorial.WorldLocation,
					LeaveCloneTutorial.GetScaledBoxExtent()))
				{
					bHasCloneInArea = true;
				}
			}
		}

		// Check for finishing the leave clone tutorial
		if (!bCompletedCloneTutorial && bHasCloneInArea)
		{
			bCompletedCloneTutorial = true;
			RemoveTutorialPromptByInstigator(Game::May, LeaveCloneTutorial);
		}

		if (!bCompletedTeleportTutorial && bInsideTeleportArea)
		{
			// Check for starting the teleport tutorial
			if (bHasCloneInArea && !bShowingTeleportPrompt)
			{
				FTutorialPrompt Prompt;
				Prompt.DisplayType = ETutorialPromptDisplay::Action;
				Prompt.Action = ActionNames::PrimaryLevelAbility;
				Prompt.Text = TeleportTutorialText;
				ShowTutorialPrompt(Game::May, Prompt, TeleportTutorial);

				bShowingTeleportPrompt = true;
			}

			// Check for finishing the teleport tutorial
			if (!bHasCloneInArea && bShowingTeleportPrompt)
			{
				RemoveTutorialPromptByInstigator(Game::May, TeleportTutorial);
				bShowingTeleportPrompt = false;
				bCompletedTeleportTutorial = true;
			}
		}

		if (!bInsideLeaveCloneArea && !bInsideTeleportArea && !bShowingTeleportPrompt)
			SetActorTickEnabled(false);
	}

    UFUNCTION()
    void BeginOverlapLeaveClone(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		if (OtherActor != Game::May)
			return;

		if (bCompletedCloneTutorial)
			return;

		FTutorialPrompt Prompt;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Action = ActionNames::SecondaryLevelAbility;
		Prompt.Text = LeaveCloneTutorialText;
		ShowTutorialPrompt(Game::May, Prompt, LeaveCloneTutorial);

		bInsideLeaveCloneArea = true;
		SetActorTickEnabled(true);
    }

    UFUNCTION()
    void EndOverlapLeaveClone(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (OtherActor != Game::May)
			return;

		RemoveTutorialPromptByInstigator(Game::May, LeaveCloneTutorial);

		bInsideLeaveCloneArea = false;
    }

    UFUNCTION()
    void BeginOverlapTeleportArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		if (OtherActor != Game::May)
			return;

		if (bCompletedTeleportTutorial)
			return;

		bInsideTeleportArea = true;
		SetActorTickEnabled(true);
    }

    UFUNCTION()
    void EndOverlapTeleportArea(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (OtherActor != Game::May)
			return;

		RemoveTutorialPromptByInstigator(Game::May, TeleportTutorial);

		bInsideTeleportArea = false;
		bShowingTeleportPrompt = false;
    }

};
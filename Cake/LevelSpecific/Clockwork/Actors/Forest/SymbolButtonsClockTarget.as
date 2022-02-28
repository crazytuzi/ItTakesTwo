import Vino.Triggers.PlayerLookAtTriggerComponent;
class ASymbolButtonsClockTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UPlayerLookAtTriggerComponent LookAtComp;
	default LookAtComp.Players = EHazeSelectPlayer::May;
	default LookAtComp.LookDuration = 0.f;
	default LookAtComp.ViewCenterFraction = 1.25f;
	default LookAtComp.Range = 8000.f;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	bool bLookedAt = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LookAtComp.OnBeginLookAt.AddUFunction(this, n"BeginLookAt");
		LookAtComp.OnEndLookAt.AddUFunction(this, n"EndLookAt");
	}

	UFUNCTION(NotBlueprintCallable)
	void BeginLookAt(AHazePlayerCharacter Player)
	{
		bLookedAt = true;
		// Print("LOOK AT" + Name);
	}

	UFUNCTION(NotBlueprintCallable)
	void EndLookAt(AHazePlayerCharacter Player)
	{
		bLookedAt = false;
	}
}
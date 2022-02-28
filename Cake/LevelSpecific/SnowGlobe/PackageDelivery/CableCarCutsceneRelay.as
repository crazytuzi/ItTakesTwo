event void FCutsceneRelayDoneEventSignature(AHazePlayerCharacter Player);
UCLASS(Abstract)
class ACableCarCutsceneRelay : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UMaterialBillboardComponent Root;

	UPROPERTY()
	FCutsceneRelayDoneEventSignature OnCutsceneDone;

	UPROPERTY()
	FCutsceneRelayDoneEventSignature OnShouldStartCutscene;

	UFUNCTION()
	void StartCutscene(AHazePlayerCharacter StartingPlayer)
	{
		OnShouldStartCutscene.Broadcast(StartingPlayer);
	}

	UFUNCTION()
	void CutsceneDone(AHazePlayerCharacter StartingPlayer)
	{
		OnCutsceneDone.Broadcast(StartingPlayer);
	}
}
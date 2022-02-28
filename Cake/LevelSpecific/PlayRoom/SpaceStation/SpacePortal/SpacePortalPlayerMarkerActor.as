import Vino.PlayerMarker.PlayerMarkerWidget;

class ASpacePortalPlayerMarkerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(NotVisible)
	AHazePlayerCharacter Player;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerMarkerWidget> WidgetClass;
	UPlayerMarkerWidget PlayerMarker;

	bool bMarkerVisible = false;

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (PlayerMarker != nullptr)
			Player.RemoveWidget(PlayerMarker);
	}

	UFUNCTION()
	void ShowMarker(FVector Location)
	{
		if (bMarkerVisible)
			return;

		TeleportActor(Location, FRotator::ZeroRotator);

		bMarkerVisible = true;

		PlayerMarker = Cast<UPlayerMarkerWidget>(Player.AddWidget(WidgetClass));
		PlayerMarker.bForceShow = true;
		PlayerMarker.AttachWidgetToActor(this);
		PlayerMarker.Setup(Player);
	}

	UFUNCTION()
	void HideMarker()
	{
		if (!bMarkerVisible)
			return;

		bMarkerVisible = false;

		Player.RemoveWidget(PlayerMarker);
	}
}
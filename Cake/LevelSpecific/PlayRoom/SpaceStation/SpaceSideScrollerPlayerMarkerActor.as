import Vino.PlayerMarker.PlayerMarkerWidget;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

class ASpaceSideScrollerPlayerMarkerActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent CallbackComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerMarkerWidget> WidgetClass;
	UPlayerMarkerWidget PlayerMarker;

	bool bSideScrollerActive = false;

	AHazePlayerCharacter Player;

	bool bMarkerVisible = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Game::GetCody();

		CallbackComp.OnCharacterChangedSize.AddUFunction(this, n"ChangedSize");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (PlayerMarker != nullptr)
			HideMarker();
	}

	UFUNCTION()
	void SetSideScrollerStatus(bool bActive)
	{
		bSideScrollerActive = bActive;
		if (!bSideScrollerActive)
			HideMarker();
	}

	UFUNCTION(NotBlueprintCallable)
	void ChangedSize(FChangeSizeEventTempFix NewSize)
	{
		if (NewSize.NewSize == ECharacterSize::Small)
			ShowMarker();
		else
			HideMarker();
	}

	UFUNCTION()
	void ShowMarker()
	{
		if (!bSideScrollerActive)
			return;

		if (bMarkerVisible)
			return;

		bMarkerVisible = true;

		PlayerMarker = Cast<UPlayerMarkerWidget>(Player.AddWidget(WidgetClass));
		PlayerMarker.bForceShow = true;
		PlayerMarker.AttachWidgetToActor(Player);
		PlayerMarker.SetWidgetRelativeAttachOffset(FVector(0.f, 0.f, 25.f));
		PlayerMarker.Setup(Player.OtherPlayer);
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
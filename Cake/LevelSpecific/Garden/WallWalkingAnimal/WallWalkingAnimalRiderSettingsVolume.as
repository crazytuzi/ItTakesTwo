import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalRiderSettings;


settings WallWalkingRiderWallToFloorSettings for UWallWalkingAnimalRiderSettings
{
	WallWalkingRiderWallToFloorSettings.WallCameraSlerpSpeed = 1.f;
}

class AWallWalkingAnimalRiderSettingsVolume : APlayerTrigger
{
	UPROPERTY()
	UWallWalkingAnimalRiderSettings Settings = WallWalkingRiderWallToFloorSettings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPlayerEnter.AddUFunction(this, n"PlayerEnter");
		OnPlayerLeave.AddUFunction(this, n"PlayerLeave");

		Super::BeginPlay();
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerEnter(AHazePlayerCharacter Player)
	{
		Player.ApplySettings(Settings, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerLeave(AHazePlayerCharacter Player)
	{
		Player.ClearSettingsByInstigator(this);
	}
}

import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingSettings;

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking", ComponentWrapperClass)
class AForceCharacterSlidingVolume : AVolume
{
    UPROPERTY(BlueprintReadOnly)
    bool bVolumeEnabled = true;

	UPROPERTY(BlueprintReadOnly)
	ESlidingVolumeMode SlidingVolumeMode;

    TPerPlayer<bool> IsPlayerInside;
	TPerPlayer<bool> bDisabledForPlayer;

	// Sliding Settings
	UPROPERTY(meta = (ShowOnlyInnerProperties))
	FSlidingSpeedSettings SlidingSpeedSettings;
	UPROPERTY(meta = (ShowOnlyInnerProperties))
	FSlidingTurningSettings SlidingTurningSettings;

    default Shape::SetVolumeBrushColor(this, FLinearColor::Green);

    UFUNCTION(Category = "Sliding Volume")
    void EnableSlidingVolume()
    {
        if (bVolumeEnabled)
            return;

        bVolumeEnabled = true;
        UpdateAlreadyInsidePlayers();
    }

    UFUNCTION(Category = "Sliding Volume")
    void DisableSlidingVolume()
    {
        if (!bVolumeEnabled)
            return;

        bVolumeEnabled = false;
        UpdateAlreadyInsidePlayers();
    }

	UFUNCTION(Category = "Sliding Volume")
	void EnableForPlayer(AHazePlayerCharacter Player)
	{
		if (!bDisabledForPlayer[Player])
			return;

		bDisabledForPlayer[Player] = false;
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Sliding Volume")
	void DisableForPlayer(AHazePlayerCharacter Player)
	{
		if (bDisabledForPlayer[Player])
			return;

		bDisabledForPlayer[Player] = true;
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Sliding Volume")
	bool IsEnabledForPlayer(AHazePlayerCharacter Player)
	{
		if (!bVolumeEnabled)
			return false;
		if (bDisabledForPlayer[Player])
			return false;
		return true;
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UpdateAlreadyInsidePlayers();
    }

    void UpdateAlreadyInsidePlayers()
    {
        TArray<AActor> ActorsInside;
        GetOverlappingActors(ActorsInside);

		// Trigger all current overlaps again to detect if we were enabled
        for (AActor OverlapActor : ActorsInside)
			ActorBeginOverlap(OverlapActor);		
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (!IsEnabledForPlayer(Player))
            return;

        // Don't double trigger volume enters
        if (IsPlayerInside[Player])
            return;
        IsPlayerInside[Player] = true;

		UCharacterSlidingComponent SlidingComp = UCharacterSlidingComponent::Get(Player);
		if (SlidingComp == nullptr)
			return;

		if (SlidingVolumeMode == ESlidingVolumeMode::StartSliding)
			SlidingComp.EnteredSlidingVolume();
		else
			SlidingComp.LeftSlidingVolume();

		USlidingSettings TempSlideSettings = Cast<USlidingSettings>(NewObject(this, USlidingSettings::StaticClass()));
		TempSlideSettings.SpeedSettings = SlidingSpeedSettings;
		TempSlideSettings.TurningSettings = SlidingTurningSettings;
		Player.ApplySettings(TempSlideSettings, this);
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;

        // Can't leave the volume if we were never in it
        if (!IsPlayerInside[Player])
            return;
        IsPlayerInside[Player] = false;

		UCharacterSlidingComponent SlidingComp = UCharacterSlidingComponent::Get(Player);
		if (SlidingComp == nullptr)
			return;

		if (SlidingVolumeMode == ESlidingVolumeMode::StartSliding)
			SlidingComp.LeftSlidingVolume();
		else
			SlidingComp.EnteredSlidingVolume();

		Player.ClearSettingsByInstigator(this);
    }
}

enum ESlidingVolumeMode
{
	StartSliding,
	StopSliding
}
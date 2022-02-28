import Vino.Movement.Capabilities.Sprint.CharacterSprintComponent;
import Vino.Movement.Capabilities.Sprint.CharacterSprintSettings;
UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking", ComponentWrapperClass)
class ACharacterSprintVolume : AVolume
{
    UPROPERTY(BlueprintReadOnly)
    bool bVolumeEnabled = true;

    TPerPlayer<bool> IsPlayerInside;
	TPerPlayer<bool> bDisabledForPlayer;

    default Shape::SetVolumeBrushColor(this, FLinearColor::Green);

	USprintSettings SprintSettings;

	UPROPERTY(Category = "Sprint Settings")
	bool bForceSprint = false;
	
	UPROPERTY(Category = "Sprint Settings")
	USprintSettings OverrideSprintSettings;	

    UFUNCTION(Category = "Sprint Volume")
    void EnableSprintVolume()
    {
        if (bVolumeEnabled)
            return;

        bVolumeEnabled = true;
        UpdateAlreadyInsidePlayers();
    }

    UFUNCTION(Category = "Sprint Volume")
    void DisableSprintVolume()
    {
        if (!bVolumeEnabled)
            return;

        bVolumeEnabled = false;
        UpdateAlreadyInsidePlayers();
    }

	UFUNCTION(Category = "Sprint Volume")
	void EnableForPlayer(AHazePlayerCharacter Player)
	{
		if (!bDisabledForPlayer[Player])
			return;

		bDisabledForPlayer[Player] = false;
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Sprint Volume")
	void DisableForPlayer(AHazePlayerCharacter Player)
	{
		if (bDisabledForPlayer[Player])
			return;

		bDisabledForPlayer[Player] = true;
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Sprint Volume")
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

		if (OverrideSprintSettings != nullptr)
			Player.ApplySettings(OverrideSprintSettings, this);

		if (bForceSprint)
		{
			UCharacterSprintComponent SprintComp = UCharacterSprintComponent::GetOrCreate(Player);
			SprintComp.ForceSprint(this);
		}
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

		if (OverrideSprintSettings != nullptr)
			Player.ClearSettingsByInstigator(this);

		if (bForceSprint)
		{
			UCharacterSprintComponent SprintComp = UCharacterSprintComponent::GetOrCreate(Player);
			SprintComp.ClearForceSprint(this);
		}
    }
}
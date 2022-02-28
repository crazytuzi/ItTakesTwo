import Vino.Checkpoints.Checkpoint;
import vino.Checkpoints.Statics.CheckpointStatics;

UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking", ComponentWrapperClass)
class ACheckpointVolume : AVolume
{
	UPROPERTY(DefaultComponent)
	UCheckpointVolumeVisualizerComponent VisualizerComp;

	default BrushComponent.SetCollisionProfileName(n"TriggerOnlyPlayer_Static");

    /* These checkpoints will be enabled while the player is in the indicated volume. */
    UPROPERTY(BlueprintReadOnly, Category = "Checkpoints")
    TArray<ACheckpoint> EnabledCheckpoints;

    /* Sticky checkpoint volumes will stay active until the player enters a different sticky checkpoint volume. */
    UPROPERTY(BlueprintReadOnly, Category = "Checkpoints")
    bool bSticky = true;

    /* Whether the checkpoint volume is enabled or not. The EnableCheckpointVolume
     * and DisableCheckpointVolume functions should be used to change this. */
    UPROPERTY(BlueprintReadOnly, Category = "Checkpoints")
    bool bVolumeEnabled = true;

	/**
	 * If set, either player being inside the volume will enable
	 * the checkpoints for both players.
	 */
    UPROPERTY(BlueprintReadOnly, Category = "Checkpoints", AdvancedDisplay)
    bool bSharedByBothPlayers = false;

	/**
	 * If set, this shared sticky checkpoint volume can only be triggered once,
	 * and will no longer apply its checkpoints after the first player has triggered it.
	 */
    UPROPERTY(BlueprintReadOnly, Category = "Checkpoints", AdvancedDisplay, Meta = (EditCondition = "bSticky && bSharedByBothPlayers", EditConditionHides))
    bool bSingleTrigger = true;

	/* Whether the checkpoint volume should start enabled for may. */
    UPROPERTY(BlueprintReadOnly, Category = "Checkpoints", AdvancedDisplay)
    bool bEnabledForMay = true;

	/* Whether the checkpoint volume should start enabled for cody. */
    UPROPERTY(BlueprintReadOnly, Category = "Checkpoints", AdvancedDisplay)
    bool bEnabledForCody = true;

    TPerPlayer<bool> IsPlayerInside;
	TPerPlayer<bool> bDisabledForPlayer;
	bool bTriggerDisabled = false;

    default Shape::SetVolumeBrushColor(this, FLinearColor(0.f, 1.f, 0.8f, 1.f));

    UFUNCTION(Category = "Checkpoint Volume")
    void EnableCheckpointVolume()
    {
        if (bVolumeEnabled)
            return;

        bVolumeEnabled = true;
        UpdateAlreadyInsidePlayers();
    }

    UFUNCTION(Category = "Checkpoint Volume")
    void DisableCheckpointVolume()
    {
        if (!bVolumeEnabled)
            return;

        bVolumeEnabled = false;
        UpdateAlreadyInsidePlayers();
    }

	UFUNCTION(Category = "Checkpoint Volume")
	void EnableForPlayer(AHazePlayerCharacter Player)
	{
		if (!bDisabledForPlayer[Player])
			return;

		bDisabledForPlayer[Player] = false;
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Checkpoint Volume")
	void DisableForPlayer(AHazePlayerCharacter Player)
	{
		if (bDisabledForPlayer[Player])
			return;

		bDisabledForPlayer[Player] = true;
        UpdateAlreadyInsidePlayers();
	}

	UFUNCTION(Category = "Checkpoint Volume")
	bool IsEnabledForPlayer(AHazePlayerCharacter Player)
	{
		if (!bVolumeEnabled)
			return false;
		if (bDisabledForPlayer[Player])
			return false;
		return true;
	}

    private void EnableCheckpoints(AHazePlayerCharacter Player)
    {
        for (auto Checkpoint : EnabledCheckpoints)
		{
			if (Checkpoint != nullptr)
				Checkpoint.EnableForPlayer(Player);
		}
    }

    private void DisableCheckpoints(AHazePlayerCharacter Player)
    {
        for (auto Checkpoint : EnabledCheckpoints)
		{
			if (Checkpoint != nullptr)
				Checkpoint.DisableForPlayer(Player);
		}
    }

    void OnVolumeRemovedFromSticky(AHazePlayerCharacter Player)
    {
        DisableCheckpoints(Player);
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        UpdateAlreadyInsidePlayers();

		if (!bEnabledForCody)
			DisableForPlayer(Game::Cody);
		if (!bEnabledForMay)
			DisableForPlayer(Game::May);
    }

	void RemoveFromSticky(AHazePlayerCharacter Player)
	{
		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::GetOrCreate(Player);
		if (RespawnComp.StickyCheckpointVolume == this)
		{
			OnCheckpointVolumeRemovedFromSticky(Player, this);
			RespawnComp.StickyCheckpointVolume = nullptr;
			DisableCheckpoints(Player);
		}
	}

    void UpdateAlreadyInsidePlayers()
    {
        TArray<AActor> ActorsInside;
        GetOverlappingActors(ActorsInside);

		// Trigger all current overlaps again to detect if we were enabled
        for (AActor OverlapActor : ActorsInside)
			ActorBeginOverlap(OverlapActor);

		// Disable checkpoints for players that are inside but no longer enabled
        for (auto Player : Game::GetPlayers())
        {
			bool bEnabledForPlayer = IsEnabledForPlayer(Player);
            if (!bEnabledForPlayer)
            {
				if (IsPlayerInside[Player])
                	ActorEndOverlap(Player);
					
                if (bSticky)
					RemoveFromSticky(Player);
            }
        }
    }

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
        if (Player == nullptr)
            return;
        if (!IsEnabledForPlayer(Player))
            return;
        if (!CanPlayerActivateCheckpointVolumes(Player))
            return;

        // Don't double trigger volume enters
        if (IsPlayerInside[Player])
            return;
        IsPlayerInside[Player] = true;

		if (bTriggerDisabled)
			return;

		TriggerEnter(Player);
		if (bSharedByBothPlayers)
		{
			TriggerEnter(Player.OtherPlayer);

			// Disable triggering this volume if in sticky single-trigger mode
			if (bSticky && bSingleTrigger)
				bTriggerDisabled = true;
		}
    }

	void TriggerEnter(AHazePlayerCharacter Player)
	{
        if (bSticky)
        {
			UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::GetOrCreate(Player);
			if (RespawnComp.StickyCheckpointVolume != this)
			{
				ResetStickyCheckpointVolume(Player);
				RespawnComp.StickyCheckpointVolume = this;
			}
        }

        EnableCheckpoints(Player);
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

		if (bSharedByBothPlayers)
		{
			if (!IsPlayerInside[0] && !IsPlayerInside[1])
			{
				TriggerExit(Player);
				TriggerExit(Player.OtherPlayer);
			}
		}
		else
		{
			TriggerExit(Player);
		}
    }

	void TriggerExit(AHazePlayerCharacter Player)
	{
		if (!bSticky)
			DisableCheckpoints(Player);
	}
};

void UpdateCheckpointVolumes(AHazePlayerCharacter Player)
{
    TArray<AActor> Overlaps;
    Player.GetOverlappingActors(Overlaps, ACheckpointVolume::StaticClass());

    for(AActor OverlapActor : Overlaps)
    {
        ACheckpointVolume OverlapVolume = Cast<ACheckpointVolume>(OverlapActor);
        OverlapVolume.ActorBeginOverlap(Player);
    }
}

void OnCheckpointVolumeRemovedFromSticky(AHazePlayerCharacter Player, UObject Object)
{
    Cast<ACheckpointVolume>(Object).OnVolumeRemovedFromSticky(Player);
}

bool IsPlayerInsideCheckpointVolume(AHazePlayerCharacter Player)
{
	TArray<AActor> OverlapActors;
	Player.GetOverlappingActors(OverlapActors, ClassFilter = ACheckpointVolume::StaticClass());

	for (auto Actor : OverlapActors)
	{
		auto CheckpointVolume = Cast<ACheckpointVolume>(Actor);
		if (CheckpointVolume.IsPlayerInside[Player])
			return true;
	}

	return false;
}

// Dummy comp for the visualizer
class UCheckpointVolumeVisualizerComponent : UActorComponent {}
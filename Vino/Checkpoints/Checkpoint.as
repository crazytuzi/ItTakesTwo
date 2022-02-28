
import Vino.PlayerHealth.PlayerRespawnComponent;

#if EDITOR
import Editor.EditorVisualizers.VisualizePlayerPose;
#endif

event void FOnRespawnedAtCheckpoint(AHazePlayerCharacter RespawningPlayer);
delegate void FOnCheckpointEnabled(AHazePlayerCharacter EnablingPlayer);
delegate void FOnCheckpointDisabled(AHazePlayerCharacter DisablingPlayer);

enum ECheckpointPriority
{
    NoRespawn,
    Lowest,
    Low,
    Normal,
    High,
    Highest,
};

struct FCheckpointPlayerState
{
    /* Whether the checkpoint is currently enabled for this player. */
    UPROPERTY()
    bool bEnabled = false;
};

/*
    Checkpoints are used to respawn players in the world when dying.

    When a player dies, it checks all checkpoints that are enabled in the
    world, and respawns at the highest priority one. If multiple
    checkpoints have the highest priority, it chooses the closest one.
 */
UCLASS(HideCategories = "Rendering Input Actor LOD StoredPosition Cooking")
class ACheckpoint : AHazeActor
{
	default bRunConstructionScriptOnDrag = true;

    /* Priority of the checkpoint. The highest priority checkpoint will always be chosen. */
    UPROPERTY(Category = "Checkpoint")
    ECheckpointPriority RespawnPriority = ECheckpointPriority::Normal;

    /* Whether the checkpoint is valid for the cody player to use. */
    UPROPERTY(Category = "Checkpoint")
    bool bCanCodyUse = true;

    /* Whether the checkpoint is valid for the may player to use. */
    UPROPERTY(Category = "Checkpoint")
    bool bCanMayUse = true;

    /* If set, this will be used as the spawn point for the level when starting play. */
    UPROPERTY(Category = "Spawn Point")
    bool bIsLevelSpawnPoint = false;

    /* The respawn effect that's played when spawning here. */
    UPROPERTY(Category = "Checkpoint", AdvancedDisplay)
    TSubclassOf<UPlayerRespawnEffect> RespawnEffect;

    /* Whether positions should automatically trace to the ground. */
    UPROPERTY(Category = "Checkpoint", AdvancedDisplay)
	bool bSnapToGround = true;

    UPROPERTY(Category = "Checkpoint", meta = (MakeEditWidget), AdvancedDisplay)
    FTransform SecondPosition = FTransform(FVector(0, 150, 0));

    UPROPERTY(EditConst, Category = "StoredPosition")
    FTransform StoredSecondPosition;

    UPROPERTY(EditConst, Category = "StoredPosition")
    bool bIsSecondHidden = false;

    UPROPERTY(Meta = (BPCannotCallEvent))
    FOnRespawnedAtCheckpoint OnRespawnAtCheckpoint;

	UPROPERTY(Meta = (BPCannotCallEvent))
	FOnCheckpointEnabled OnCheckpointEnabled;

	UPROPERTY(Meta = (BPCannotCallEvent))
	FOnCheckpointDisabled OnCheckpointDisabled;

	UPROPERTY(BlueprintHidden, EditInstanceOnly, AdvancedDisplay, Category = "Checkpoint")
	TPerPlayer<FTransform> FinalSpawnPositions;

    /* Per-player checkpoint state. */
    TPerPlayer<FCheckpointPlayerState> State;

    /* Scene root for placement. */
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UFUNCTION(Category = "Checkpoint")
    bool IsEnabledForPlayer(AHazePlayerCharacter Player)
    {
        if (Player.Player == EHazePlayer::Cody && !bCanCodyUse)
            return false;
        if (Player.Player == EHazePlayer::May && !bCanMayUse)
            return false;
        return State[Player].bEnabled;
    }

    UFUNCTION(Category = "Checkpoint", BlueprintPure) const
    FTransform GetPositionForPlayer(AHazePlayerCharacter Player)
    {
		return FinalSpawnPositions[Player] * Root.WorldTransform;
    }

    UFUNCTION(Category = "Checkpoint")
    void EnableForPlayer(AHazePlayerCharacter Player)
    {
		if (!State[Player].bEnabled)
		{
			State[Player].bEnabled = true;	
			OnEnabledForPlayer(Player);
		}
    }

	void OnEnabledForPlayer(AHazePlayerCharacter Player)
	{
		OnCheckpointEnabled.ExecuteIfBound(Player);
	}

    UFUNCTION(Category = "Checkpoint")
    void DisableForPlayer(AHazePlayerCharacter Player)
    {
		if (State[Player].bEnabled)
		{
			State[Player].bEnabled = false;
			OnDisableForPlayer(Player);
		}
    }

	void OnDisableForPlayer(AHazePlayerCharacter Player)
	{
		OnCheckpointDisabled.ExecuteIfBound(Player);
	}

	// Snap all checkpoints in visible levels to the ground
	UFUNCTION(CallInEditor)
	void SnapAllCheckpointsToGround()
	{
		TArray<ACheckpoint> AllCheckpoints;
		GetAllActorsOfClass(AllCheckpoints);

		for (auto OtherCheckpoint : AllCheckpoints)
		{
			OtherCheckpoint.UpdatePlayerSpawnLocation();
			OtherCheckpoint.Modify();
			OtherCheckpoint.RerunConstructionScripts();
		}
	}

    UFUNCTION(Category = "Checkpoint")
    void TeleportPlayerToCheckpoint(AHazePlayerCharacter Player)
    {
        FTransform Position = GetPositionForPlayer(Player);
        Player.TeleportActor(Location=Position.GetLocation(), Rotation=Position.GetRotation().Rotator());
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        // Hide the second position if not relevant
        bool bShouldHideSecond = !bCanMayUse || !bCanCodyUse;
        if (bShouldHideSecond != bIsSecondHidden)
        {
            if (bShouldHideSecond)
            {
                StoredSecondPosition = SecondPosition;
                SecondPosition = FTransform(FVector(99999, 99999, 99999));
            }
            else
            {
                SecondPosition = StoredSecondPosition;
            }
            bIsSecondHidden = bShouldHideSecond;
        }

        // Classify the main and secondary transform
#if EDITOR
		if (!bSnapToGround)
			ResetPlayerSpawnLocation();
		else if (!Editor::IsCooking() && Level.IsVisible() && Editor::IsSelected(this))
			UpdatePlayerSpawnLocation();
#endif

        // Make editor visualizers
        if (bCanMayUse)
            CreateForPlayer(EHazePlayer::May, FinalSpawnPositions[EHazePlayer::May]);
        if (bCanCodyUse)
            CreateForPlayer(EHazePlayer::Cody, FinalSpawnPositions[EHazePlayer::Cody]);
    }

	void ResetPlayerSpawnLocation()
	{
		if (bCanMayUse)
		{
			FinalSpawnPositions[EHazePlayer::May] = FTransform::Identity;
			FinalSpawnPositions[EHazePlayer::Cody] = SecondPosition;
		}
		else
		{
			FinalSpawnPositions[EHazePlayer::May] = FTransform::Identity;
			FinalSpawnPositions[EHazePlayer::Cody] = FTransform::Identity;
		}
	}

	void UpdatePlayerSpawnLocation()
	{
		ResetPlayerSpawnLocation();

		// Trace the transforms to the ground if needed
		//   We don't do the trace while cooking, because other levels may not be streamed in
		if (bSnapToGround)
		{
			if (bCanMayUse)
				TraceTransformToGround(FinalSpawnPositions[EHazePlayer::May]);
			if (bCanCodyUse)
				TraceTransformToGround(FinalSpawnPositions[EHazePlayer::Cody]);
		}
	}

	void TraceTransformToGround(FTransform& InOutRelativeTransform)
	{
		FTransform WorldTransform = InOutRelativeTransform * Root.WorldTransform;

		TArray<AActor> Ignored;
		Ignored.Add(this);

		if (ActorUpVector.Equals(FVector::UpVector, 0.01f))
		{
			FHitResult TraceHit;
			System::CapsuleTraceSingleByProfile(
				WorldTransform.Location + FVector(0.f, 0.f, 100.f),
				WorldTransform.Location - FVector(0.f, 0.f, 150.f),
				30.f,
				88.f,
				n"PlayerCharacter",
				false,
				Ignored,
				EDrawDebugTrace::None,
				TraceHit,
				false
			);

			if (TraceHit.bBlockingHit)
				InOutRelativeTransform.Location = Root.WorldTransform.InverseTransformPosition(TraceHit.ImpactPoint);
		}
		else
		{
			TArray<FHitResult> Hits;

			Trace::CapsuleTraceMultiAllHitsByChannel(
				WorldTransform.Location + ActorUpVector * 100.f,
				WorldTransform.Location - ActorUpVector * 150.f,
				ActorQuat,
				30.f,
				88.f,
				ETraceTypeQuery::Visibility,
				false, Ignored,
				Hits);

			for (FHitResult& Hit : Hits)
			{
				if (!Hit.bBlockingHit)
					continue;
				if (Hit.bStartPenetrating)
					continue;

				if (Hit.bBlockingHit)
				{
					InOutRelativeTransform.Location = Root.WorldTransform.InverseTransformPosition(Hit.ImpactPoint);
					break;
				}
			}
		}
	}

    void CreateForPlayer(EHazePlayer Player, const FTransform& RelativeTransform)
    {
        // Add spawn point components that the player spawner will use for positioning
        if (bIsLevelSpawnPoint)
        {
            auto SpawnPoint = UHazePlayerSpawnPointComponent::Create(this);
            SpawnPoint.RelativeTransform = RelativeTransform;
            SpawnPoint.SpawnForPlayer = Player;
        }

#if EDITOR
		if (!Editor::IsCooking())
		{
			// Add an editor billboard indicating this is a checkpoint
			FTransform BillboardTransform = RelativeTransform;
			BillboardTransform.AddToTranslation(FVector(0, 0, 100));

			UBillboardComponent Billboard = UBillboardComponent::Create(this);
			Billboard.RelativeTransform = BillboardTransform;

			if (bIsLevelSpawnPoint)
			{
				Billboard.SetSprite(Asset("/Engine/EditorResources/S_Player"));
				BillboardTransform.Scale3D = FVector(1);
			}
			else
			{
				Billboard.SetSprite(Asset("/Engine/EditorResources/Ai_Spawnpoint"));
				BillboardTransform.Scale3D = FVector(0.6);
			}

			// Create an editor visualizer mesh for the player
			CreatePlayerEditorVisualizer(Root, Player, RelativeTransform);
		}
#endif
    }

	UFUNCTION(NotBlueprintCallable)
	void OnRespawnTriggered(AHazePlayerCharacter Player)
	{
		OnRespawnAtCheckpoint.Broadcast(Player);
	}
};

bool PrepareCheckpointRespawn(AHazePlayerCharacter Player, FPlayerRespawnEvent& OutEvent)
{
	TArray<ACheckpoint> AllCheckpoints;
	GetAllActorsOfClass(AllCheckpoints);

	float ClosestDistance = MAX_flt;
	ECheckpointPriority Priority = ECheckpointPriority::Lowest;
	ACheckpoint ClosestCheckpoint = nullptr;
	FTransform ClosestPosition;

	FVector PlayerLocation = Player.ActorLocation;

	for (ACheckpoint Checkpoint : AllCheckpoints)
	{
		if (int(Checkpoint.RespawnPriority) < int(Priority))
			continue;

		if (!Checkpoint.IsEnabledForPlayer(Player))
			continue;

		if (int(Checkpoint.RespawnPriority) > int(Priority))
		{
			// Higher priority checkpoint, reset the current
			Priority = Checkpoint.RespawnPriority;
			ClosestCheckpoint = nullptr;
			ClosestDistance = MAX_flt;
		}

		FTransform Position = Checkpoint.GetPositionForPlayer(Player);
		float Distance = Position.GetLocation().DistSquared(PlayerLocation);
		if (Distance < ClosestDistance)
		{
			ClosestDistance = Distance;
			ClosestCheckpoint = Checkpoint;
			ClosestPosition = Position;
		}
	}

	if (ClosestCheckpoint != nullptr)
	{
		OutEvent.LocationRelativeTo = ClosestCheckpoint.RootComponent;
		OutEvent.RelativeLocation = ClosestPosition.GetRelativeTransform(ClosestCheckpoint.ActorTransform).Location;
		OutEvent.Rotation = ClosestPosition.Rotator();
		OutEvent.RespawnEffect = ClosestCheckpoint.RespawnEffect;
		OutEvent.OnRespawn = FOnRespawnTriggered(ClosestCheckpoint, n"OnRespawnTriggered");
		return true;
	}
	else
	{
		return false;
	}
}

FString Debug_ShowCheckpoints(AHazePlayerCharacter Player)
{
	FString List;

	TArray<ACheckpoint> AllCheckpoints;
	GetAllActorsOfClass(AllCheckpoints);

	float ClosestDistance = MAX_flt;
	ECheckpointPriority Priority = ECheckpointPriority::Lowest;
	ACheckpoint ClosestCheckpoint = nullptr;
	FTransform ClosestPosition;

	FVector PlayerLocation = Player.ActorLocation;

	TArray<ACheckpoint> EnabledCheckpoints;

	for (ACheckpoint Checkpoint : AllCheckpoints)
	{
		if (int(Checkpoint.RespawnPriority) < int(Priority))
			continue;

		if (!Checkpoint.IsEnabledForPlayer(Player))
			continue;

		EnabledCheckpoints.Add(Checkpoint);

		if (int(Checkpoint.RespawnPriority) > int(Priority))
		{
			// Higher priority checkpoint, reset the current
			Priority = Checkpoint.RespawnPriority;
			ClosestCheckpoint = nullptr;
			ClosestDistance = MAX_flt;
		}

		FTransform Position = Checkpoint.GetPositionForPlayer(Player);
		float Distance = Position.GetLocation().DistSquared(PlayerLocation);
		if (Distance < ClosestDistance)
		{
			ClosestDistance = Distance;
			ClosestCheckpoint = Checkpoint;
			ClosestPosition = Position;
		}
	}

	FLinearColor ActiveColor = Player.IsCody() ? FLinearColor::Green : FLinearColor::Blue;
	FLinearColor AvailableColor = FMath::Lerp(ActiveColor, FLinearColor::White, 0.2f);

	for (ACheckpoint Checkpoint : EnabledCheckpoints)
	{
		FString CheckpointLine = Checkpoint.Name+" (Priority: "+int(Checkpoint.RespawnPriority)+")";

		FTransform Position = Checkpoint.GetPositionForPlayer(Player);
		FVector DebugLocation = Position.Location + (Position.Rotation.UpVector * 100.f);

		if (Checkpoint == ClosestCheckpoint)
		{
			System::DrawDebugCapsule(DebugLocation,
				100.f, 50.f, FRotator::ZeroRotator,
				ActiveColor, Thickness = 16.f);

			List += "\n  ==> "+CheckpointLine;
		}
		else
		{
			System::DrawDebugCapsule(DebugLocation,
				100.f, 50.f, FRotator::ZeroRotator, AvailableColor);

			List += "\n      "+CheckpointLine;
		}
	}

	return List;
}
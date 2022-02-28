import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.ChessBoss.Abilities.CastleChessBossSpawn;
import Cake.LevelSpecific.PlayRoom.Castle.Chessboard.Chessboard;

enum EChessPieceGroupAudioState
{
	Spawning,
	Attacking,
	Despawning
}

struct FChessPieceWaveGroup
{
	TArray<ACastleEnemy> WavePieces;
	EChessPieceGroupAudioState WaveState;
	ECastleChessSpawnType SpawnType;
	bool bHasPerformedSpawn = false;
	bool bHasPerformedAttack = false;
}

class ACastleChessBossAudioManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = Billboard)
	UTextRenderComponent Text;
	default Text.bHiddenInGame = true;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapability;

	UPROPERTY()
	TSubclassOf<UHazeCapability> TileEffectsAudioCapability;

	UPROPERTY()
	AChessboard Chessboard;

	bool bWaveSpawned = false;

	ECastleChessSpawnType CurrentSpawnType;
	TArray<FChessPieceWaveGroup> WaveGroups;
	TArray<FChessPieceWaveGroup> TempWaveGroups;

	UPROPERTY()
	TArray<float> CurrentlyFallingTilePositions;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UClass AudioClass = AudioCapability.Get();
		if(AudioClass != nullptr)
			AddCapability(AudioClass);
		
		if(Chessboard != nullptr)
		{
			UClass TileEffectsAudioClass = TileEffectsAudioCapability.Get();
			if(TileEffectsAudioClass != nullptr)
				Chessboard.AddCapability(TileEffectsAudioClass);	
		}

		SetActorTickEnabled(false);

	}

	UFUNCTION()
	void PrepareNewSpawnAudio(ECastleChessSpawnType SpawnType, TArray<ACastleEnemy> SpawnedPieces)
	{		
		FChessPieceWaveGroup NewWaveGroup;
		NewWaveGroup.SpawnType = SpawnType;
		NewWaveGroup.WavePieces = SpawnedPieces;
		NewWaveGroup.WaveState = EChessPieceGroupAudioState::Spawning;
		bWaveSpawned = true;

		TempWaveGroups.Add(NewWaveGroup);
	}	
}
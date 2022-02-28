import Vino.Interactions.InteractionComponent;
import Vino.Trajectory.TrajectoryDrawer;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessWidget;
import Vino.Camera.Components.CameraUserComponent;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessMoveTo;
import Vino.Tutorial.TutorialPrompt;
import Vino.Interactions.DoubleInteractionActor;

event void FChessMinigamePlayerSignature(AHazePlayerCharacter Player);
event void FChessMinigamePieceAttackMove(AHazePlayerCharacter Player, EChessMinigamePiece MovingPiece, EChessMinigamePiece DestroyedPiece);

const float ChessMinigameScaleMultiplier = 0.7f;
const float ChessMinigamePieceScaleMultiplier = 0.8f;

struct FChessMinigamePosition
{
	UPROPERTY(EditConst)
	int X = -1;

	UPROPERTY(EditConst)
	int Y = -1;

	FChessMinigamePosition()
	{
		X = -1;
		Y = -1;
	}

	FChessMinigamePosition(int _X, int _Y)
	{
		X =_X;
		Y = _Y;
	}

	FChessMinigamePosition OffsetWith(int Xoffset, int Yoffset) const
	{
		return FChessMinigamePosition(X + Xoffset, Y + Yoffset);
	}

	bool IsValid() const
	{
		return X >= 1 && Y >= 1 && X <= 8 && Y <= 8;
	}

	bool IsEqual(const FChessMinigamePosition& Other) const
	{
		return X == Other.X && Y == Other.Y;
	}

	bool IsEqual(int _X, int _Y) const
	{
		return X == _X && Y == _Y;
	}


	FVector ToVector() const
	{
		return FVector(X, Y, 0);
	}

	FVector2D ToVector2D() const
	{
		return FVector2D(X, Y);
	}

}

enum EChessMinigamePiece
{
	Pawn,
	Knight,
	Bishop,
	Rook,
	Queen,
	King,
	Unset
}

enum EChessMinigamePieceMoveType
{
	Unset,
	Current,
	Available,
	Castling,
	Combat,
	Blocked,
	Invalid,	
}

enum EChessMinigamePieceMoveSubType
{
	Unset,
	King,
	Exposed,
	Long,
	Short,
	Pass,
}

enum EChessMinigamePieceMoveSearchType
{
	Unset,
	PreviewMove,
	CanReachEnemyKing,
}

enum EChessMinigameGameTime
{
	Infinite,
	Quick,
	Long,
}

struct EChessMinigamePieceMovePosition
{
	AMinigameChessTile Tile = nullptr;
	EChessMinigamePieceMoveType MoveType = EChessMinigamePieceMoveType::Unset;
	EChessMinigamePieceMoveSubType SubType = EChessMinigamePieceMoveSubType::Unset;
	AMinigameChessPieceBase MoveTypeInstigator;

	EChessMinigamePieceMovePosition(AMinigameChessTile _Tile, EChessMinigamePieceMoveType _MoveType)
	{
		Tile = _Tile;
		MoveType = _MoveType;
	}

	EChessMinigamePieceMovePosition(AMinigameChessboard Board, FChessMinigamePosition Position)
	{
		Tile = Board.GetTileActor(Position);
	}
	
	bool IsValid() const
	{
		return Tile != nullptr;
	}

	bool CanApplyPieceMove(FChessMinigamePosition CurrentPosition) const
	{
		if(!IsValid())
			return false;
		else if(MoveType == EChessMinigamePieceMoveType::Blocked)
			return false;
		else if(GetBoardPosition().IsEqual(CurrentPosition))
			return false;
		return true;
	}

	FChessMinigamePosition GetBoardPosition()const property
	{
		if(Tile != nullptr)
			return Tile.BoardPosition;
		else
			return FChessMinigamePosition(-1, -1);
	}

	FVector2D ToVector2D() const
	{
		const FChessMinigamePosition BoardPos = GetBoardPosition();
		return BoardPos.ToVector2D();
	}

	bool IsMovableMove() const
	{
		return MoveType == EChessMinigamePieceMoveType::Available 
			|| MoveType == EChessMinigamePieceMoveType::Castling
			|| MoveType == EChessMinigamePieceMoveType::Combat;
	}

	bool IsCombatMove() const
	{
		return MoveType == EChessMinigamePieceMoveType::Combat;
	}

	bool IsBlockedMove() const
	{
		return MoveType == EChessMinigamePieceMoveType::Blocked;
	}

	bool IsMoveEnpassant() const
	{
		return MoveType == EChessMinigamePieceMoveType::Combat && SubType == EChessMinigamePieceMoveSubType::Pass;
	}
}

struct EChessMinigamePieceMovePositionArray
{
	AMinigameChessPieceBase InstigatorPiece;

	// All the moves we have collected
	TArray<EChessMinigamePieceMovePosition> CollectedMoves;

	// The current index in the validmoves array
	int ActiveIndex = -1;

	// The current search filter	
	EChessMinigamePieceMoveSearchType SearchFilter = EChessMinigamePieceMoveSearchType::Unset;
	bool bBreakAtFirstFind = false;

	private bool bMovesAreHighlighted = false;

	EChessMinigamePieceMovePositionArray(AMinigameChessPieceBase _Piece)
	{
		InstigatorPiece = _Piece;
	}

	void Add(const EChessMinigamePieceMovePosition& Position)
	{
		CollectedMoves.Add(Position);
	}

	bool GetClosest(EChessMinigamePieceMovePosition& OutFound) const
	{
		return false;
	}

	bool HasAnyMoves() const
	{
		return CollectedMoves.Num() > 0;
	}

	void ApplyTileColor()
	{
		if(bMovesAreHighlighted)
			return;

		bMovesAreHighlighted = true;
		for(auto Move : CollectedMoves)
		{
			Move.Tile.SetPreviewColor(Move.MoveType, Move.SubType);
		}
	}

	void ClearHighlights()
	{
		if(!bMovesAreHighlighted)
			return;

		bMovesAreHighlighted = false;
		for(auto Move : CollectedMoves)
		{
			Move.Tile.SetNeutralColor();
		}
	}

	void Reset()
	{
		ClearHighlights();
		CollectedMoves.Reset();
		ActiveIndex = -1;
	}
}

import void AddChessBoardToPlayer(AHazePlayerCharacter, AMinigameChessboard) from "Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessPlayer";
import void SetActiveChessPiece(AHazePlayerCharacter, AMinigameChessPieceBase) from "Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessPlayer";

UCLASS(Abstract)
class AChessPieceTrajectoryDrawer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UTrajectoryDrawer Root;
}

UCLASS(Abstract)
class AMinigameChessboard : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	default SetActorTickEnabled(false);
	default SetActorScale3D(ChessMinigameScaleMultiplier);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent BoardMesh;
	default BoardMesh.RelativeLocation = FVector(1540, 1540, -20);

	// Class used for chess tile actors
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMinigameChessTile> TileActorClass;

	// Tile actors that the board has created for all the tiles
	UPROPERTY(EditConst)
	TArray<AMinigameChessTile> TileActors;

	UPROPERTY(EditConst)
	TArray<AMinigameChessPieceBase> WhitePieces;

	TArray<AMinigameChessPieceBase> WhiteTeam;
	TArray<AMinigameChessPieceBase> WhiteReplacementPieces;
	TArray<AMinigameChessPieceBase> WhiteRemovedPieces;
	AMinigameChessPieceBase WhiteTeamKing;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	float WhiteTeamTimeLeft = -1;

	UPROPERTY(EditConst)
	TArray<AMinigameChessPieceBase> BlackPieces;

	TArray<AMinigameChessPieceBase> BlackTeam;
	TArray<AMinigameChessPieceBase> BlackReplacementPieces;
	TArray<AMinigameChessPieceBase> BlackRemovedPieces;
	AMinigameChessPieceBase BlackTeamKing;

	UPROPERTY(NotVisible, BlueprintReadOnly)
	float BlackTeamTimeLeft = -1;

	// Time is in minutes
	UPROPERTY(EditDefaultsOnly)
	TMap<EChessMinigameGameTime, float> GameTimes; 

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AChessPieceTrajectoryDrawer> TrajectoryTemplate;

	// Classes used for chess pieces
	UPROPERTY(EditDefaultsOnly)
	TMap<EChessMinigamePiece, TSubclassOf<AMinigameChessPieceBase>> PieceClasses; 

	UPROPERTY(EditDefaultsOnly)
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset PassiveUserCameraSettings;

	UPROPERTY(EditDefaultsOnly)
	UHazeCameraSpringArmSettingsDataAsset ActiveUserCameraSettings;

	UPROPERTY(EditInstanceOnly, Category = "Events")
	AMinigameChessboardGameStarter GameStarterActor;

	UPROPERTY(EditInstanceOnly, Category = "Events")
	AMinigameChessboardGameEnder GameEnderActor;

	UPROPERTY(EditInstanceOnly, Category = "Events")
	FChessMinigamePlayerSignature OnPlayerWon;

	UPROPERTY(EditInstanceOnly, Category = "Events")
	FChessMinigamePieceAttackMove OnPieceTaken;

	UPROPERTY(EditDefaultsOnly, Category = "Messages")
	FText CheckKingMessage;

	UPROPERTY(EditDefaultsOnly, Category = "Tutorial")
	FTutorialPrompt MovePieceTutorial;

	UPROPERTY(EditDefaultsOnly, Category = "Tutorial")
	FTutorialPrompt ApplyPieceMoveTutorial;

	UPROPERTY(EditDefaultsOnly, Category = "Tutorial")
	FTutorialPrompt SwapPieceTutorial;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent MovePreviewTileAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent KingDestroyedAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent PieceDestroyedAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent AttackPreviewAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent ChoosePieceAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent SummonPieceAudioEvent;

	UPROPERTY(EditDefaultsOnly, Category = "Audio")
	UAkAudioEvent ButtonAudioEvent;

	// If this component has an asset set, we will trigger barks from that asset when 
	// one player has been interacting with this double interact fro the given delay time
	// Per audio team request, these will by default trigger continuously.
	UPROPERTY(DefaultComponent, ShowOnActor, Category = "VOBark")
	UVOBarkTriggerComponent VOBarkTriggerComponent;
	default VOBarkTriggerComponent.Delay = 1.f;
	default VOBarkTriggerComponent.RetriggerDelays.Add(1.f);
	default VOBarkTriggerComponent.bRepeatForever = true;

	// If true, bark triggering will be independently triggered on each side in network.
	// Since barks are triggered continuosly and are just reminders default is true.
	UPROPERTY(Category = "VOBark")
	bool bVOBarkTriggerLocally = true;

	private TPerPlayer<bool> BarkReady;

	UPROPERTY(Category = "Events")
	FOnDoubleInteractBarkTriggered OnVOBarkTriggered;

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComponent;
	default MinigameComponent.MinigameTag = EMinigameTag::Chess;
	
	UPROPERTY(EditConst, Transient)
	private int ChessPieceNetworkCount = 0;

	default SetActorTickEnabled(false);
	
	UPROPERTY(EditConst, Transient)
	private AHazePlayerCharacter CurrentPlayer;

	UPROPERTY(EditConst, Transient)
	private AHazePlayerCharacter WhitePlayer;

	bool bTheFirstPieceHasBeenSelected = false;

	private AHazePlayerCharacter PendingWhitePlayer;
	private AHazePlayerCharacter PendingWinningPlayer;
	private bool bHasPendingEnd = false;
	private TArray<AChessPieceTrajectoryDrawer> TrajectoryDrawerContainer;
	private bool bHasNoTeamInitalized = false;

	bool bHasDefaultSetup = false;
	EChessMinigamePieceMoveType LastMoveType = EChessMinigamePieceMoveType::Unset;
	EChessMinigamePiece LastMovedPieceType = EChessMinigamePiece::Unset;
	EChessMinigamePiece LastPieceTakenType = EChessMinigamePiece::Unset;
	EChessMinigamePieceMovePosition EnpassantMove;

	UFUNCTION(CallInEditor, Category = "Chessboard")
	void SpawnTileActors()
	{
		for (auto OldActor : TileActors)
		{
			if (OldActor != nullptr)
				OldActor.DestroyActor();
		}
		TileActors.Empty();

		// Spawn a tile actor for each tile on the board
		for (int Y = 1; Y <= 8; ++Y)
		{
			for (int X = 1; X <= 8; ++X)
			{
				auto Tile = Cast<AMinigameChessTile>(SpawnActor(TileActorClass.Get(), bDeferredSpawn = true));
				Tile.BoardPosition.X = X;
				Tile.BoardPosition.Y = Y;
				Tile.bIsBlack = ((X % 2) != 0) == ((Y % 2) != 0);
				Tile.AttachToActor(this);
				Tile.Board = this;
				FinishSpawningActor(Tile);
				TileActors.Add(Tile);

				const FVector2D PositionAlpha = FVector2D(float(X) - 1.f / 7.f, float(Y) - 1.f / 7.f);
				const FVector2D TileSize(Tile.Collision.BoxExtent.X, Tile.Collision.BoxExtent.Y);
				const float TileY = FMath::Lerp(-TileSize.X, TileSize.X, PositionAlpha.X);
				const float TileX = FMath::Lerp(-TileSize.Y, TileSize.Y, PositionAlpha.Y);

				Tile.SetActorRelativeLocation(FVector(TileX, TileY, -20),
				false,
				FHitResult(),
				true);
				}
		}
	}

	UFUNCTION(CallInEditor, Category = "Chessboard")
	void ResetPiecesSpawnData()
	{
		WhitePieces.Empty();
		BlackPieces.Empty();
		ChessPieceNetworkCount = 0;
	}

	UFUNCTION(CallInEditor, Category = "Chessboard")
	void SpawnPieces()
	{
		for (auto OldActor : WhitePieces)
		{
			if (OldActor != nullptr)
				OldActor.DestroyActor();
		}
		WhitePieces.Empty();

		for (auto OldActor : BlackPieces)
		{
			if (OldActor != nullptr)
				OldActor.DestroyActor();
		}
		BlackPieces.Empty();
		ChessPieceNetworkCount += 64;

		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Rook, false, FVector2D(1, 1)));
		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Knight, false, FVector2D(2, 1)));
		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Bishop, false, FVector2D(3, 1)));
		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Queen, false, FVector2D(4, 1)));
		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::King, false, FVector2D(5, 1)));
		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Bishop, false, FVector2D(6, 1)));
		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Knight, false, FVector2D(7, 1)));
		WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Rook, false, FVector2D(8, 1)));
		for(int i = 1; i <= 8; ++i)
		{
			WhitePieces.Add(SpawnPiece(EChessMinigamePiece::Pawn, false, FVector2D(i, 2)));
		}

		for(auto Piece : WhitePieces)
		{
			Piece.InitalizeStartPosition();
		}


		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Rook, true, FVector2D(1, 8)));
		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Knight, true, FVector2D(2, 8)));
		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Bishop, true, FVector2D(3, 8)));
		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Queen, true, FVector2D(4, 8)));
		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::King, true, FVector2D(5, 8)));
		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Bishop, true, FVector2D(6, 8)));
		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Knight, true, FVector2D(7, 8)));
		BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Rook, true, FVector2D(8, 8)));
		for(int i = 1; i <= 8; ++i)
		{
			BlackPieces.Add(SpawnPiece(EChessMinigamePiece::Pawn, true, FVector2D(i, 7)));
		}

		for(auto Piece : BlackPieces)
		{
			Piece.InitalizeStartPosition();
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VOBarkTriggerComponent.OnVOBarkTriggered.AddUFunction(this, n"BarkTriggered");
		VOBarkTriggerComponent.bTriggerLocally = bVOBarkTriggerLocally;

		if(GameStarterActor != nullptr)
		{
			GameStarterActor.Board = this;
			GameStarterActor.OnLeftInteractionReady.AddUFunction(this, n"VOBarkReady");
			GameStarterActor.OnRightInteractionReady.AddUFunction(this, n"VOBarkReady");
			GameStarterActor.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"VOBarkCancel");
			GameStarterActor.OnDoubleInteractionCompleted.AddUFunction(this, n"VOBarkCompleted");
		}
	#if EDITOR
		else
		{
			devEnsure(false, "Missing BP_MinigameChessBoardStarter");
		}
	#endif

		if(GameEnderActor != nullptr)
		{
			GameEnderActor.Board = this;
			GameEnderActor.DisableActor(this);
		}
	#if EDITOR
		else
		{
			devEnsure(false, "Missing BP_MinigameChessBoardEnder");
		}
	#endif

		// So we have atleaset one
		GetTrajectoryDrawer();

		MinigameComponent.OnMinigamePlayerLeftEvent.AddUFunction(this, n"OnPlayerLeftMidGame");
		MinigameComponent.OnMinigameTutorialComplete.AddUFunction(this, n"OnTutorialAccepted");
        MinigameComponent.OnTutorialCancel.AddUFunction(this, n"OnTutorialCanceled");

		// Force the network spawner to have a valid number
		ChessPieceNetworkCount += 128;
		
		ResetChessPieces();
		InitializeNoTeam();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(int i = TrajectoryDrawerContainer.Num() - 1; i >= 0; --i)
		{
			TrajectoryDrawerContainer[i].DestroyActor();
		}
		TrajectoryDrawerContainer.Reset();

		if(WhitePlayer != nullptr)
		{
			TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
			for(AHazePlayerCharacter& Player : Players)
			{
				Player.RemoveCapabilitySheet(PlayerCapabilitySheet, this);
				Player.ClearCameraSettingsByInstigator(this);
			}
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bHasPendingEnd)
		{
			FinalizeEndGame(PendingWinningPlayer);
			PendingWinningPlayer = nullptr;
			bHasPendingEnd = false; 
		}
		SetActorTickEnabled(false);
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkReady(AHazePlayerCharacter Player)
	{
		BarkReady[Player.Player] = true;
		VOBarkTriggerComponent.SetBarker(Player);

		// Bark is currently only used as a reminder for the other player
		// so should only trigger when exactly one player is interacting
		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnEnded(); // Two inteacting
		else
			VOBarkTriggerComponent.OnStarted(); // We're the only one
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCancel(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		BarkReady[Player.Player] = false;
		VOBarkTriggerComponent.SetBarker(Player.OtherPlayer);

		// Bark is currently only used as a reminder for the other player
		// so should only trigger when exactly one player is interacting
		if (BarkReady[Player.OtherPlayer.Player])
			VOBarkTriggerComponent.OnStarted(); // They're the only one
		else
			VOBarkTriggerComponent.OnEnded(); // Noone interacting
	}

	UFUNCTION(NotBlueprintCallable)
	void VOBarkCompleted()
	{
		// Bark can now safely expire.
		VOBarkTriggerComponent.bRepeatForever = false;
		VOBarkTriggerComponent.TriggerCount = VOBarkTriggerComponent.MaxTriggerCount;
		VOBarkTriggerComponent.OnEnded();
	}

	UFUNCTION(NotBlueprintCallable)
	void BarkTriggered(AHazeActor Barker)
	{
		OnVOBarkTriggered.Broadcast(Cast<AHazePlayerCharacter>(Barker));
	}

	void PrepareGame(AHazePlayerCharacter StartingPlayer, EChessMinigameGameTime GameTimeType)
	{
		if(!devEnsure(StartingPlayer != nullptr, "Can't start chessgame with empty player"))
			return;

		// We cant start a game when 1 game is already ongoing
		if(WhitePlayer != nullptr)
			return;

		GameStarterActor.LeftInteraction.Disable(n"AwaitingTutorial");
		GameStarterActor.RightInteraction.Disable(n"AwaitingTutorial");
		PendingWhitePlayer = StartingPlayer;
		
		FillGameTime(GameTimeType, WhiteTeamTimeLeft);
		FillGameTime(GameTimeType, BlackTeamTimeLeft);
		MinigameComponent.InitializeTime(WhiteTeamTimeLeft);
		MinigameComponent.SetClockIconVisibilityMay(false);
		MinigameComponent.SetClockIconVisibilityCody(false);

		if(PendingWhitePlayer.IsMay())
		{
			MinigameComponent.UpdateDoubleTime(WhiteTeamTimeLeft, Game::May);
			MinigameComponent.UpdateDoubleTime(BlackTeamTimeLeft, Game::Cody);
		}
		else
		{
			MinigameComponent.UpdateDoubleTime(BlackTeamTimeLeft, Game::May);
			MinigameComponent.UpdateDoubleTime(WhiteTeamTimeLeft, Game::Cody);
		}

		PendingWinningPlayer = nullptr;
		bHasPendingEnd = false;

		MinigameComponent.ActivateTutorial();
	}

	UFUNCTION(NotBlueprintCallable)
    private void OnTutorialAccepted()
    {
		ResetChessPieces();

		GameStarterActor.LeftInteraction.Enable(n"AwaitingTutorial");
		GameStarterActor.RightInteraction.Enable(n"AwaitingTutorial");
		GameStarterActor.DisableActor(this);

		GameEnderActor.EnableActor(this);
		GameEnderActor.LeftInteraction.Disable(n"AwaitingCountDown");
		GameEnderActor.RightInteraction.Disable(n"AwaitingCountDown");

		BeginGame();
    }
    
    UFUNCTION(NotBlueprintCallable)
    private void OnTutorialCanceled()
    {
		GameStarterActor.LeftInteraction.Enable(n"AwaitingTutorial");
		GameStarterActor.RightInteraction.Enable(n"AwaitingTutorial");
        PendingWhitePlayer = nullptr;
    }

	UFUNCTION(NotBlueprintCallable)
	private void BeginGame()
	{
		if (WhiteTeamTimeLeft > 0.f && BlackTeamTimeLeft > 0.f) 
			MinigameComponent.ShowGameHud();
		else
			MinigameComponent.bGameHudIsActive = true;

		InitializeWhiteAndBlackTeam();

		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(AHazePlayerCharacter& PlayerIndex : Players)
		{
			PlayerIndex.AddCapabilitySheet(PlayerCapabilitySheet, EHazeCapabilitySheetPriority::High, this);
			AddChessBoardToPlayer(PlayerIndex, this);

			FHazeCameraBlendSettings Blend;
			Blend.BlendTime = 1.f;
			PlayerIndex.ApplyCameraSettings(PassiveUserCameraSettings, Blend, this, EHazeCameraPriority::Medium);
		}

		SetActivePlayer(WhitePlayer); 

		GameEnderActor.LeftInteraction.SetExclusiveForPlayer(WhitePlayer.Player, false);
		GameEnderActor.RightInteraction.SetExclusiveForPlayer(WhitePlayer.GetOtherPlayer().Player, false);

		GameEnderActor.LeftInteraction.Enable(n"AwaitingCountDown");
		GameEnderActor.RightInteraction.Enable(n"AwaitingCountDown");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnPlayerLeftMidGame(AHazePlayerCharacter Player)
	{
		EndGameWithPlayerAsWinner(Player, Player.GetOtherPlayer());	
	}

	void EndGameWithPlayerAsWinner(AHazePlayerCharacter ControllingPlayer, AHazePlayerCharacter WinningPlayer)
	{
		auto SendingPlayer = ControllingPlayer;
		if(SendingPlayer == nullptr)
			SendingPlayer = Game::GetMay();

		if(!SendingPlayer.HasControl())
			return;

		auto Crumb = UHazeCrumbComponent::Get(SendingPlayer);
		
		FHazeDelegateCrumbParams Params;
		Params.AddObject(n"WinningPlayer", WinningPlayer);
		Crumb.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_EndGameWithPlayerAsWinner"), Params);
	}

	UFUNCTION(NotBlueprintCallable)
	void Crumb_EndGameWithPlayerAsWinner(const FHazeDelegateCrumbData& CrumbData)
	{
		PendingWinningPlayer = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"WinningPlayer"));
		bHasPendingEnd = true;
		SetActorTickEnabled(true);
	}

	void FinalizeEndGame(AHazePlayerCharacter WinningPlayer)
	{
		if(WhitePlayer == nullptr)
			return;

		GameEnderActor.DisableActor(this);
		GameStarterActor.EnableActor(this);

		// Player can be nullptr if it is a draw or a forced end
		if(WinningPlayer != nullptr)
		{
			MinigameComponent.AdjustScore(WinningPlayer, 1);
			MinigameComponent.AnnounceWinner(WinningPlayer);
		}
		else
		{
			MinigameComponent.AnnounceWinner(EMinigameWinner::Draw);
		}

		OnPlayerWon.Broadcast(WinningPlayer);

		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for(AHazePlayerCharacter& Player : Players)
		{
			Player.RemoveCapabilitySheet(PlayerCapabilitySheet, this);
			Player.ClearCameraSettingsByInstigator(this);
		}

		WhitePlayer = nullptr;
		SetActivePlayer(nullptr);
		InitializeNoTeam();
	}

	void FillGameTime(EChessMinigameGameTime Type, float& TeamTime)const
	{
		if(!GameTimes.Find(Type, TeamTime))
			TeamTime = -1;
		else
			TeamTime *= 60;
	}

	void SetActivePlayer(AHazePlayerCharacter NewPlayer)
	{
		if(CurrentPlayer != nullptr)
		{
			CurrentPlayer.ClearViewSizeOverride(this);
			if(CurrentPlayer == WhitePlayer)
				DisableWhiteTeamInteraction();
			else
				DisableBlackTeamInteraction();
		}

		if(WhitePlayer == nullptr || NewPlayer == nullptr)
			return;

		CurrentPlayer = NewPlayer;
		CurrentPlayer.ApplyViewSizeOverride(this, EHazeViewPointSize::Large, EHazeViewPointBlendSpeed::Normal);
		if(CurrentPlayer == WhitePlayer)
			EnableWhiteTeamInteraction();
		else
			EnableBlackTeamInteraction();


		if(CurrentPlayer.IsMay())
		{
			MinigameComponent.SetClockIconVisibilityMay(false);
			MinigameComponent.SetClockIconVisibilityCody(true);
		}
		else
		{
			MinigameComponent.SetClockIconVisibilityCody(false);
			MinigameComponent.SetClockIconVisibilityMay(true);
		}

		auto TeamKing = GetKing(CurrentPlayer);
		bool bKingIsCheck = false;
		bool bCanMoveSomething = false;
		// We need to check if our king is exposed at the start
		{
			
			EChessMinigamePieceMovePositionArray PotentialEnemyMoves = EChessMinigamePieceMovePositionArray(TeamKing);
			PotentialEnemyMoves.SearchFilter = EChessMinigamePieceMoveSearchType::CanReachEnemyKing;
			PotentialEnemyMoves.bBreakAtFirstFind = true;
			
			const auto& OtherTeam = CurrentPlayer == WhitePlayer ? BlackTeam : WhiteTeam;
			for(auto Piece : OtherTeam)
			{
				if(!bKingIsCheck)
				{
					PotentialEnemyMoves.CollectedMoves.Reset(1);
					Piece.GetAvailableMoves(PotentialEnemyMoves);
					if(PotentialEnemyMoves.HasAnyMoves())
					{
						bKingIsCheck = true;
						break;
					}
				}
			}
		}

		// We need to check if we have any available moves at all
		{	
			const auto& MyTeam = CurrentPlayer == WhitePlayer ? WhiteTeam : BlackTeam;
			for(auto Piece : MyTeam)
			{
				if(Piece.GenerateAvailableMoveToTiles())
					bCanMoveSomething = true;
			}
		}

		if(bKingIsCheck)
		{
			if(bCanMoveSomething)
			{
				CheckKing(TeamKing);
			}
			else 
			{
				// Check mate
				EndGameWithPlayerAsWinner(CurrentPlayer, CurrentPlayer.OtherPlayer);
				return;
			}
		}
		else if(!bCanMoveSomething)
		{
			// No valid moves
			EndGameWithPlayerAsWinner(CurrentPlayer, nullptr);
			return;
		}
		else if(BlackTeam.Num() <= 2 && WhiteTeam.Num() <= 2)
		{
			// we cant win with only king and knight
			bool bBlackWantsDraw = true;
			if(BlackTeam.Num() == 2)
			{
				bBlackWantsDraw = false;
				for(auto Piece : BlackTeam)
				{
					// we cant win with only king and knight
					if(Piece.Type == EChessMinigamePiece::Knight)
					{
						bBlackWantsDraw = true;
						break;
					}
				}
			}

			bool bWhiteWantsDraw = true;
			if(WhiteTeam.Num() == 2)
			{
				bWhiteWantsDraw = false;
				for(auto Piece : WhiteTeam)
				{
					// we cant win with only king and knight
					if(Piece.Type == EChessMinigamePiece::Knight)
					{
						bWhiteWantsDraw = true;
						break;
					}
				}
			}
		
			if(bWhiteWantsDraw && bBlackWantsDraw)
			{
				EndGameWithPlayerAsWinner(CurrentPlayer, nullptr);
				return;	
			}
		}
	
		auto PlayerMadeMove = CurrentPlayer.OtherPlayer;

		// Broadcast the last type we took
		if(LastPieceTakenType != EChessMinigamePiece::Unset)
			OnPieceTaken.Broadcast(PlayerMadeMove, LastMovedPieceType, LastPieceTakenType);
	}

	void FinalizePieceMove(AHazePlayerCharacter Player, AMinigameChessPieceBase Piece)
	{
		const EChessMinigamePieceMoveSubType MoveSubType = Piece.ActiveMoveToPosition.SubType;
		Piece.OnMoveFinalized(Player, Piece.ActiveMoveToPosition);

		// The king has been taken, should never happen
		if(MoveSubType == EChessMinigamePieceMoveSubType::King)
		{
			EndGameWithPlayerAsWinner(Player, Player);
		}
	}

	void SwapPiece(AHazePlayerCharacter Player, AMinigameChessPieceBase Piece, EChessMinigamePiece NewType)
	{
		FVector2D CurrentPosition(Piece.BoardPosition.X, Piece.BoardPosition.Y);
		RemovePiece(Piece);

		if(WhitePlayer == Player)
		{
			auto NewPiece = SpawnPiece(NewType, false, CurrentPosition);
			WhiteTeam.Add(NewPiece);
			WhiteReplacementPieces.Add(NewPiece);
			NewPiece.InitalizeStartPosition();
			NewPiece.InitializeForGameplay(Player);
			SetActiveChessPiece(Player, NewPiece);
		}
		else
		{
			auto NewPiece = SpawnPiece(NewType, true, CurrentPosition);
			BlackTeam.Add(NewPiece);
			BlackReplacementPieces.Add(NewPiece);
			NewPiece.InitalizeStartPosition();
			NewPiece.InitializeForGameplay(Player);
			SetActiveChessPiece(Player, NewPiece);
		}
	}

	void ResetChessPieces()
	{
		if(bHasDefaultSetup)
			return;

		LastMoveType = EChessMinigamePieceMoveType::Unset;
		LastMovedPieceType = EChessMinigamePiece::Pawn;
		bHasDefaultSetup = true;

		// First reset all the tiles so we can prep the board
		for(auto Tile : TileActors)
		{
			if(Tile._Piece != nullptr)
			{
				Tile._Piece.SetBoardTile(nullptr);
			}

			if(Tile._PreviewPiece != nullptr)
			{
				Tile._PreviewPiece.SetPreviewMoveTile(nullptr);
			}
		}

		// White Team Reset
		for(auto TeamPiece : WhiteReplacementPieces)
		{
			TeamPiece.DestroyActor();
		}
		WhiteReplacementPieces.Reset();
		
		for(auto TeamPiece : WhiteRemovedPieces)
		{
			TeamPiece.EnableActor(this);
		}
		WhiteRemovedPieces.Reset();
		
		WhiteTeam = WhitePieces;
		for(auto TeamPiece : WhiteTeam)
		{
			TeamPiece.InitalizeStartPosition();
			if(TeamPiece.Type == EChessMinigamePiece::King)
				WhiteTeamKing = TeamPiece;
		}

		
		// Black Team Reset
		for(auto TeamPiece : BlackReplacementPieces)
		{
			TeamPiece.DestroyActor();
		}
		BlackReplacementPieces.Reset();
		
		for(auto TeamPiece : BlackRemovedPieces)
		{
			TeamPiece.EnableActor(this);
		}
		BlackRemovedPieces.Reset();

		BlackTeam = BlackPieces;
		for(auto TeamPiece : BlackTeam)
		{
			TeamPiece.InitalizeStartPosition();
			if(TeamPiece.Type == EChessMinigamePiece::King)
				BlackTeamKing = TeamPiece;
		}
	}

	void RemovePiece(AMinigameChessPieceBase Piece)
	{
		if(Piece.bIsBlack)
		{
			BlackTeam.RemoveSwap(Piece);
			BlackRemovedPieces.Add(Piece);
		}
		else
		{
			WhiteTeam.RemoveSwap(Piece);
			WhiteRemovedPieces.Add(Piece);
		}

		// Effect
		if(Piece.DestroyEffect != nullptr)
			Niagara::SpawnSystemAtLocation(Piece.DestroyEffect, Piece.GetActorLocation(), Piece.GetActorRotation());

		// Audio, Destroy Piece
		if(Piece.Type == EChessMinigamePiece::King)
		{
			UHazeAkComponent::HazePostEventFireForget(KingDestroyedAudioEvent, Piece.GetActorTransform());
		}
		else
		{
			UHazeAkComponent::HazePostEventFireForget(PieceDestroyedAudioEvent, Piece.GetActorTransform());
		}
		
		Piece.SetBoardTile(nullptr);
		Piece.DisableActor(this);
	}

	AMinigameChessPieceBase SpawnPiece(EChessMinigamePiece Type, bool bIsBlack, FVector2D Position)
	{
        if (!PieceClasses[Type].IsValid())
        {
            devEnsure(false, "Invalid enemy class on chessboard spawn.");
            return nullptr;
        }

//#if EDITOR
// We make a nice debug name during development
		FString DebugName = "";
		switch(Type)
		{
			case EChessMinigamePiece::King:
				DebugName = "King";
				break;
			case EChessMinigamePiece::Queen:
				DebugName = "Queen";
				break;
			case EChessMinigamePiece::Bishop:
				DebugName = "Bishop";
				break;
			case EChessMinigamePiece::Knight:
				DebugName = "Knight";
				break;
			case EChessMinigamePiece::Rook:
				DebugName = "Rook";
				break;
			case EChessMinigamePiece::Pawn:
				DebugName = "Pawn";
				break;
			default:
				DebugName = "Undefiened";
				break;
		}
		const FName PieceName = FName(FString((bIsBlack ? "Black_" : "White_") + DebugName + "_" + ChessPieceNetworkCount));
// #else
// 		const FName PieceName = NAME_None;
// #endif

        auto Piece = Cast<AMinigameChessPieceBase>(SpawnActor(PieceClasses[Type], Name = PieceName, bDeferredSpawn = true, Level = GetLevel()));
		Piece.Type = Type;
		Piece.Board = this;
	 	Piece.bIsBlack = bIsBlack;
		Piece.InitialBoardPosition = Position;
		Piece.MakeNetworked(this, ChessPieceNetworkCount);
		FinishSpawningActor(Piece);		
        ChessPieceNetworkCount += 1;
        return Piece;
	}

	bool ImActivePlayer(AHazePlayerCharacter Player) const
	{
		return Player == CurrentPlayer;
	}

	void InitializeWhiteAndBlackTeam()
	{
		WhitePlayer = PendingWhitePlayer;
		bTheFirstPieceHasBeenSelected = false;
		bHasNoTeamInitalized = false;
		
		// Initailize the pieces
		for(auto TeamPiece : WhiteTeam)
		{
			TeamPiece.InitializeForGameplay(WhitePlayer);
		}

		auto BlackPlayer = WhitePlayer.GetOtherPlayer();
		for(auto TeamPiece : BlackTeam)
		{
			TeamPiece.InitializeForGameplay(BlackPlayer);
		}

		PendingWhitePlayer = nullptr;
		PendingWinningPlayer = nullptr;
		bHasPendingEnd = false;
	}

	void InitializeNoTeam()
	{
		if(bHasNoTeamInitalized)
			return;

		bHasNoTeamInitalized = true;
		DisableWhiteTeamInteraction();
		DisableBlackTeamInteraction();
	}

	void BlockTeamForPlayer(AHazePlayerCharacter Player)
	{
		if(Player == WhitePlayer)
		{
			for(auto TeamPiece : WhiteTeam)
			{
				TeamPiece.InteractionPoint.Disable(n"ActivePiece");
			}
		}
		else
		{
			for(auto TeamPiece : BlackTeam)
			{
				TeamPiece.InteractionPoint.Disable(n"ActivePiece");
			}
		}
	}

	void UnblockTeamForPlayer(AHazePlayerCharacter Player)
	{
		if(Player == WhitePlayer)
		{
			for(auto TeamPiece : WhiteTeam)
			{
				TeamPiece.InteractionPoint.Enable(n"ActivePiece");
			}
		}
		else
		{
			for(auto TeamPiece : BlackTeam)
			{
				TeamPiece.InteractionPoint.Enable(n"ActivePiece");
			}
		}
	}

	void DisableWhiteTeamInteraction()
	{	
		for(auto TeamPiece : WhiteTeam)
		{
			TeamPiece.InteractionPoint.Disable(n"NoActiveGame");
		}
	}

	void DisableBlackTeamInteraction()
	{	
		for(auto TeamPiece : BlackTeam)
		{
			TeamPiece.InteractionPoint.Disable(n"NoActiveGame");
		}
	}

	void EnableWhiteTeamInteraction()
	{
		for(auto TeamPiece : WhiteTeam)
		{
			TeamPiece.InteractionPoint.Enable(n"NoActiveGame");
		}
	}

	void EnableBlackTeamInteraction()
	{
		for(auto TeamPiece : BlackTeam)
		{
			TeamPiece.InteractionPoint.Enable(n"NoActiveGame");
		}
	}

	const TArray<AMinigameChessPieceBase>& GetAllPieces(AHazePlayerCharacter Player)const
	{
		if(Player == WhitePlayer)
			return WhiteTeam;
		else
			return BlackTeam;
	}

	const TArray<AMinigameChessPieceBase>& GetAllPieces(bool bBlackTeam)const
	{
		if(bBlackTeam)
			return BlackTeam;
		else
			return WhiteTeam;
	}

	AMinigameChessTile GetTileActor(FChessMinigamePosition GridPosition) const
	{
		if (!GridPosition.IsValid())
			return nullptr;
		return TileActors[((GridPosition.Y - 1) * 8) + (GridPosition.X - 1)];
	}

	AMinigameChessPieceBase GetKing(AHazePlayerCharacter Player) const
	{
		return GetKing(Player != WhitePlayer);
	}

	AMinigameChessPieceBase GetKing(bool bBlackKing) const
	{
		if(bBlackKing)
			return BlackTeamKing;
		else
			return WhiteTeamKing;
	}

	void CheckKing(AMinigameChessPieceBase King)
	{
		FVector CheckPosition = King.GetActorLocation();
		CheckPosition.Z += King.Collision.CapsuleHalfHeight;

		FMinigameWorldWidgetSettings MinigameWorldSettings;	
		MinigameWorldSettings.MinigameTextMovementType = EMinigameTextMovementType::AccelerateToHeight;
		MinigameWorldSettings.TextJuice = EInGameTextJuice::BigChange;
		MinigameWorldSettings.MinigameTextColor = EMinigameTextColor::Attention;
		MinigameWorldSettings.TimeDuration = 4.f;
		MinigameComponent.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, CheckKingMessage.ToString(), CheckPosition, MinigameWorldSettings);
	}

	FVector GetWorldPosition(FChessMinigamePosition GridPosition)const
	{
		if (!GridPosition.IsValid())
			return FVector::ZeroVector;

		return GetWorldPosition(GetTileActor(GridPosition));
	}

	FVector GetWorldPosition(AMinigameChessTile GridPosition)const
	{
		if (GridPosition == nullptr)
			return FVector::ZeroVector;

		FVector Position = GridPosition.GetActorLocation();
		//Position.Z += GridPosition.Collision.BoxExtent.Z * 2;
		return Position;
	}

	void SetTeamTime(AHazePlayerCharacter Player, float NewTime)
	{
		if(Player == WhitePlayer)
			WhiteTeamTimeLeft = NewTime;
		else
			BlackTeamTimeLeft = NewTime;

		if(WhitePlayer.IsMay())
		{
			MinigameComponent.UpdateDoubleTime(WhiteTeamTimeLeft, Game::May);
			MinigameComponent.UpdateDoubleTime(BlackTeamTimeLeft, Game::Cody);
		}
		else
		{
			MinigameComponent.UpdateDoubleTime(BlackTeamTimeLeft, Game::May);
			MinigameComponent.UpdateDoubleTime(WhiteTeamTimeLeft, Game::Cody);
		}
	}

	float GetTeamTimeLeft(AHazePlayerCharacter Player) const
	{
		if(Player == WhitePlayer)
			return WhiteTeamTimeLeft;
		else
			return BlackTeamTimeLeft;			
	}

	void ReturnTrajectoryDrawer(UTrajectoryDrawer Drawer)
	{
		auto Trajectory = Cast<AChessPieceTrajectoryDrawer>(Drawer.Owner);
		TrajectoryDrawerContainer.Add(Trajectory);
	}

	UTrajectoryDrawer GetTrajectoryDrawer()
	{
		if(TrajectoryDrawerContainer.Num() == 0)
		{
			auto NewDrawer = Cast<AChessPieceTrajectoryDrawer>(SpawnPersistentActor(TrajectoryTemplate));
			NewDrawer.AttachToComponent(Root);
			NewDrawer.SetOwner(this);
			TrajectoryDrawerContainer.Add(NewDrawer);
		}

		UTrajectoryDrawer Drawer = TrajectoryDrawerContainer[TrajectoryDrawerContainer.Num() - 1].Root;
		TrajectoryDrawerContainer.RemoveAt(TrajectoryDrawerContainer.Num() - 1);
		return Drawer;
	}
};

UCLASS(Abstract)
class AMinigameChessTile : AHazeActor
{
	default SetActorScale3D(ChessMinigameScaleMultiplier);

	default PrimaryActorTick.bStartWithTickEnabled = false;
	default SetActorTickEnabled(false);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.bGenerateOverlapEvents = false;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.BoxExtent = FVector(100.f, 100.f, 100.f);
	default Collision.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(EditConst, BlueprintReadOnly)
	bool bIsBlack = false;

	UPROPERTY(EditConst, BlueprintReadOnly)
	FChessMinigamePosition BoardPosition;

	UPROPERTY(EditConst)
	AMinigameChessboard Board;

	UPROPERTY(EditConst, Transient)
	AMinigameChessPieceBase _Piece;

	UPROPERTY(EditConst, Transient)
	AMinigameChessPieceBase _PreviewPiece;

	private float BlendInTime = 0.f;
	private float TimeLeft = 0;
	private float TargetOpacity = 0.f;
	private float CurrentOpacity = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh.SetVisibility(false);
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		TimeLeft -= DeltaTime;
		if(TimeLeft <= 0)
		{
			Mesh.SetScalarParameterValueOnMaterials(n"Opacity", TargetOpacity);
			CurrentOpacity = TargetOpacity;
			SetActorTickEnabled(false);
			if(CurrentOpacity <= 0.f)
				Mesh.SetVisibility(false);
		}
		else
		{
			const float Alpha = 1.f - (TimeLeft / BlendInTime);
			CurrentOpacity = FMath::Lerp(CurrentOpacity, TargetOpacity, Alpha);
			Mesh.SetScalarParameterValueOnMaterials(n"Opacity", CurrentOpacity);
		}
	}

	void SetPreviewColor(EChessMinigamePieceMoveType MoveType, EChessMinigamePieceMoveSubType SubType)
	{
		if(MoveType == EChessMinigamePieceMoveType::Unset ||
			MoveType == EChessMinigamePieceMoveType::Current)
		return;

		FVector DebugPosition = Board.GetWorldPosition(this);
		DebugPosition.Z += 200;

		float BlockedValue = 0;
		float AttackValue = 0;
		
		if(MoveType == EChessMinigamePieceMoveType::Blocked)
		{
			BlockedValue = 1.f;
		}
		else if(MoveType == EChessMinigamePieceMoveType::Combat)
		{
			AttackValue = 1.f;
		}
		else if(SubType == EChessMinigamePieceMoveSubType::Exposed)
		{
			BlockedValue = 1.f;
		}

		Mesh.SetScalarParameterValueOnMaterials(n"IsBlockedMove", BlockedValue);
		Mesh.SetScalarParameterValueOnMaterials(n"IsAttackingMove", AttackValue);

		BlendInTime = 0.2f;
		TimeLeft = BlendInTime;
		TargetOpacity = 1.f;
		Mesh.SetScalarParameterValueOnMaterials(n"Opacity", 0.f);
		SetActorTickEnabled(true);
		Mesh.SetVisibility(true);
	}

	void SetNeutralColor()
	{
		BlendInTime = 0.2f;
		TimeLeft = BlendInTime;
		TargetOpacity = 0.f;
		SetActorTickEnabled(true);
	}

	AMinigameChessPieceBase GetPiece() const property
	{
		if(_Piece == nullptr 
		|| _Piece._PreviewTile == nullptr
		|| _Piece._PreviewTile == _Piece._BoardTile)
			return _Piece;

		return nullptr;
	}

	AMinigameChessPieceBase GetPreviewPiece() const property
	{
		return _PreviewPiece;
	}

	float GetJumpToOffset() const property
	{
		if(_Piece == nullptr)
			return 0;
		
		return _Piece.Collision.GetCapsuleHalfHeight() * 2;
	}
}

enum EMinigameChessPieceState
{
	Inactive,
	InactiveAwaitingAnimiationFinish,
	Preview,
	PreviewAttack,
	PieceMovingToTile,
	PieceLandOnEmptyTile,
	PieceLandOnOtherPiece,
	PieceLandedOnSwapPieceTile
}

UCLASS(Abstract)
class AMinigameChessPieceBase : AHazeActor
{
	default SetActorScale3D(ChessMinigamePieceScaleMultiplier);

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PreviewLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent StaticMesh;
	default StaticMesh.SetCollisionProfileName(n"NoCollision");
	default StaticMesh.SetCastShadow(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeOffsetComponent MeshOffset;

	UPROPERTY(DefaultComponent, Attach = MeshOffset)
	USkeletalMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");
	default Mesh.SetCastShadow(false);
	default Mesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent Collision;
	default Collision.bGenerateOverlapEvents = false;
	default Collision.SetCollisionProfileName(n"BlockAll");
	default Collision.CapsuleHalfHeight = 200;
	default Collision.CapsuleRadius = 120;
	default Collision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default Collision.RemoveTag(n"Walkable");

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionPoint;
	default InteractionPoint.FocusShapeTransform.SetScale3D(FVector(1.f, 1.f, 1.f));
	default InteractionPoint.MovementSettings.InitializeJumpTo(0.f);
	default InteractionPoint.ActivationSettings.NetworkMode = EHazeTriggerNetworkMode::ActorControl;
	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 350.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.FocusShape.SphereRadius = 350.f;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(80.f, 0.f, 100.f);
	default InteractionPoint.SetRelativeLocation(FVector(-30, 0.f, 100.f));

	UPROPERTY(EditConst, BlueprintReadOnly, Category = "Default")
	EChessMinigamePiece Type;

	UPROPERTY(EditConst, BlueprintReadOnly, Category = "Default")
	bool bIsBlack = false;

	UPROPERTY(EditDefaultsOnly, Category = "Default")
	FMinigameChessMoveToTimes JumpMove;

	// Animation while piece is doing nothing
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
    FHazePlaySequenceData IdleMH;
	default IdleMH.bLoop = true;

	// Animation when the player has dropped this piece on top of another piece
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySequenceData MoveToTarget;

	// Animation when the player has dropped this piece on top of another piece
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySequenceData Attack;

	// Animation while the player is on move preview
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
    FHazePlaySequenceData PreviewMoveMH;
	default PreviewMoveMH.bLoop = true;

	// Animation while the player is previewing the attack of another piece
	UPROPERTY(EditDefaultsOnly, Category = "Animation")
	FHazePlaySequenceData PreviewAttackMH;
	default PreviewAttackMH.bLoop = true;

	UPROPERTY(EditDefaultsOnly, Category = "Effect")
	UNiagaraSystem LandedEffect;

	UPROPERTY(EditDefaultsOnly, Category = "Effect")
	UNiagaraSystem DestroyEffect;

	UPROPERTY(NotEditable, BlueprintReadOnly, Category = "Default")
	UMaterialInstanceDynamic DynamicMaterial;

	UPROPERTY(EditConst, BlueprintReadOnly, Category = "Default")
	FVector2D InitialBoardPosition;

	UPROPERTY(EditConst, BlueprintReadOnly, Category = "Default")
	AMinigameChessboard Board;

	UPROPERTY(EditConst, BlueprintReadOnly, Category = "Default")
	AMinigameChessTile _BoardTile;

	AHazePlayerCharacter ControllingPlayer;
	AMinigameChessTile _PreviewTile;
	UTrajectoryDrawer Trajectory;

	protected EChessMinigamePieceMovePositionArray AvailableMoveToTiles;

	protected EMinigameChessPieceState _RemainingAnimationState = EMinigameChessPieceState::Inactive;
	protected EMinigameChessPieceState _State = EMinigameChessPieceState::Inactive;

	//protected bool bHasMoved = false;
	FMinigameChessMoveTo ActiveMoveTo;
	EChessMinigamePieceMovePosition ActiveMoveToPosition;
	FTimerHandle ActiveAfterMoveToTimer;
	EChessMinigamePieceMoveType LastMoveType = EChessMinigamePieceMoveType::Unset;
	EChessMinigamePieceMoveSubType LastMoveSubType = EChessMinigamePieceMoveSubType::Unset;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		SetActorRelativeScale3D(FVector(ChessMinigamePieceScaleMultiplier));
		Collision.RelativeLocation = FVector(0.f, 0.f, Collision.CapsuleHalfHeight);
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		DynamicMaterial = Mesh.CreateDynamicMaterialInstance(0);
		if(bIsBlack)
			DynamicMaterial.SetVectorParameterValue(n"BaseColor Tint", FLinearColor(0.1f, 0.1f, 0.1f));
		else
			DynamicMaterial.SetVectorParameterValue(n"BaseColor Tint", FLinearColor(0.5f, 0.5f, 0.5f));
			
		StaticMesh.SetMaterial(0, DynamicMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AvailableMoveToTiles = EChessMinigamePieceMovePositionArray(this);
		ShowStaticMeshHideSkelMesh();
	}

	void InitalizeStartPosition()
	{
		FRotator PieceRotation;
		if(!bIsBlack)
			PieceRotation = Board.GetActorRotation();
		else
			PieceRotation =(-Board.GetActorForwardVector()).Rotation();

		const FChessMinigamePosition Position(InitialBoardPosition.X, InitialBoardPosition.Y);
		SetBoardTile(Board.GetTileActor(Position));
		SetActorLocationAndRotation(Board.GetWorldPosition(Position), PieceRotation);

		// Reset everything
		LastMoveType = EChessMinigamePieceMoveType::Unset;
		LastMoveSubType = EChessMinigamePieceMoveSubType::Unset;
		_RemainingAnimationState = EMinigameChessPieceState::Inactive;
		ControllingPlayer = nullptr;
		_PreviewTile = nullptr;
		AvailableMoveToTiles.Reset();
		ActiveMoveTo = FMinigameChessMoveTo();
		ActiveMoveToPosition = EChessMinigamePieceMovePosition();
	}

	void InitializeForGameplay(AHazePlayerCharacter OwningPlayer)
	{
		ControllingPlayer = OwningPlayer;
		SetControlSide(OwningPlayer);
		InteractionPoint.SetExclusiveForPlayer(OwningPlayer.Player, false);
	}

	UFUNCTION(NotBlueprintCallable)
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {

#if TEST
		// Trying to find a interaction bug 
		Log("Piece picked: " + Component.GetOwner().GetName());

#endif

		SetActiveChessPiece(Player, this);
    }

	void DrawTrajectory(AHazePlayerCharacter Player, AMinigameChessPieceBase TargetPiece = nullptr, FLinearColor Color = FLinearColor::Red)
	{
		const FVector From = Board.GetWorldPosition(GetBoardPosition());
		FVector To;
		if(TargetPiece == nullptr)
		{
			To = Board.GetWorldPosition(GetBoardPreviewPosition());
		}
		else
		{
			if(TargetPiece.IsPreviewing())
				To = Board.GetWorldPosition(TargetPiece.GetBoardPreviewPosition());
			else
				To = Board.GetWorldPosition(TargetPiece.GetBoardPosition());
		}
		const FVector Direction = (To - From).GetSafeNormal();
		const float Distance = From.Distance(To);
		if(Distance <= KINDA_SMALL_NUMBER)
			return;

		const float Gravity = 100.f;
		const float Alpha = FMath::Min((Distance / 400.f) / 8, 1.f);
		const float JumpHeight = FMath::Lerp(300.f, 600.f, Alpha);
		const FOutCalculateVelocity Result = CalculateParamsForPathWithHeight(
			From, 
			To, 
			Gravity, 
			JumpHeight);

		if(Trajectory == nullptr)
			Trajectory = Board.GetTrajectoryDrawer();

		float DrawLength = Distance + FMath::Sqrt(JumpHeight);
		Trajectory.DrawTrajectory(From, DrawLength, Result.Velocity, Gravity, 20.0f, Color, Player);
	}

	AMinigameChessTile GetBoardTile() const property
	{
		return _BoardTile;
	}

	void SetBoardTile(AMinigameChessTile NewTile) property
	{
		// First clear the old tile
		if(_BoardTile != nullptr)
		{
			// We cant take control over this tile if there is another piece here
			if(!devEnsure(_BoardTile._Piece == nullptr || _BoardTile._Piece == this))
				return;

			_BoardTile._Piece = nullptr;
		}
	
		_BoardTile = NewTile;
		if(_BoardTile != nullptr)
			_BoardTile._Piece = this;
	}

	void SetPreviewMoveTile(AMinigameChessTile NewTile) property
	{
		if(_PreviewTile != nullptr)
			_PreviewTile._PreviewPiece = nullptr;

		if(NewTile != nullptr)
			NewTile._PreviewPiece = this;

		_PreviewTile = NewTile;
	}

	bool GenerateAvailableMoveToTiles()
	{
		// First, we clear out all the old available moves
		AvailableMoveToTiles.Reset();

		AvailableMoveToTiles.SearchFilter = EChessMinigamePieceMoveSearchType::PreviewMove;
		GetAvailableMoves(AvailableMoveToTiles);

		// Add the current location to the available locations
		AvailableMoveToTiles.Add(EChessMinigamePieceMovePosition(BoardTile, EChessMinigamePieceMoveType::Current));
		FinalizeAvailableMoves(AvailableMoveToTiles);
		
		for(EChessMinigamePieceMovePosition Move : AvailableMoveToTiles.CollectedMoves)
		{
			if(!Move.IsMovableMove())
				continue;

			// We could move here, but that will make the king exposed
			if(Move.SubType == EChessMinigamePieceMoveSubType::Exposed)
				continue;

			return true;
		}

		return false;
	}

	void PlayerTakeControl()
	{
		if(System::IsTimerActiveHandle(ActiveAfterMoveToTimer))
			OnMoveFinalizedInternal();

		GenerateAvailableMoveToTiles();

		AvailableMoveToTiles.ApplyTileColor();

		Board.bTheFirstPieceHasBeenSelected = true;
		_State = EMinigameChessPieceState::Preview;
		ShowSkelMeshHideStaticMesh();
	}

	void PlayerCancelControl(AHazePlayerCharacter Player)
	{
		_State = EMinigameChessPieceState::Inactive;
		AvailableMoveToTiles.ClearHighlights();
		DeactivatePreview(Player);
		ShowStaticMeshHideSkelMesh();

		if(Trajectory != nullptr)
		{
			Board.ReturnTrajectoryDrawer(Trajectory);
			Trajectory = nullptr;
		}
	}

	void PlayerInitializedMovement(AHazePlayerCharacter Player, EChessMinigamePieceMovePosition Position)
	{
		DeactivatePreview(Player);
		_State = EMinigameChessPieceState::PieceMovingToTile;
		ActiveMoveToPosition = Position;
		ActiveMoveTo.InitializeMove(
			GetActorLocation(),
			Board.GetWorldPosition(Position.Tile),
			Collision.GetCapsuleHalfHeight() * 2,
			JumpMove);

		// Update the board
		Board.bHasDefaultSetup = false; // This board needs to reset now	
		Board.EnpassantMove = EChessMinigamePieceMovePosition();
		Board.LastMovedPieceType = Type;
		Board.LastMoveType = Position.MoveType;	
		Board.LastPieceTakenType = EChessMinigamePiece::Unset;
	}

	bool UpdateMoveTo(float DeltaTime)
	{
		// We deactivate the next frame so sound has time to update
		if(!ActiveMoveTo.IsActive())
			return false;


		ActiveMoveTo.ActiveTime = FMath::Min(ActiveMoveTo.ActiveTime + DeltaTime, ActiveMoveTo.Move.TotalAnimationTime);

		// We have landed
		if(ActiveMoveTo.HasLanded())
		{
			if(ActiveMoveToPosition.MoveType == EChessMinigamePieceMoveType::Combat)
			{
				_State = EMinigameChessPieceState::PieceLandOnOtherPiece;
			}
			else
			{
				_State = EMinigameChessPieceState::PieceLandOnEmptyTile;
			}

			SetActorLocation(ActiveMoveTo.TargetLocation);
			ActiveMoveTo.bHasMove = false;
		}
		else
		{
			const float MoveAlpha = ActiveMoveTo.Move.MoveCurve.GetFloatValue(ActiveMoveTo.ActiveTime);
			const float JumpAlpha = ActiveMoveTo.Move.JumpCurve.GetFloatValue(ActiveMoveTo.ActiveTime);

			FVector NewLocation = FMath::Lerp(ActiveMoveTo.StartLocation, ActiveMoveTo.TargetLocation, MoveAlpha);
			NewLocation.Z += FMath::Lerp(0.f, ActiveMoveTo.MaxAirHeight, JumpAlpha);
			SetActorLocation(NewLocation);
		}

		return true;
	}

	void OnMoveFinalized(AHazePlayerCharacter Player, EChessMinigamePieceMovePosition GridPosition)
	{
		if(!GridPosition.IsValid())
			return;

		if(GridPosition.MoveType == EChessMinigamePieceMoveType::Combat 
		&& GridPosition.MoveTypeInstigator != nullptr)
		{
			AMinigameChessPieceBase EnemyPiece = GridPosition.MoveTypeInstigator;
			Board.LastPieceTakenType = EnemyPiece.Type;
			Board.RemovePiece(EnemyPiece);
		}

		SetBoardTile(GridPosition.Tile);
		SetActorLocation(Board.GetWorldPosition(GridPosition.Tile));

		// Effect
		if(LandedEffect != nullptr)
			Niagara::SpawnSystemAtLocation(LandedEffect, GetActorLocation(), GetActorRotation());

		LastMoveType = GridPosition.MoveType;
		LastMoveSubType = GridPosition.SubType;
		FinalizeMoveState(GridPosition);
	}

	void FinalizeMoveState(EChessMinigamePieceMovePosition GridPosition)
	{
		_RemainingAnimationState = _State;
		_State = EMinigameChessPieceState::InactiveAwaitingAnimiationFinish;
		const float RemainInAnimationAfterMoveTime = ActiveMoveTo.GetRemaningTime();
		if(RemainInAnimationAfterMoveTime > 0)
			ActiveAfterMoveToTimer = System::SetTimer(this, n"OnMoveFinalizedInternal", RemainInAnimationAfterMoveTime, false);
		else
			OnMoveFinalizedInternal();
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnMoveFinalizedInternal()
	{
		System::ClearAndInvalidateTimerHandle(ActiveAfterMoveToTimer);
		_State = EMinigameChessPieceState::Inactive;
		_RemainingAnimationState = _State;
		ShowStaticMeshHideSkelMesh();
	}

	void ShowSkelMeshHideStaticMesh()
	{
		Mesh.Activate(true);
		Mesh.SetHiddenInGame(false);
		StaticMesh.Deactivate();
		StaticMesh.SetHiddenInGame(true);
		SetActorTickEnabled(true);
	}

	void ShowStaticMeshHideSkelMesh()
	{
		Mesh.Deactivate();
		Mesh.SetHiddenInGame(true);
		StaticMesh.Activate();
		StaticMesh.SetHiddenInGame(false);
		SetActorTickEnabled(false);
	}

	void GetAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves){}
	
	// We need to make sure that the king is not exposed here
	void FinalizeAvailableMoves(EChessMinigamePieceMovePositionArray& OutMoves)
	{
		// The king validates himself
		ensure(OutMoves.InstigatorPiece.Type != EChessMinigamePiece::King);
		Board.GetKing(bIsBlack).FinalizeAvailableMoves(OutMoves);
	} 

	FChessMinigamePosition GetBoardPosition() const property
	{
		return BoardTile.BoardPosition;
	}

	FChessMinigamePosition GetBoardPreviewPosition() const property
	{
		if(AvailableMoveToTiles.ActiveIndex < 0)
			return BoardTile.BoardPosition;
		else
			return AvailableMoveToTiles.CollectedMoves[AvailableMoveToTiles.ActiveIndex].BoardPosition;
	}

	protected void DeactivatePreview(AHazePlayerCharacter Player)
	{
		auto PreviewComp = UMinigameChessPlayerPreviewComponent::Get(Player);
		if(PreviewComp.PreviewIsActive())
		{	
			PreviewLocation.SetRelativeLocation(FVector::ZeroVector);	
			PreviewComp.DeactivatePreview();
		}

		if(_State != EMinigameChessPieceState::Inactive)
		{
			AvailableMoveToTiles.Reset();
		}
	}

	bool GetBestPreviewMoveIndex(FChessMinigamePosition Wanted, int& OutIndex)const
	{
		const FVector2D CurrentPosition = GetBoardPreviewPosition().ToVector2D();
		const FVector2D InputDir = (Wanted.ToVector2D() - CurrentPosition).GetSafeNormal();
	
		FVector2D ClosestPos = CurrentPosition;
		int ClosestIndex = -1;
		float ClosestDistance = -1;

		for(int i = 0; i < AvailableMoveToTiles.CollectedMoves.Num(); ++i)
		{
			const EChessMinigamePieceMoveType TileMoveType = AvailableMoveToTiles.CollectedMoves[i].MoveType;
			if(TileMoveType == EChessMinigamePieceMoveType::Blocked)
				continue;

			const FVector2D TilePos = AvailableMoveToTiles.CollectedMoves[i].ToVector2D();
			const FVector2D MoveDir = (TilePos - CurrentPosition).GetSafeNormal();
			const float DotP = InputDir.DotProduct(MoveDir);
			if(DotP <= 0.45f)
				continue;

			float Dist = TilePos.DistSquared(CurrentPosition);
			Dist += Dist * (1.f - DotP) * 2;

			if(Dist > FMath::Square(4))
				continue;

			if(ClosestIndex < 0 || Dist < ClosestDistance)
			{
				ClosestPos = TilePos;
				ClosestIndex = i;
				ClosestDistance = Dist;
			}
		}	

		// We have found a new place for the mesh preview to stand on
		if(ClosestIndex < 0)
			return false;

		OutIndex = ClosestIndex;
		return true;
	}

	EChessMinigamePieceMovePosition UpdatePreviewTileMove(AHazePlayerCharacter Player, int BestValidMoveIndex) 
	{
		EChessMinigamePieceMovePosition FoundPosition = AvailableMoveToTiles.CollectedMoves[BestValidMoveIndex];
		AvailableMoveToTiles.ActiveIndex = BestValidMoveIndex;
	
		if(FoundPosition.MoveType == EChessMinigamePieceMoveType::Combat)
		{
			_State = EMinigameChessPieceState::PreviewAttack;
			const FVector WorldPosition = Board.GetWorldPosition(FoundPosition.MoveTypeInstigator.GetBoardTile());
			PreviewLocation.SetWorldLocation(WorldPosition);
		}
		else
		{
			_State = EMinigameChessPieceState::Preview;
			const FVector WorldPosition = Board.GetWorldPosition(FoundPosition.BoardPosition);
			PreviewLocation.SetWorldLocation(WorldPosition);
		}

		//Audio
		UHazeAkComponent::HazePostEventFireForget(Board.MovePreviewTileAudioEvent, FTransform(PreviewLocation.GetWorldLocation()));

		auto PreviewComp = UMinigameChessPlayerPreviewComponent::Get(Player);
		if(FoundPosition.BoardPosition.IsEqual(BoardPosition))
		{
			AvailableMoveToTiles.ActiveIndex = -1;
			PreviewComp.DeactivatePreview();
		}
		else
		{
			PreviewComp.ActivatePreview(this);
		}
		return FoundPosition;
	}

	EMinigameChessPieceState GetState()const property
	{
		return _State;
	}

	EMinigameChessPieceState GetAnimationState()const property
	{
		// The animation can remain a bit longer
		if(_State == EMinigameChessPieceState::InactiveAwaitingAnimiationFinish)
			return _RemainingAnimationState;

		return _State;
	}

	bool IsPreviewing() const
	{
		return _State == EMinigameChessPieceState::Preview || _State == EMinigameChessPieceState::PreviewAttack;
	}

	bool IsMoving() const
	{
		return _State == EMinigameChessPieceState::PieceMovingToTile 
			|| _State == EMinigameChessPieceState::PieceLandOnEmptyTile
			|| _State == EMinigameChessPieceState::PieceLandOnOtherPiece;
	}

	bool IsOppositeTeam(AMinigameChessPieceBase Other) const
	{
		if(Other == nullptr)
			return false;
		else
			return bIsBlack != Other.bIsBlack;
	}

	bool IsKing() const
	{
		return Type == EChessMinigamePiece::King;
	}

	bool IsRook() const
	{
		return Type == EChessMinigamePiece::Rook;
	}

	bool HasMoved()const 
	{ 
		return LastMoveType != EChessMinigamePieceMoveType::Unset || ActiveMoveTo.bHasMove; 
	}
}

UCLASS(Abstract)
class UMinigameChessPlayerPreviewComponent : UStaticMeshComponent
{
	default bGenerateOverlapEvents = false;
	default SetCollisionProfileName(n"NoCollision");
	default SetVisibility(false);

	// Used for showing previews
	UPROPERTY(EditDefaultsOnly, Category = "StaticMesh")
	TMap<EChessMinigamePiece, UStaticMesh> PreviewTypes;

	// The material that will be used on the mesh
	UPROPERTY(EditDefaultsOnly, Category = "StaticMesh")
	UMaterialInstance PreviewMaterial;

	bool PreviewIsActive() const
	{
		return IsVisible();
	}

	void ActivatePreview(AMinigameChessPieceBase PreviewPiece)
	{
		ActivatePreview(PreviewPiece, PreviewPiece.Type);
	}

	void ActivatePreview(AMinigameChessPieceBase PreviewPiece, EChessMinigamePiece TypeToShow)
	{
		AttachToComponent(PreviewPiece.PreviewLocation);

		// Update the preview mesh to match the piece
		UStaticMesh NewMesh = nullptr;
		PreviewTypes.Find(TypeToShow, NewMesh);
		SetStaticMesh(NewMesh);
		SetMaterial(0, PreviewMaterial);
		SetRelativeScale3D(1.f);
		SetVisibility(true);
	}

	void DeactivatePreview()
	{
		AttachToComponent(Owner.RootComponent);
		SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		SetVisibility(false);	
	}
}

class UMinigameChessWorldTextWidget : UHazeUserWidget
{
	UFUNCTION(BlueprintEvent)
	void OnTextChange(FText NewText) {}
}

UCLASS(Abstract)
class AMinigameChessboardGameStarter : ADoubleInteractionActor
{
	AMinigameChessboard Board;

	private AHazePlayerCharacter CurrentWhitePlayer;

	default LeftInteraction.SetRelativeLocation(FVector(-490.f, 280.f, 0.f));
	default RightInteraction.SetRelativeLocationAndRotation(FVector(490.f, 280.f, 0.f), FRotator(0.f, 180.f, 0.f));
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent SwitchModeInteraction;
	default SwitchModeInteraction.RelativeLocation = FVector(0.f, 220.f, 0.f);
	default SwitchModeInteraction.MovementSettings.InitializeNoMovement();

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UWidgetComponent MiddleTextWidgetComponent;
	default MiddleTextWidgetComponent.RelativeLocation = FVector(X=0.f,Y=76.f,Z=221.f);
	default MiddleTextWidgetComponent.RelativeRotation = FRotator(Pitch=30.f,Yaw=90.f,Roll=0.f);

	UPROPERTY()
	EChessMinigameGameTime StartMode = EChessMinigameGameTime::Quick;

	UPROPERTY(EditDefaultsOnly)
	TMap<EChessMinigameGameTime, UTexture> ModeTextures;

	UPROPERTY(EditDefaultsOnly)
	TMap<EChessMinigameGameTime, FText> TextModeRelation;

	UPROPERTY(Category = "Middle Interaction Animations")
	FHazePlaySlotAnimationParams CodyMiddleAnimations;

	UPROPERTY(Category = "Middle Interaction Animations")
	FHazePlaySlotAnimationParams MayMiddleAnimations;

	UPROPERTY(EditConst)
	UMaterialInstanceDynamic DynamicMaterial;

	bool bHasBlockedInteraction = false;
	bool bIsEnglish = true;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript() override
	{
		Super::ConstructionScript();

		OnDoubleInteractionCompleted.AddUFunction(this, n"OnStartGameWithTutorial");
		OnLeftInteractionReady.AddUFunction(this, n"OnWhitePlayerEntered");
		OnRightInteractionReady.AddUFunction(this, n"OnBlackPlayerEntered");
		SwitchModeInteraction.OnActivated.AddUFunction(this, n"OnSwitchModeUsed");
		DynamicMaterial = Mesh.CreateDynamicMaterialInstance(0);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		FString Lang = Internationalization::GetCurrentLanguage();
		bIsEnglish = (Lang == "en") || (Lang == "en-US") || (Lang == "en-GB");
		//bIsEnglish = !bIsEnglish;
		if(bIsEnglish)
		{
			MiddleTextWidgetComponent.SetVisibility(false);
			if(DynamicMaterial != nullptr)
			{
				DynamicMaterial.SetTextureParameterValue(n"M4", ModeTextures.FindOrAdd(StartMode));
			}
		}
		else
		{
			MiddleTextWidgetComponent.SetVisibility(true);
			SetPendingStartMode(StartMode);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnWhitePlayerEntered(AHazePlayerCharacter Player)
	{
		CurrentWhitePlayer = Player;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnBlackPlayerEntered(AHazePlayerCharacter Player)
	{

	}

	UFUNCTION(NotBlueprintCallable)
	private void OnSwitchModeUsed(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		FHazeAnimationDelegate OnBlendedIn, OnBlendedOut;
		if(Player.IsCody())
		{
			Player.PlayEventAnimation(OnBlendedIn, OnBlendedOut, CodyMiddleAnimations);
		}	
		else
		{
			Player.PlayEventAnimation(OnBlendedIn, OnBlendedOut, MayMiddleAnimations);
		}

		if(StartMode == EChessMinigameGameTime::Quick)
		{
			SetPendingStartMode(EChessMinigameGameTime::Long);
			Player.PlayerHazeAkComp.HazePostEvent(Board.ButtonAudioEvent);
		}
		else if(StartMode == EChessMinigameGameTime::Long)
		{
			SetPendingStartMode(EChessMinigameGameTime::Infinite);
			Player.PlayerHazeAkComp.HazePostEvent(Board.ButtonAudioEvent);
		}
		else
		{
			SetPendingStartMode(EChessMinigameGameTime::Quick);
			Player.PlayerHazeAkComp.HazePostEvent(Board.ButtonAudioEvent);
		}
	}

	private void SetPendingStartMode(EChessMinigameGameTime Mode)
	{
		StartMode = Mode;
		if(bIsEnglish)
		{
			if(DynamicMaterial != nullptr)
			{
				DynamicMaterial.SetTextureParameterValue(n"M4", ModeTextures.FindOrAdd(StartMode));
			}
		}
		else
		{
			// If its not english, we use a text widget instead for localization
			FText NewText = TextModeRelation[StartMode];	
			UMinigameChessWorldTextWidget TextWidget = Cast<UMinigameChessWorldTextWidget>(MiddleTextWidgetComponent.GetWidget());
			TextWidget.OnTextChange(TextModeRelation[StartMode]);
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void OnStartGameWithTutorial()
    {
        Board.PrepareGame(CurrentWhitePlayer, StartMode);
    }
}


UCLASS(Abstract)
class AMinigameChessboardGameEnder : ADoubleInteractionActor
{
	AMinigameChessboard Board;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TextMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CleanMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UWidgetComponent MiddleTextWidgetComponent;
	default MiddleTextWidgetComponent.RelativeLocation = FVector(X=0.f,Y=76.f,Z=221.f);
	default MiddleTextWidgetComponent.RelativeRotation = FRotator(Pitch=30.f,Yaw=90.f,Roll=0.f);

	UPROPERTY(EditDefaultsOnly)
	FText DrawText;

	bool bIsEnglish = true;

	default LeftInteraction.SetRelativeLocation(FVector(-490.f, 280.f, 0.f));
	default RightInteraction.SetRelativeLocationAndRotation(FVector(490.f, 280.f, 0.f), FRotator(0.f, 180.f, 0.f));

	UFUNCTION(BlueprintOverride)
    void ConstructionScript() override
	{
		Super::ConstructionScript();
		OnDoubleInteractionCompleted.AddUFunction(this, n"OnEndGame");
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay() override
	{
		Super::BeginPlay();
		FString Lang = Internationalization::GetCurrentLanguage();
		bIsEnglish = (Lang == "en") || (Lang == "en-US") || (Lang == "en-GB");
		//bIsEnglish = !bIsEnglish;
		if(bIsEnglish)
		{
			MiddleTextWidgetComponent.SetVisibility(false);
			CleanMesh.SetVisibility(false);
			TextMesh.SetVisibility(true);
		}
		else
		{		
			MiddleTextWidgetComponent.SetVisibility(true);
			UMinigameChessWorldTextWidget TextWidget = Cast<UMinigameChessWorldTextWidget>(MiddleTextWidgetComponent.GetWidget());
			TextWidget.OnTextChange(DrawText);
			CleanMesh.SetVisibility(true);
			TextMesh.SetVisibility(false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
    void OnEndGame()
    {
		auto Player = Game::GetMay();
		if(!Board.ImActivePlayer(Player))
			Player = Player.GetOtherPlayer();
		Board.EndGameWithPlayerAsWinner(Player, nullptr);
    }
}

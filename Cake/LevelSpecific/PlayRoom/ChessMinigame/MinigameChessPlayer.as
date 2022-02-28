import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChess;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Trajectory.TrajectoryStatics;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessPiece_King;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessMoveTo;
import Cake.LevelSpecific.PlayRoom.ChessMinigame.MinigameChessPlayer_Animation;
import Vino.Tutorial.TutorialStatics;

void AddChessBoardToPlayer(AHazePlayerCharacter Player, AMinigameChessboard Board)
{
	UMinigameChessPlayerComponent::Get(Player).ChessBoard = Board;
}

void SetActiveChessPiece(AHazePlayerCharacter Player, AMinigameChessPieceBase Piece)
{
	auto ChessComp = UMinigameChessPlayerComponent::Get(Player);
	ChessComp.ActivePiece = Piece;
}

UCLASS(Abstract)
class UMinigameChessPlayerAnimInstance : UHazeFeatureSubAnimInstance
{
	UPROPERTY(BlueprintReadOnly)
	EMinigameChessPlayerState ChessState;

	UPROPERTY(BlueprintReadOnly)
	bool bPreviewAttacking = false;

	UMinigameChessPlayerComponent ChessComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		auto PlayerOwner = Cast<AHazePlayerCharacter>(GetOwningActor());
		if(PlayerOwner == nullptr)
			return;

		ChessComp = UMinigameChessPlayerComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(ChessComp == nullptr)
			return;
		
		ChessState = ChessComp.State;
		if(ChessComp.ActivePiece != nullptr && ChessComp.ActivePiece.State == EMinigameChessPieceState::PreviewAttack)
			bPreviewAttacking = true;
		else
			bPreviewAttacking = false;
	}
}

enum EMinigameChessPlayerState
{
    Inactive,
    Preview,
    PieceMoving,
	SwapPawnToAnotherPiece,
    Taunting,
}

UCLASS(Abstract)
class UMinigameChessPlayerComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Animations")
	ULocomotionFeatureMinigameChessPlayer Animations;

	UPROPERTY(EditDefaultsOnly, Category = "Effects")
	UNiagaraSystem MovePieceEffect;

	AMinigameChessboard ChessBoard;
	AMinigameChessPieceBase ActivePiece;
	private bool bIsTaunting = false;
	
	void SetTauntEnable(bool bStatus)
	{
		bIsTaunting = bStatus;
	}

	AMinigameChessPieceKing GetTheKing()
	{
		return Cast<AMinigameChessPieceKing>(ChessBoard.GetKing(Cast<AHazePlayerCharacter>(Owner)));
	}

	void AddLocomotionFeature()
	{
		Cast<AHazePlayerCharacter>(Owner).AddLocomotionFeature(Animations);
	}

	void RemoveLocomotionFeature()
	{
		Cast<AHazePlayerCharacter>(Owner).RemoveLocomotionFeature(Animations);
	}

	EMinigameChessPlayerState GetState()const property
	{	
		if(bIsTaunting)
			return EMinigameChessPlayerState::Taunting;
		else if(ActivePiece == nullptr)
			return EMinigameChessPlayerState::Inactive;
		else if(ActivePiece.IsPreviewing())
			return EMinigameChessPlayerState::Preview;
		else if(ActivePiece.IsMoving())
			return EMinigameChessPlayerState::PieceMoving;
		else if(ActivePiece.State == EMinigameChessPieceState::PieceLandedOnSwapPieceTile)
			return EMinigameChessPlayerState::SwapPawnToAnotherPiece;
		else
			return EMinigameChessPlayerState::Inactive;
	}
}

class MinigameChessPlayerMovePieceCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Chess");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	const float TimeToFocus = 0.3f;

	UMinigameChessPlayerComponent ChessComp;
	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MoveComp;
	UMinigameChessPlayerPreviewComponent PreviewMesh;
	
	FChessMinigamePosition PiecePosition;
	bool bHasMadeInput = false;
	EChessMinigamePieceMovePosition PreviewPosition;

	//float TimeLeftToFocus = 0.f;
	//FRotator StartDesiredRotation;
	USceneComponent OriginalAttachment;
	
	int PreviewAnimationIndex = 0;
	float LastPreviewAnimationUpdateTime = 0;
	FVector DirToAttack;
	FVector LastWorldLocation;
	int ReplicatedValidMoveIndex = -1;
	bool bSwapPlayerAtEnd = false;
	bool bStartTaunt = false;
	bool bApplyPieceMove = false;
	bool bPlayerIsAttached = false;

	bool bIsSwappingPiece = false;
	TArray<EChessMinigamePiece> SwapableTypes;
	default SwapableTypes.Add(EChessMinigamePiece::Rook);
	default SwapableTypes.Add(EChessMinigamePiece::Bishop);
	default SwapableTypes.Add(EChessMinigamePiece::Knight);
	default SwapableTypes.Add(EChessMinigamePiece::Queen);
	int CurrentSwapToIndex = -1;

	bool bShowMoveTutorial = true;
	bool bShowingActionTutorial = false;

	bool bWaitingForActivationFullSync = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ChessComp = UMinigameChessPlayerComponent::Get(Owner);
		OriginalAttachment = PlayerOwner.Mesh.GetAttachParent();
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
		PreviewMesh = UMinigameChessPlayerPreviewComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
    void OnRemoved()
    {
        ChessComp.RemoveLocomotionFeature();
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ChessComp.ActivePiece == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ChessComp.ActivePiece == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(WasActionStarted(ActionNames::Cancel) && !bWaitingForActivationFullSync && HasControl())
		{
			if(ChessComp.State == EMinigameChessPlayerState::Preview)
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}

		if(ChessComp.State == EMinigameChessPlayerState::Inactive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bWaitingForActivationFullSync = true;
		ChessComp.SetTauntEnable(false);
		PlayerOwner.TriggerMovementTransition(this);
		PlayerOwner.BlockMovementSyncronization(this);

		PlayerOwner.BlockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.BlockCapabilities(CapabilityTags::Collision, this);
		ChessComp.AddLocomotionFeature();
	
		ChessComp.ChessBoard.BlockTeamForPlayer(PlayerOwner);
		ChessComp.ActivePiece.PlayerTakeControl();
		LastWorldLocation = ChessComp.ActivePiece.PreviewLocation.GetWorldLocation();

		//StartDesiredRotation = UCameraUserComponent::Get(PlayerOwner).GetDesiredRotation();
		//TimeLeftToFocus = TimeToFocus;

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.f;
		PlayerOwner.ApplyCameraSettings(ChessComp.ChessBoard.ActiveUserCameraSettings, Blend, this, EHazeCameraPriority::High);

		bHasMadeInput = false;
		PreviewPosition = EChessMinigamePieceMovePosition(ChessComp.ActivePiece.BoardTile, EChessMinigamePieceMoveType::Current);
		ReplicatedValidMoveIndex = -1;
		ActivateAttachment();

		Sync::FullSyncPoint(this, n"InteractionActivation");

		if(bShowMoveTutorial)
			ShowTutorialPrompt(PlayerOwner, ChessComp.ChessBoard.MovePieceTutorial, this);

		ShowCancelPrompt(PlayerOwner, this);
	}

	UFUNCTION(NotBlueprintCallable)
    void InteractionActivation()
    {
        bWaitingForActivationFullSync = false;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(ChessComp.ActivePiece != nullptr)
		{	
			ClearPlayerAttachment();
			if(!bSwapPlayerAtEnd)
				ChessComp.ActivePiece.PlayerCancelControl(PlayerOwner);
		
			ChessComp.ActivePiece = nullptr;
		}

		PlayerOwner.ClearCameraSettingsByInstigator(this, 2.f);
		ChessComp.ChessBoard.UnblockTeamForPlayer(PlayerOwner);
		PlayerOwner.UnblockMovementSyncronization(this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Movement, this);
		PlayerOwner.UnblockCapabilities(CapabilityTags::Collision, this);
		PreviewPosition = EChessMinigamePieceMovePosition(nullptr, EChessMinigamePieceMoveType::Unset);
		bIsSwappingPiece = false;

		if(bStartTaunt)
		{
			bStartTaunt = false;
			ChessComp.SetTauntEnable(true);
		}

		if(bSwapPlayerAtEnd)
		{
			bSwapPlayerAtEnd = false;
			ChessComp.ChessBoard.SetActivePlayer(PlayerOwner.GetOtherPlayer());
		}
		
		bShowingActionTutorial = false;
		RemoveTutorialPromptByInstigator(PlayerOwner, this);
		RemoveCancelPromptByInstigator(PlayerOwner, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bWaitingForActivationFullSync)
		{
			// Update player animation
			RequestAnimation();
			return;
		}	

		// We are in an active state
		if(ChessComp.State == EMinigameChessPlayerState::SwapPawnToAnotherPiece)
		{
			// A pawn as reached the end of the board and can be swapped to another piece
			UpdateSwapPiece(DeltaTime);

			// Update player animation
			RequestAnimation();
			return;
		}
		else if(ChessComp.State != EMinigameChessPlayerState::Preview)
		{
			// We update the piece current moveto position type
			UpdatePieceMoveTo(DeltaTime);
	
			// Update player animation
			RequestAnimation();
			return;
		}

		// if(TimeLeftToFocus > 0)
		// {
		// 	TimeLeftToFocus = FMath::Max(TimeLeftToFocus - DeltaTime, 0.f);
		// 	const float Alpha = 1 - (TimeLeftToFocus / TimeToFocus);
			
		// 	FRotator CameraRotation = ChessComp.ActivePiece.GetCameraFacingRotation(StartDesiredRotation);
		// 	UCameraUserComponent::Get(PlayerOwner).SetDesiredRotation(FMath::LerpShortestPath(StartDesiredRotation, CameraRotation, Alpha));
		// }

		// This will update the 'ReplicatedValidMoveIndex' on both sides
		UpdateControlStickInput();
		if(ReplicatedValidMoveIndex >= 0)
		{
			PreviewPosition = ChessComp.ActivePiece.UpdatePreviewTileMove(PlayerOwner, ReplicatedValidMoveIndex);
			LastPreviewAnimationUpdateTime = Time::GetGameTimeSeconds();
			DirToAttack = (ChessComp.ActivePiece.PreviewLocation.GetWorldLocation() - LastWorldLocation).GetSafeNormal();
			LastWorldLocation = ChessComp.ActivePiece.PreviewLocation.GetWorldLocation();
			LastPreviewAnimationUpdateTime = 0;
			PreviewAnimationIndex = 9999;
			ReplicatedValidMoveIndex = -1;
		}

		auto MyKing = ChessComp.GetTheKing();

		//Update the exposed grafics
		TArray<AMinigameChessPieceBase> PotentialAttackers;
		const bool bKingIsExposed = MyKing.IsExposedAt(PreviewPosition, PotentialAttackers);
		if(bKingIsExposed)
		{
			const FVector To = ChessComp.ChessBoard.GetWorldPosition(MyKing.GetBoardPreviewPosition());
			for(auto Attacker : PotentialAttackers)
			{
				Attacker.DrawTrajectory(PlayerOwner, MyKing);
			}
		}

		const bool bShouldShowActionTutorial = !(PreviewPosition.MoveType == EChessMinigamePieceMoveType::Current || bKingIsExposed || !PreviewPosition.CanApplyPieceMove(ChessComp.ActivePiece.GetBoardPosition()));
		if(!bShouldShowActionTutorial && bShowingActionTutorial)
		{
			bShowingActionTutorial = false;
			RemoveTutorialPromptByInstigator(PlayerOwner, this);
		}
		else if(bShouldShowActionTutorial && !bShowingActionTutorial)
		{
			bShowingActionTutorial = true;
			ShowTutorialPrompt(PlayerOwner, ChessComp.ChessBoard.ApplyPieceMoveTutorial, this);
		}

		// This will update the preview attack animation for the current PiecePosition
		// Might be nice to replace this with a nicer animation
		UpdatePreviewAnimation(DeltaTime);

		// This will update the players action input to see if we place the piece on a new location
		UpdateControlActionInput(bKingIsExposed);
		
		// Stored through network
		if(bApplyPieceMove)
		{
			bApplyPieceMove = false;
			ClearPlayerAttachment();

			if(ChessComp.MovePieceEffect != nullptr)
				Niagara::SpawnSystemAtLocation(ChessComp.MovePieceEffect, ChessComp.ActivePiece.GetActorLocation(), ChessComp.ActivePiece.GetActorRotation());
			
			// Move the chess piece to the position
			ChessComp.ActivePiece.PlayerInitializedMovement(PlayerOwner, PreviewPosition);

			RemoveTutorialPromptByInstigator(PlayerOwner, this);
			RemoveCancelPromptByInstigator(PlayerOwner, this);
		}

		// Update player animation
		RequestAnimation();
	}

	void ActivateAttachment()
	{
		bPlayerIsAttached = true;
		PlayerOwner.AttachRootComponentTo(ChessComp.ActivePiece.PreviewLocation, NAME_None, EAttachLocation::SnapToTarget);
		PlayerOwner.Mesh.AttachToComponent(ChessComp.ActivePiece.Root);
		PlayerOwner.Mesh.SetRelativeLocation(FVector(-(ChessComp.ActivePiece.Collision.CapsuleRadius + 20), 0.f, 0.f));
	}

	void ClearPlayerAttachment()
	{
		if(bPlayerIsAttached)
		{
			bPlayerIsAttached = false;
			const FVector PlayerPositionToSet = PlayerOwner.Mesh.GetWorldLocation();
			PlayerOwner.Mesh.AttachToComponent(OriginalAttachment);
			PlayerOwner.DetachRootComponentFromParent();
			PlayerOwner.SetActorLocation(PlayerPositionToSet);
		}	
	}

	void UpdatePieceMoveTo(float DeltaTime)
	{
		if(!ChessComp.ActivePiece.UpdateMoveTo(DeltaTime))
		{
			// When the animation is done, we handle what type of move we did
			bStartTaunt = ChessComp.ActivePiece.State == EMinigameChessPieceState::PieceLandOnOtherPiece;
			ChessComp.ChessBoard.FinalizePieceMove(PlayerOwner, ChessComp.ActivePiece);
		}
	}

	void UpdateSwapPiece(float DeltaTime)
	{
		if(!HasControl())
			return;

		if(!bIsSwappingPiece)
		{
			ChessComp.ActivePiece.Mesh.SetVisibility(false);
			NetSetSwapIndex(SwapableTypes.Num() - 1);
		}

		const float Input = GetAttributeVector(AttributeVectorNames::LeftStickRaw).X;
		const bool bHasValidInput = FMath::Abs(Input) > 0.5f;
		if(bHasMadeInput && !bHasValidInput)
		{
			bHasMadeInput = false;
		}
		else if(!bHasMadeInput && bHasValidInput)
		{
			if(Input > 0.5f)
				CurrentSwapToIndex++;
			else if(Input < -0.5f)
				CurrentSwapToIndex--;

			if(CurrentSwapToIndex < 0)
				CurrentSwapToIndex = SwapableTypes.Num() - 1;
			else if(CurrentSwapToIndex >= SwapableTypes.Num())
				CurrentSwapToIndex = 0;

			bHasMadeInput = true;
			NetSetSwapIndex(CurrentSwapToIndex);
		}	

		if(WasActionStarted(ActionNames::MinigameBottom))
		{	
			NetSwapPawn();
		}
	}

	UFUNCTION(NetFunction)
	void NetSetSwapIndex(int NewIndex)
	{
		if(!bIsSwappingPiece)
		{
			bIsSwappingPiece = true;
			ShowTutorialPrompt(PlayerOwner, ChessComp.ChessBoard.SwapPieceTutorial, this);
			ShowTutorialPrompt(PlayerOwner, ChessComp.ChessBoard.ApplyPieceMoveTutorial, this);
		}

		// PLAY SOUND
		UHazeAkComponent::HazePostEventFireForget(ChessComp.ChessBoard.ChoosePieceAudioEvent, PreviewMesh.GetWorldTransform());

		
		CurrentSwapToIndex = NewIndex;
		PreviewMesh.ActivatePreview(ChessComp.ActivePiece, SwapableTypes[CurrentSwapToIndex]);
	}

	UFUNCTION(NetFunction)
	void NetSwapPawn()
	{
		// PLAY SOUND
		UHazeAkComponent::HazePostEventFireForget(ChessComp.ChessBoard.SummonPieceAudioEvent, PreviewMesh.GetWorldTransform());
		
		ChessComp.ChessBoard.SwapPiece(PlayerOwner, ChessComp.ActivePiece, SwapableTypes[CurrentSwapToIndex]);
		PreviewMesh.DeactivatePreview();	
	}

	void RequestAnimation()
	{
		if(PlayerOwner.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData AnimationRequest;
			AnimationRequest.AnimationTag = n"Chess";
			PlayerOwner.RequestLocomotion(AnimationRequest);
		}
	}

	void UpdateControlStickInput()
	{
		if(!HasControl())
			return;

		const FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

		const FVector Forward = ChessComp.ChessBoard.GetActorForwardVector();
		const FVector Right = ChessComp.ChessBoard.GetActorRightVector();
		const FVector2D InputAngle = FVector2D(Right.DotProduct(Input.GetSafeNormal()), Forward.DotProduct(Input.GetSafeNormal()));

		const FChessMinigamePosition CurrentPiecePosition = ChessComp.ActivePiece.GetBoardPreviewPosition();
		const FChessMinigamePosition WantedPreviewPosition = CurrentPiecePosition.OffsetWith(FMath::RoundToInt(InputAngle.X), FMath::RoundToInt(InputAngle.Y));
		
		// Update the preview mesh and make sure we only update once every stick input
		bool bValidInput = false;
		if(!bHasMadeInput && Input.SizeSquared() > 0.7f)
		{
			bHasMadeInput = true;	
			if(WantedPreviewPosition.IsValid() && !WantedPreviewPosition.IsEqual(CurrentPiecePosition))
			{
				int FoundIndex = -1;
				if(ChessComp.ActivePiece.GetBestPreviewMoveIndex(WantedPreviewPosition, FoundIndex))
				{
					// We found a valid move so we send that to both sides
					// This will update the 'ReplicatedValidMoveIndex' so we can use that
					NetUpdatePreviewTile(FoundIndex);
				}
			}
		}
		else if(bHasMadeInput && Input.SizeSquared() <= 0.4f)
		{
			bHasMadeInput = false;
		}
	}

	void UpdateControlActionInput(const bool bKingIsExposed)
	{
		if(!HasControl())
			return;

		// Try to activate position
		if(WasActionStarted(ActionNames::MovementJump))
		{	
			const bool bInvalidInput = bKingIsExposed || !PreviewPosition.CanApplyPieceMove(ChessComp.ActivePiece.GetBoardPosition());
			NetHandleActionInput(!bInvalidInput);
		}
	}

	UFUNCTION(NetFunction)
	void NetHandleActionInput(bool bIsValid)
	{
		if(bIsValid)
		{
			bApplyPieceMove = true;
			bSwapPlayerAtEnd = true;
		}
		else
		{
			// TODO, play error sound
		}
	}

	UFUNCTION(NetFunction)
	void NetUpdatePreviewTile(int ValidMoveIndex)
	{
		ReplicatedValidMoveIndex = ValidMoveIndex;
		if(bShowMoveTutorial)
		{
			bShowMoveTutorial = false;
			RemoveTutorialPromptByInstigator(PlayerOwner, this);
		}

	}

	void UpdatePreviewAnimation(float DeltaTime)
	{
		if(ChessComp.ActivePiece.State != EMinigameChessPieceState::PreviewAttack)
		{
			PreviewMesh.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
			return;
		}
			
		if(Time::GetGameTimeSeconds() <= LastPreviewAnimationUpdateTime)
			return;


		// PLAY SOUND (attack animation update)
		UHazeAkComponent::HazePostEventFireForget(ChessComp.ChessBoard.AttackPreviewAudioEvent, PreviewMesh.GetWorldTransform());

		PreviewMesh.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
		LastPreviewAnimationUpdateTime = Time::GetGameTimeSeconds() + 0.5f;
		PreviewAnimationIndex++;
		if(PreviewAnimationIndex >= 2)
			PreviewAnimationIndex = 0;

		if(PreviewAnimationIndex == 1)
		{	
			FQuat AttackRotation = (DirToAttack).ToOrientationQuat();
			AttackRotation *= FRotator(15.f, 0.f, 0.f).Quaternion();
			PreviewMesh.SetWorldRotation(AttackRotation);

			FVector NewPosition = PreviewMesh.GetWorldLocation();
			NewPosition -= DirToAttack * (ChessComp.ActivePiece.Collision.CapsuleRadius * 1);
			NewPosition.Z += 100;
			NewPosition += PreviewMesh.GetWorldRotation().UpVector * 100;
			PreviewMesh.SetWorldLocation(NewPosition);
		}
		else
		{
			FQuat AttackRotation = (DirToAttack).ToOrientationQuat();
			AttackRotation *= FRotator(15.f, 0.f, 0.f).Quaternion();
			PreviewMesh.SetWorldRotation(AttackRotation);

			FVector NewPosition = PreviewMesh.GetWorldLocation();
			NewPosition -= DirToAttack * (ChessComp.ActivePiece.Collision.CapsuleRadius * 1);
			NewPosition.Z += 100;
			PreviewMesh.SetWorldLocation(NewPosition);
		}	
	}

}

/** This capability will update the time and eventually finish the game */
class MinigameChessPlayerTimerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Chess");

	UMinigameChessPlayerComponent ChessComp;
	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ChessComp = UMinigameChessPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!ChessComp.ChessBoard.ImActivePlayer(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;
	
		if(ChessComp.State != EMinigameChessPlayerState::Preview
			&& ChessComp.State != EMinigameChessPlayerState::Inactive)
			return EHazeNetworkActivation::DontActivate;

		if(!ChessComp.ChessBoard.bTheFirstPieceHasBeenSelected)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!ChessComp.ChessBoard.ImActivePlayer(PlayerOwner))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ChessComp.State != EMinigameChessPlayerState::Preview
			&& ChessComp.State != EMinigameChessPlayerState::Inactive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurrentTeamTime = ChessComp.ChessBoard.GetTeamTimeLeft(PlayerOwner);
		if(CurrentTeamTime > 0)
		{
			CurrentTeamTime = FMath::Max(CurrentTeamTime - DeltaTime, 0.f);
			ChessComp.ChessBoard.SetTeamTime(PlayerOwner, CurrentTeamTime);
			if(CurrentTeamTime <= 0.f)
			{
				ChessComp.ChessBoard.EndGameWithPlayerAsWinner(PlayerOwner, PlayerOwner.GetOtherPlayer());
			}
		}
	}
}

class MinigameChessPlayerAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Chess");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 110;

	UMinigameChessPlayerComponent ChessComp;
	AHazePlayerCharacter PlayerOwner;
	UHazeMovementComponent MoveComp;
	bool bControlHasMoved = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		ChessComp = UMinigameChessPlayerComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(ChessComp.ChessBoard.ImActivePlayer(PlayerOwner))
			return EHazeNetworkActivation::DontActivate;

		if(!PlayerOwner.Mesh.CanRequestLocomotion())
			return EHazeNetworkActivation::DontActivate;

		if(ChessComp.State != EMinigameChessPlayerState::Taunting)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ChessComp.ChessBoard.ImActivePlayer(PlayerOwner))
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!PlayerOwner.Mesh.CanRequestLocomotion())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(ChessComp.State != EMinigameChessPlayerState::Taunting)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bControlHasMoved = false;
		ChessComp.SetTauntEnable(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// We will contiune to request the chess movement
		MoveComp.SetAnimationToBeRequested(n"Chess");

		if(HasControl())
		{
			if(GetAttributeVector(AttributeVectorNames::MovementDirection).Size() > 0.5f)
				NetSetControlHasMoved();
		}
			
		if(bControlHasMoved)
		{
			bControlHasMoved = false;
			ChessComp.RemoveLocomotionFeature();
			PlayerOwner.RemoveLocomotionFeature(ChessComp.Animations);
			ChessComp.SetTauntEnable(false);
		}
	}

	UFUNCTION(NetFunction)
	void NetSetControlHasMoved()
	{
		bControlHasMoved = true;
	}
}
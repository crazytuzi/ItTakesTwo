import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarManagerComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarPlayerComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarVisualizerComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarDeviceRope;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.TugOfWar.TugOfWarDeviceWheel;
import Vino.Checkpoints.Checkpoint;
import Vino.MinigameScore.MinigameComp;

event void FOnLeftTugOfWarReadyEventSignature(AHazePlayerCharacter Player);
event void FOnRightTugOfWarReadyEventSignature(AHazePlayerCharacter Player);
event void FOnTriggerTugOfWarSequenceEventSignature(bool MayWon);

class ATugOfWarActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkCompCogsLeftSide;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkCompCogsRightSide;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkCompCogsRope;

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::TugofWar;

	UPlayerHazeAkComponent PlayerHazeAkComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent LeftInteraction;
	default LeftInteraction.RelativeLocation = FVector(0, -750, 0);
	default LeftInteraction.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent RightInteraction;
	default RightInteraction.RelativeLocation = FVector(0, 750, 0);
	default RightInteraction.MovementSettings.InitializeSmoothTeleport();

	UPROPERTY(DefaultComponent, Attach = LeftInteraction)
	USceneComponent LeftAttachPoint;
	default LeftAttachPoint.RelativeLocation = FVector(0, 0, -50);

	UPROPERTY(DefaultComponent, Attach = LeftAttachPoint)
	USceneComponent LeftButtonMashPosition;
	default LeftButtonMashPosition.RelativeLocation = FVector(0,0,250.f);

	UPROPERTY(DefaultComponent, Attach = RightInteraction)
	USceneComponent RightAttachPoint;
	default RightAttachPoint.RelativeLocation = FVector(0, 0, -50);

	UPROPERTY(DefaultComponent, Attach = RightAttachPoint)
	USceneComponent RightButtonMashPosition;
	default RightButtonMashPosition.RelativeLocation = FVector(0,0,250.f);

	UPROPERTY(DefaultComponent, Attach = RopeStartPoint)
	UStaticMeshComponent RopeMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RopeStartPoint;
	default RopeStartPoint.RelativeLocation = FVector(0,0,20);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RopeEndPoint;
	default RopeEndPoint.RelativeLocation = FVector(0,0,20);

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UTugOfWarManagerComponent ManagerComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 5200.f;

	UPROPERTY(Category = "Setup")
	AHazeCameraActor NeutralCamera;

	UPROPERTY(Category = "Setup")
	AHazeCameraActor CodyCamera;

	UPROPERTY(Category = "Setup")
	AHazeCameraActor MayCamera;

	AHazeCameraActor ActiveCamera;

	UPROPERTY(Category = "Double Interact")
	bool bShowCancelPrompt = false;

	UPROPERTY(Category = "Animation Settings")
	bool bPlayExitAnimationOnCompleted = false;

	UPROPERTY(Category = "Double Interact")
	TSubclassOf<UHazeCapability> AnimationCapability;

	UPROPERTY(Category = "Double Interact")
	TSubclassOf<UHazeCapability> ButtonMashCapability;

	UPROPERTY(Category = "Double Interact")
	TSubclassOf<UHazeCapability> CancelCapability;

	//Called when first player interacts with Rope (Unsure which AK Comp to post from, should be posted in OnInteractionUsed() for left/right respectively)
	// UPROPERTY(Category = "Audio Events")
	// UAkAudioEvent FirstPlayerGrabbedRopeAudioEvent;

	//Called When no more players interacting with RopeEndPoint (Unsure which AK Component to post from, should be posted in CancelInteraction() function)
	//For minigame Ended Use Events on Sequence in SideContent_BP
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent NoPlayersGrabbingRopeAudioEvent;

	// UPROPERTY(Category = "Audio Events")
	// UAkAudioEvent BothPlayersOnRopeAudioEvent;

	//Called when May Interacts with Actor
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayGrabRopeAudioEvent;

	//Called when Cody interacts with Actor
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyGrabRopeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePlayerInteractLeftCogsAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePlayerInteractRightCogsAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePlayerInteractRopeAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLeftCogsLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopRightCogsLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartSqueakyRopeLoopAudioEvent;

	UPROPERTY()
	FOnLeftTugOfWarReadyEventSignature OnLeftInteractionReady;
	UPROPERTY()
	FOnRightTugOfWarReadyEventSignature OnRightInteractionReady;
	UPROPERTY()
	FOnTriggerTugOfWarSequenceEventSignature OnTriggerTugOfWarSequence;

	AHazePlayerCharacter LeftPlayer;
	AHazePlayerCharacter RightPlayer;

	UTugOfWarPlayerComponent Player1Component;
	UTugOfWarPlayerComponent Player2Component;

	UPROPERTY(Category = "Setup")
	TArray<ATugOfWarDeviceRope> TilingRopes;

	UPROPERTY(Category = "Settings")
	float Tiling = 4.f;
	UPROPERTY(Category = "Settings")
	float InteractionWidth = 1555.f;

	private TPerPlayer<bool> ReadyForComplete;
	private TPerPlayer<UInteractionComponent> ActiveInteractions;
	private bool bWaitingForComplete = false;
	bool bInteractionMoveInProgress = false;
	bool bBothPlayersInteracting = false;

	bool bSwitchSyncFloats = false;
	bool bAnyPlayerOnTheRope = false;

	FTimerHandle PendingStartBarkTimerHandle;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftPlayerSyncMashRate;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightPlayerSyncMashRate;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftPlayerSyncMashRate2;
	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightPlayerSyncMashRate2;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ManagerComp.LeftAttach = LeftAttachPoint;
		ManagerComp.RightAttach = RightAttachPoint;

		float Distance = InteractionWidth / 2;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		/* Set AkComp References in manager */
		ManagerComp.HazeAkCompCogsLeftSide = HazeAkCompCogsLeftSide;
		ManagerComp.HazeAkCompCogsRightSide = HazeAkCompCogsRightSide;
		ManagerComp.HazeAkCompRope = HazeAkCompCogsRope;

		LeftInteraction.OnActivated.AddUFunction(this, n"OnInteractionUsed");

		RightInteraction.OnActivated.AddUFunction(this, n"OnInteractionUsed");

		DoubleInteract.OnTriggered.AddUFunction(this, n"ShowTutorial");
		ManagerComp.OnCompleted.AddUFunction(this, n"CompleteInteraction");
		ManagerComp.OnStateChange.AddUFunction(this, n"OnStateChange");
		ManagerComp.OnMoveStarted.AddUFunction(this, n"OnInteractionMove");

		if(HasControl())
		{
			ManagerComp.OnMoveCompleted.AddUFunction(this, n"OnInteractionMoveCompleted");
		}

		ManagerComp.LeftAttach = LeftAttachPoint;
		ManagerComp.RightAttach = RightAttachPoint;

		ManagerComp.RopeMaterials.Add(RopeMesh.CreateDynamicMaterialInstance(0));
		
		SetupRopeMaterials();
		ManagerComp.InitializeVariables();

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"OnTutorialCompleted");

		if(HasControl())
			MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"OnCountdownFinished");

		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"OnVictoryAnimationFinished");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"TutorialCancelled");
	}

	void SetupRopeMaterials()
	{
		ManagerComp.RopeMaterials.Add(RopeMesh.CreateDynamicMaterialInstance(0));

		for(int i = 0; i < TilingRopes.Num(); i++)
		{
			ManagerComp.RopeMaterials.Add(TilingRopes[i].Mesh.CreateDynamicMaterialInstance(0));
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	void HandlePlayer1Input(AHazePlayerCharacter Player, float MashRate)
	{
		if(bInteractionMoveInProgress)
			return;
		
		if(!bSwitchSyncFloats)
		{
			if(LeftPlayer != nullptr && LeftPlayer.HasControl())
			{
				LeftPlayerSyncMashRate.Value = MashRate;
				ManagerComp.Player1MashRate = MashRate;
			}
			else if(LeftPlayer != nullptr && !LeftPlayer.HasControl())
				ManagerComp.Player1MashRate = LeftPlayerSyncMashRate.Value;
		}
		else
		{
			if(LeftPlayer != nullptr && LeftPlayer.HasControl())
			{
				LeftPlayerSyncMashRate2.Value = MashRate;
				ManagerComp.Player1MashRate = MashRate;
			}
			else if(LeftPlayer != nullptr && !LeftPlayer.HasControl())
				ManagerComp.Player1MashRate = LeftPlayerSyncMashRate2.Value;
		}
	}

	void HandlePlayer2Input(AHazePlayerCharacter Player, float MashRate)
	{
		if(bInteractionMoveInProgress)
			return;

		if(!bSwitchSyncFloats)
		{
			if(RightPlayer != nullptr && RightPlayer.HasControl())
			{
				RightPlayerSyncMashRate.Value = MashRate;
				RightPlayerSyncMashRate2.Value = 0.f;
				ManagerComp.Player2MashRate = MashRate;
			}
			else if (RightPlayer != nullptr && !RightPlayer.HasControl())
			{
				ManagerComp.Player2MashRate = RightPlayerSyncMashRate.Value;
			}
		}
		else
		{
			if(RightPlayer != nullptr && RightPlayer.HasControl())
			{
				RightPlayerSyncMashRate2.Value = MashRate;
				RightPlayerSyncMashRate.Value = 0.f;
				ManagerComp.Player2MashRate = MashRate;
			}
			else if (RightPlayer != nullptr && !RightPlayer.HasControl())
			{
				ManagerComp.Player2MashRate = RightPlayerSyncMashRate2.Value;
			}
		}
	}

	UFUNCTION(NetFunction)
	void CancelInteraction(AHazePlayerCharacter Player)
	{
		DoubleInteract.CancelInteracting(Player);
		ExitFromInteraction(Player, bPlayExitAnimation = true);

		if(Player == LeftPlayer)
			LeftPlayer = nullptr;
		else
			RightPlayer = nullptr;

		//Stopped interacting and no player is left in interaction.
		if(LeftPlayer == nullptr && RightPlayer == nullptr)
		{
			UHazeAkComponent::HazePostEventFireForget(NoPlayersGrabbingRopeAudioEvent, this.GetActorTransform());
		}
	}

	void SetReadyForComplete(AHazePlayerCharacter Player, bool bReady)
	{
		ReadyForComplete[Player] = bReady;
		CheckForInteractionComplete();
	}

	UFUNCTION()
	void Enable(FName Reason)
	{
		LeftInteraction.Enable(Reason);
		RightInteraction.Enable(Reason);
	}

	UFUNCTION()
	void Disable(FName Reason)
	{
		LeftInteraction.Disable(Reason);
		RightInteraction.Disable(Reason);
	}

	UFUNCTION()
	void OnInteractionUsed(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		ActiveInteractions[Player] = UsedInteraction;
		UsedInteraction.Disable(n"InUse");

		Player.SetCapabilityAttributeObject(n"TugOfWarActor", this);
		Player.SetCapabilityAttributeObject(n"ManagerComp", ManagerComp);

		Player.AddCapability(AnimationCapability);
		Player.AddCapability(ButtonMashCapability);
		Player.AddCapability(CancelCapability);

		Player.BlockCapabilities(n"Death", this);

		DoubleInteract.StartInteracting(Player);

		if(UsedInteraction == LeftInteraction)
		{
			Player.SetCapabilityActionState(n"TugOfWarPlayer1", EHazeActionState::Active);
			Player1Component = UTugOfWarPlayerComponent::GetOrCreate(Player);
			Player1Component.bIsExitingInteraction = false;
			Player1Component.ManagerComp = ManagerComp;
			Player1Component.bIsPlayer1 = true;
			Player1Component.TotalSteps = ManagerComp.InteractionSteps;
			Player1Component.Activate();
			ManagerComp.LeftPlayer = Player;
			ManagerComp.LeftButtonMashPosition = LeftButtonMashPosition;
			LeftPlayerSyncMashRate.OverrideControlSide(Player);
			LeftPlayerSyncMashRate2.OverrideControlSide(Player);

			//If Player is the first player to interact.
			if(LeftPlayer == nullptr && RightPlayer == nullptr)
			{
				HazeAkCompCogsRightSide.HazePostEvent(OnePlayerInteractRightCogsAudioEvent);
				HazeAkCompCogsLeftSide.HazePostEvent(OnePlayerInteractLeftCogsAudioEvent);
				HazeAkCompCogsRope.HazePostEvent(OnePlayerInteractRopeAudioEvent);
			}

			Player.PlayerHazeAkComp.HazePostEvent(MayGrabRopeAudioEvent);

			LeftPlayer = Player;

			//Player is interacting alone
			if(RightPlayer == nullptr)
			{
				ManagerComp.StartPlayer1Handle();
				PendingStartBarkTimerHandle = System::SetTimer(this, n"PlayPendingStartVOBark", 3.f, false);
			}
		}
		else
		{
			Player.SetCapabilityActionState(n"TugOfWarPlayer2", EHazeActionState::Active);

			Player2Component = UTugOfWarPlayerComponent::GetOrCreate(Player);
			Player2Component.bIsExitingInteraction = false;
			Player2Component.ManagerComp = ManagerComp;
			Player2Component.bIsPlayer1 = false;
			Player2Component.TotalSteps = ManagerComp.InteractionSteps;
			Player2Component.Activate();
			ManagerComp.RightPlayer = Player;
			ManagerComp.RightButtonMashPosition = RightButtonMashPosition;
			RightPlayerSyncMashRate.OverrideControlSide(Player);
			RightPlayerSyncMashRate2.OverrideControlSide(Player);

			//If Player is the first player to interact.
			if(LeftPlayer == nullptr && RightPlayer == nullptr)
			{
				HazeAkCompCogsRightSide.HazePostEvent(OnePlayerInteractRightCogsAudioEvent);
				HazeAkCompCogsLeftSide.HazePostEvent(OnePlayerInteractLeftCogsAudioEvent);
				HazeAkCompCogsRope.HazePostEvent(OnePlayerInteractRopeAudioEvent);
			}

			Player.PlayerHazeAkComp.HazePostEvent(CodyGrabRopeAudioEvent);

			RightPlayer = Player;

			//Player Is Interacting Alone			
			if(LeftPlayer == nullptr)
			{
				ManagerComp.StartPlayer2Handle();
				PendingStartBarkTimerHandle = System::SetTimer(this, n"PlayPendingStartVOBark", 3.f, false);
			}
		}
	
		if(LeftPlayer == nullptr || RightPlayer == nullptr)
			Player.SetCapabilityActionState(n"ButtonMashing", EHazeActionState::Active);

		OnLeftOrRightInteractionReady(UsedInteraction, Player);
	}

	UFUNCTION()
	void PlayPendingStartVOBark()
	{
		if(LeftPlayer != nullptr && RightPlayer == nullptr)
			MinigameComp.PlayPendingStartVOBark(LeftPlayer, RightInteraction.WorldLocation);
		else if (RightPlayer != nullptr && LeftPlayer == nullptr)
			MinigameComp.PlayPendingStartVOBark(RightPlayer, LeftInteraction.WorldLocation);
		else
			return;
	}

	UFUNCTION()
	void ShowTutorial()
	{
		if(ManagerComp.Player1Handle != nullptr)
			ManagerComp.Player1Handle.ResetButtonMash();
		if(ManagerComp.Player2Handle != nullptr)
			ManagerComp.Player2Handle.ResetButtonMash();

		ManagerComp.ResetMashRate();

		if(HasControl())
			NetSetSwitchSyncBool(!bSwitchSyncFloats);
	
		MinigameComp.ActivateTutorial();
		ManagerComp.StopPlayer1Handle();
		ManagerComp.StopPlayer2Handle();
		EnableButtonMash(false);
	}

	UFUNCTION()
	void TutorialCancelled()
	{
		MinigameComp.EndGameHud();
		ExitFromInteraction(LeftPlayer, true);
		ExitFromInteraction(RightPlayer, true);
	}

	private void ExitFromInteraction(AHazePlayerCharacter Player, bool bPlayExitAnimation)
	{
		Player.SetCapabilityAttributeObject(n"TugOfWarActor", nullptr);
		Player.SetCapabilityActionState(n"ButtonMashing", EHazeActionState::Inactive);

		Player.RemoveCapability(AnimationCapability);
		Player.RemoveCapability(ButtonMashCapability);
		Player.RemoveCapability(CancelCapability);
		
		Player.UnblockCapabilities(n"Death", this);

		if(ActiveCamera != nullptr)
			DeactivateCamera();
			
		if(!ManagerComp.bInteractionStarted)
		{
			ActiveInteractions[Player].Enable(n"InUse");
			ActiveInteractions[Player] = nullptr;
		}

		if(Player == LeftPlayer)
		{
			Player1Component.bIsExitingInteraction = true;
			Player.SetCapabilityActionState(n"TugOfWarPlayer1", EHazeActionState::Inactive);
			Player1Component.Deactivate();
			ManagerComp.Player1MashRate = 0.f;
			LeftPlayer = nullptr;
		}
		else
		{
			Player2Component.bIsExitingInteraction = true;
			Player.SetCapabilityActionState(n"TugOfWarPlayer2", EHazeActionState::Inactive);
			Player2Component.Deactivate();
			ManagerComp.Player2MashRate = 0.f;
			RightPlayer = nullptr;
		}

		if(System::IsTimerActiveHandle(PendingStartBarkTimerHandle))
			System::ClearAndInvalidateTimerHandle(PendingStartBarkTimerHandle);
	}

	UFUNCTION()
	void OnLeftOrRightInteractionReady(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{	
		if(UsedInteraction == LeftInteraction)
		{
			OnLeftInteractionReady.Broadcast(Player);

			if(RightPlayer != nullptr)
			{
				bBothPlayersInteracting = true;
	
				if(System::IsTimerActiveHandle(PendingStartBarkTimerHandle))
					System::ClearAndInvalidateTimerHandle(PendingStartBarkTimerHandle);
			}
			else
				bBothPlayersInteracting = false;
		}
		else
		{
			OnRightInteractionReady.Broadcast(Player);

			if(LeftPlayer != nullptr)
			{
				bBothPlayersInteracting = true;
	
				if(System::IsTimerActiveHandle(PendingStartBarkTimerHandle))
					System::ClearAndInvalidateTimerHandle(PendingStartBarkTimerHandle);
			}
			else
				bBothPlayersInteracting = false;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnTutorialCompleted()
	{
		if(HasControl())
		{
			CheckForInteractionComplete();

			HazeAkCompCogsLeftSide.HazePostEvent(StopLeftCogsLoopAudioEvent);
			HazeAkCompCogsRightSide.HazePostEvent(StopRightCogsLoopAudioEvent);
			HazeAkCompCogsRope.HazePostEvent(StartSqueakyRopeLoopAudioEvent);
		}

		//Change to apply fullscreen for first player interacting as they already have view centered on interact?
		Game::GetMay().ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);

		ManagerComp.DirSign = 0.f;
		ActivateCamera(NeutralCamera);
		bWaitingForComplete = true;

		MinigameComp.StartCountDown();
	}

	private void CheckForInteractionComplete()
	{
		if(!bWaitingForComplete)
			return;
		
		for (auto Player : Game::Players)
		{
			if(!ReadyForComplete[Player])
				return;
		}
	}

	UFUNCTION(NetFunction)
	private void CompleteInteraction(bool DidMayWin)
	{
		OnTriggerTugOfWarSequence.Broadcast(DidMayWin);
	}

	UFUNCTION(BlueprintCallable)
	void InteractionSequenceComplete()
	{
		bWaitingForComplete = false;
		for (auto Player : Game::Players)
		{
			ExitFromInteraction(Player, bPlayExitAnimationOnCompleted);
			ReadyForComplete[Player] = false;
		}

		LeftPlayer = nullptr;
		RightPlayer = nullptr;

		ManagerComp.ResetCompletion();
	}

	UFUNCTION(NetFunction)
	void OnStateChange(int State)
	{
		switch(State)
		{
			case(-2):
				DeactivateCamera();
				if(MayCamera != nullptr)
					ActivateCamera(MayCamera);
				break;
			case(2):
				DeactivateCamera();
				if(CodyCamera != nullptr)
					ActivateCamera(CodyCamera);
				break;
			default:
				if(ActiveCamera != NeutralCamera)
				{
					DeactivateCamera();
					if(NeutralCamera != nullptr)
						ActivateCamera(NeutralCamera);
				}
				break;
		}
	}

	UFUNCTION()
	void DeactivateCamera()
	{
		if(ActiveCamera == nullptr)
			return;

		for(auto Player : Game::Players)
		{
			ActiveCamera.DeactivateCamera(Player);
		}
	}

	void ActivateCamera(AHazeCameraActor Camera)
	{
		if(Camera == nullptr)
			return;
		
		FHazeCameraBlendSettings Settings;
		Settings.BlendTime = 2.f;

		for(auto Player : Game::Players)
		{
			Camera.ActivateCamera(Player, Settings);
		}
		ActiveCamera = Camera;
	}

	UFUNCTION(BlueprintCallable)
	void IncreaseCodyScore()
	{
		MinigameComp.AnnounceWinner(EMinigameWinner::Cody);
	}

	UFUNCTION(BlueprintCallable)
	void IncreaseMayScore()
	{
		MinigameComp.AnnounceWinner(EMinigameWinner::May);
	}

	UFUNCTION()
	void OnInteractionMove()
	{
		if(HasControl())
		{
			NetBlockButtonMashing(true);
			NetSetMoving(true);
		}
	}

	UFUNCTION()
	void OnInteractionMoveCompleted()
	{
		if(HasControl())
		{
			NetBlockButtonMashing(false);
			NetSetMoving(false);
			NetSetSwitchSyncBool(!bSwitchSyncFloats);
			NetCallMinigameTaunt(ManagerComp.CurrentStep);
		}
	}

	UFUNCTION(NetFunction)
	void NetCallMinigameTaunt(int State)
	{
		if (ManagerComp.PlayerWonMove != nullptr)
			MinigameComp.PlayTauntAllVOBark(ManagerComp.PlayerWonMove);
	}

	UFUNCTION(NetFunction)
	void OnCountdownFinished()
	{
		ManagerComp.bInteractionStarted = true;
		ManagerComp.StartPlayer1Handle();
		ManagerComp.StartPlayer2Handle();
		EnableButtonMash(true);
	}

	UFUNCTION()
	void OnVictoryAnimationFinished()
	{
		ActiveInteractions[0].Enable(n"InUse");
		ActiveInteractions[1].Enable(n"InUse");

		ActiveInteractions[1] = nullptr;
		ActiveInteractions[0] = nullptr;
	}

	UFUNCTION(NetFunction)
	void NetBlockButtonMashing(bool Blocked)
	{
		if(!Blocked)
		{
			for(auto Player : Game::Players)
			{
				Player.SetCapabilityActionState(n"ButtonMashBlocked", EHazeActionState::Inactive);
			}	
		}
		else
		{
			for(auto Player : Game::Players)
			{
				Player.SetCapabilityActionState(n"ButtonMashBlocked", EHazeActionState::Active);
			}
		}
	}

	UFUNCTION()
	void EnableButtonMash(bool Enabled)
	{
		if(!Enabled)
		{
			for(auto Player : Game::Players)
			{
				Player.SetCapabilityActionState(n"ButtonMashing", EHazeActionState::Inactive);
			}	
		}
		else
		{
			for(auto Player : Game::Players)
			{
				Player.SetCapabilityActionState(n"ButtonMashing", EHazeActionState::Active);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetSetSwitchSyncBool(bool state)
	{
		bSwitchSyncFloats = state;
	}

	UFUNCTION(NetFunction)
	void NetSetMoving(bool Moving)
	{
		bInteractionMoveInProgress = Moving;
	}
}
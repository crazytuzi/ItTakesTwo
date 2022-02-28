import Peanuts.Spline.SplineComponent;
import Cake.SlotCar.SlotCarActor;
import Vino.Visibility.Capabilities.HideCharacterCapability;
import Vino.Interactions.InteractionComponent;
import Vino.Tutorial.TutorialStatics;
import Vino.Interactions.DoubleInteractionActor;
import Peanuts.Spline.SplineMeshCreation;
import Cake.SlotCar.SlotCarLapTimes;
import Cake.SlotCar.SlotCarWidget;
import Cake.SlotCar.Capabilities.SlotCarRaceStage;
import Vino.Camera.Components.CameraKeepInViewComponent;
import Vino.MinigameScore.MinigameComp;
import Cake.LevelSpecific.Music.VOBanks.MusicConcertHallVOBank;

class ASlotCarTrackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// Camera
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCameraRootComponent CameraRootComp;

	UPROPERTY(DefaultComponent, Attach = CameraRootComp, ShowOnActor)
    UCameraKeepInViewComponent KeepInViewComp;

	UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent KeepInViewTargetLeft;
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent KeepInViewTargetRight;
	UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent KeepInViewTargetTop;
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent KeepInViewTargetBottom;

    UPROPERTY(DefaultComponent, Attach = KeepInViewComp, ShowOnActor)
    UHazeCameraComponent TrackCamera;
	default TrackCamera.Settings.bUseSnapOnTeleport = true;
	default TrackCamera.Settings.bSnapOnTeleport = false;


	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase MayControllerMesh;
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase CodyControllerMesh;

	UPROPERTY(DefaultComponent, Attach = MayControllerMesh)
	UInteractionComponent MayInteractionComp;
	UPROPERTY(DefaultComponent, Attach = CodyControllerMesh)
	UInteractionComponent CodyInteractionComp;
	
    UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
    UHazeSplineComponent SplineComp;

    UPROPERTY(DefaultComponent, NotEditable, Attach = SplineComp)
    UBillboardComponent BillboardComponent;
    default BillboardComponent.SetRelativeLocation(FVector(0, 0, 150));
    default BillboardComponent.Sprite = Asset("/Engine/EditorResources/Spline/T_Loft_Spline");
    default BillboardComponent.bIsEditorOnly = true;

    UPROPERTY()
	TPerPlayer<ASlotCarActor> SlotCars;
    TArray<USplineMeshComponent> SplineMeshComponents;
    UPROPERTY(NotEditable)
    TArray<FVector> TrackLanes;

    UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.MinigameTag = EMinigameTag::Slotcars;

    /* Track Attributes */
	UPROPERTY(Category = "Track Attributes")
	FSplineMeshData SplineMeshData;
    UPROPERTY(Category = "Track Attributes")
    TSubclassOf<ASlotCarActor> SlotCarType(ASlotCarActor::StaticClass());
    UPROPERTY(Category = "Track Attributes")
    float LaneHeight = 19.f;
    UPROPERTY(Category = "Track Attributes")
    float LaneSpacing = 50.f;	

	UPROPERTY(NotEditable)
	FSplineMeshRangeContainer SplineMeshContainer;

    UPROPERTY(Category = "Track Attributes")
    int TargetLaps = 3;
    
	UPROPERTY(Category = "Track Attributes")
	bool bSpawnCars = true;

    UPROPERTY(Category = "Game State")
	bool bPlayersCanCancel;

	UPROPERTY(Category = "Audio Events")
	UMusicConcertHallVOBank VOBank;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RedLightEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GreenLightEvent;

	UPROPERTY()
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY(Category = "Animations")
	FSlotCarPlayerAnimations CodyAnimations;
	UPROPERTY(Category = "Animations")
	FSlotCarPlayerAnimations MayAnimations;
	UPROPERTY(Category = "Animations")
	UBlendSpace ControllerBlendSpace;

	TPerPlayer<UInteractionComponent> ActiveInteractions;
	TPerPlayer<bool> bEnterAnimationComplete;

	// Car Trackers
	TPerPlayer<FSlotCarLapTimes> LapTimes;

	ESlotCarRaceStage RaceStage = ESlotCarRaceStage::Idle;

	bool bStartRaceTutorialVisible = false;
    
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		BuildMeshes();
        CreateLanes();
    }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Disable each others interaction point from the other player
		MayInteractionComp.DisableForPlayer(Game::Cody, n"SlotCar");
		CodyInteractionComp.DisableForPlayer(Game::May, n"SlotCar");

		MayInteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		CodyInteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");
		
		// Play controller blend spaces
		FHazePlayBlendSpaceParams BSParams;
		BSParams.BlendSpace = ControllerBlendSpace;
		MayControllerMesh.PlayBlendSpace(BSParams);
		CodyControllerMesh.PlayBlendSpace(BSParams);

		if (bSpawnCars)
			AddCarsToTrack();

		bPlayersCanCancel = true;

		//Add keep in view targets
		FHazeFocusTarget LeftTarget;
		LeftTarget.Component = KeepInViewTargetLeft;
		KeepInViewComp.AddTarget(LeftTarget);

		FHazeFocusTarget RightTarget;
		RightTarget.Component = KeepInViewTargetRight;
		KeepInViewComp.AddTarget(RightTarget);

		FHazeFocusTarget TopTarget;
		TopTarget.Component = KeepInViewTargetTop;
		KeepInViewComp.AddTarget(TopTarget);

		FHazeFocusTarget BottomTarget;
		BottomTarget.Component = KeepInViewTargetBottom;
		KeepInViewComp.AddTarget(BottomTarget);

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"OnMinigameTutorialComplete");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"OnMinigameCancelled");
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"CountDownCompleted");
	}

	UFUNCTION()
	void OnMinigameTutorialComplete()
	{
		if (!HasControl())
			return;

		NetSetStageCountdown();
	}

	UFUNCTION()
	void OnMinigameCancelled()
	{
		if (!HasControl())
			return;

		NetSetStagePractice(nullptr);
	}

	UFUNCTION(NetFunction)
	void NetRequestReadyCheck()
	{	
		if (!HasControl())
			return;

		if (RaceStage != ESlotCarRaceStage::Practice)
			return;

		if (ActiveInteractions[0] == nullptr || ActiveInteractions[1] == nullptr)
			return;

		NetSetStageReadyCheck();
	}

	UFUNCTION(NetFunction)
	void NetRequestCancel(AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;		

		if (RaceStage == ESlotCarRaceStage::Practice && ActiveInteractions[Player] != nullptr)
			NetAcceptCancel(Player);
		else if (RaceStage == ESlotCarRaceStage::RaceActive)
			NetAcceptCancel(Player);
	}

	UFUNCTION(NetFunction)
	void NetAcceptCancel(AHazePlayerCharacter Player)
	{
		ExitFromInteraction(Player);

		if (!HasControl())
			return;
		if (ActiveInteractions[0] == nullptr && ActiveInteractions[1] == nullptr)
			NetSetStageIdle();
		else
			NetSetStagePractice(Player.OtherPlayer);
	}

	UFUNCTION(NetFunction)
	void NetSetStageIdle()
	{
		RaceStage = ESlotCarRaceStage::Idle;

		MinigameComp.EndGameHud();
	}

	UFUNCTION(NetFunction)
	void NetSetStagePractice(AHazePlayerCharacter Player)
	{
		if (RaceStage == ESlotCarRaceStage::Idle)
		{
			if (HasControl())
				MinigameComp.NetDeactivateTambourineCharacter();
		}
		else if (RaceStage == ESlotCarRaceStage::ReadyCheck)
			MinigameComp.EndGameHud();
		else if (RaceStage == ESlotCarRaceStage::RaceActive)
		{
			LapTimes[0].RaceEnded();
			LapTimes[1].RaceEnded();

			if (Player != nullptr)
				MinigameComp.AnnounceWinner(Player);
			else
				MinigameComp.EndGameHud();
		}

		RaceStage = ESlotCarRaceStage::Practice;

		if (BothPlayersInteracting())
			ShowStartRaceTutorial();
	}

	UFUNCTION(NetFunction)
	void NetSetStageReadyCheck()
	{
		RaceStage = ESlotCarRaceStage::ReadyCheck;

		HideStartRaceTutorial();
		MinigameComp.ActivateTutorial();
	}

	UFUNCTION(NetFunction)
	void NetSetStageCountdown()
	{
		RaceStage = ESlotCarRaceStage::Countdown;

		if (HasControl() && Network::IsNetworked())
			System::SetTimer(this, n"SetStageCountdownInternal", Network::GetPingRoundtripSeconds() * 0.5f, false);
		else
			SetStageCountdownInternal();
	}

	UFUNCTION()
	void SetStageCountdownInternal()
	{
		MinigameComp.StartCountDown();

		for (ASlotCarActor SlotCar : SlotCars)
		{
			SlotCar.BlockCapabilities(n"SlotCar", this);
			SlotCar.CurrentSpeed = 0.f;
			SlotCar.TeleportSlotCarToStartOfSpline(SlotCar);
		}

		LapTimes[0].PrepareForRaceStart(TargetLaps);
		LapTimes[1].PrepareForRaceStart(TargetLaps);
	}

	UFUNCTION()
	void CountDownCompleted()
	{
		RaceStage = ESlotCarRaceStage::RaceActive;

		for (ASlotCarActor SlotCar : SlotCars)
		{
			SlotCar.UnblockCapabilities(n"SlotCar", this);
		}

		LapTimes[0].RaceStarted();
		LapTimes[1].RaceStarted();
	}

	void BuildMeshes()
	{		
		FSplineMeshBuildData BuildData = MakeSplineMeshBuildData(this, SplineComp, SplineMeshData);

		if (!BuildData.IsValid())
			return;

		BuildSplineMeshes(BuildData, SplineMeshContainer);
	}
	
    // Add lanes to the TrackLane array and calculate their offset
    void CreateLanes()
    {
		TrackLanes.Empty();
         
		for (int Index = 0, Count = 2; Index < Count; ++Index)
		{
			float HorizontalOffset = ((-LaneSpacing * (Count - 1)) / 2) + (LaneSpacing * Index);
			FVector LaneOffset = FVector(0, HorizontalOffset, LaneHeight);            
			TrackLanes.Add(LaneOffset);           
		}
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (RaceStage == ESlotCarRaceStage::RaceActive)
			MinigameComp.UpdateCurrentLapTimes(DeltaTime);
	}

	void AddCarsToTrack()
	{
		for (int Index = 0; Index < 2; Index++)
		{			
            FVector TrackOffset = TrackLanes[Index];
            FVector SpawnLocaton = SplineComp.GetTransformAtSplinePoint(0, ESplineCoordinateSpace::World, false).TransformPosition(TrackOffset);
            FRotator SpawnRotation = SplineComp.GetRotationAtSplinePoint(0, ESplineCoordinateSpace::World);

			ASlotCarActor SlotCar = Cast<ASlotCarActor>(SpawnActor(SlotCarType, SpawnLocaton, SpawnRotation, bDeferredSpawn = true, Level = GetLevel()));
			SlotCars[Game::Players[Index]] = SlotCar;

			SlotCar.TrackSplineOffset = TrackOffset;
			SlotCar.TrackActor = this;
			SlotCar.OwningPlayer = Game::Players[Index];
			SlotCar.SetControlSide(Game::Players[Index]);
			SlotCar.TrackSpline = SplineComp;
			SlotCar.SetActorTickEnabled(true);
			SlotCar.MakeNetworked(FNetworkIdentifierPart(Index), FNetworkIdentifierPart(this));
			SlotCar.CarIndex = Index;
			FinishSpawningActor(SlotCar);
		}
	}

	UFUNCTION(NetFunction)
	void NetLapCompleted(AHazePlayerCharacter Player, float LapTime)
	{
		LapTimes[Player].LapCompleted(LapTime);
		
		MinigameComp.SetScore(Player, FMath::Min(LapTimes[Player].NumberOfLaps, TargetLaps));
		MinigameComp.SetBestAndLastLapTimes(Player);

		if (RaceStage != ESlotCarRaceStage::RaceActive)
			return;

		PlayLeaderTauntBark(Player);

		if (!Network::IsNetworked() && LapTimes[Player].NumberOfLaps > TargetLaps)
		{
			NetRaceFinished(Player);
			return;
		}

		if (!HasControl())
			return;
			
		if (LapTimes[Player].NumberOfLaps > TargetLaps)
		{
			// Race finished locally
			LapTimes[Player].RaceEnded();

			if (!Player.HasControl())
			{
				// Remote side won - No need to check
				if (LapTimes[Player.OtherPlayer].HasCompletedRace())
				{
					// Compared lap times
					if (LapTimes[Player].TotalRaceTime <= LapTimes[Player.OtherPlayer].TotalRaceTime)
						NetRaceFinished(Player);
					else
						NetRaceFinished(Player.OtherPlayer);
				}
				else
				{
					NetRaceFinished(Player);
				}
			}
			else
			{
				// Control side has completed the race - check if we actually won
				NetCheckIfControlSideWon(Player);
			}
		}
	}

	void PlayLeaderTauntBark(AHazePlayerCharacter LapFinisher)
	{
		AHazePlayerCharacter Leader;
		if (LapTimes[LapFinisher].NumberOfLaps > LapTimes[LapFinisher.OtherPlayer].NumberOfLaps)
			Leader = LapFinisher;
		else
			Leader = LapFinisher.OtherPlayer;
		
		MinigameComp.PlayTauntAllVOBark(Leader);
	}

	// Winner checks
	UFUNCTION(NetFunction)
	void NetCheckIfControlSideWon(AHazePlayerCharacter Player)
	{
		if (HasControl())
			return;

		if (LapTimes[Player.OtherPlayer].HasCompletedRace())
		{
			// Waiting for message, don't do shit, yo
		}
		else
			NetControlSideWinValidated(Player);
	}
	UFUNCTION(NetFunction)
	void NetControlSideWinValidated(AHazePlayerCharacter Player)
	{
		// Control side wins
		if (HasControl())
			NetRaceFinished(Player);
	}

	// Declare the winner
	UFUNCTION(NetFunction)
	void NetRaceFinished(AHazePlayerCharacter Winner)
	{	
		if (HasControl())
			NetSetStagePractice(Winner);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionActivated(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		ActiveInteractions[Player] = UsedInteraction;
		
		UsedInteraction.Disable(n"InUse");

		// Update the slot car and push the sheet for player control
		ASlotCarActor SlotCar = SlotCars[Player];
		Player.SetCapabilityAttributeObject(n"SlotCarActor", SlotCar);
		Player.AddCapabilitySheet(PlayerSheet, Priority = EHazeCapabilitySheetPriority::Interaction, Instigator = this);

		Player.SetCapabilityAttributeObject(n"SlotCarInteraction", this);
	
		// Activate cameras
		Player.ActivateCamera(TrackCamera, FHazeCameraBlendSettings(2.f), this);
		// FHazeFocusTarget FocusTarget;
		// FocusTarget.Actor = SlotCar;
		// KeepInViewComp.AddTarget(FocusTarget);

		// If both players have entered
		if (ActiveInteractions[Player] != nullptr && ActiveInteractions[Player.OtherPlayer] != nullptr)
			Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen);
		else
		{
			// Only one player interacting - Play the pending start bark
			FVector InteractionLocation;
			if (Player.IsMay())
				InteractionLocation = CodyInteractionComp.WorldLocation;
			else
				InteractionLocation = MayInteractionComp.WorldLocation;

			MinigameComp.PlayPendingStartVOBark(Player, InteractionLocation);

			SetCarsAudioPanningOverride(Player);
		}
		
		// Tambourine should despawn if anyone interacts with the slot car
		if (HasControl())
			NetSetStagePractice(nullptr);
	}

	void ExitFromInteraction(AHazePlayerCharacter Player)
	{
		HideStartRaceTutorial();

		Player.DetachRootComponentFromParent();
		Player.RemoveAllCapabilitySheetsByInstigator(Instigator = this);

		Player.StopBlendSpace();
		Player.PlayEventAnimation(Animation = GetAnimations(Player).Exit);

		ActiveInteractions[Player].Enable(n"InUse");
		ActiveInteractions[Player] = nullptr;

		Player.SetCapabilityAttributeObject(n"SlotCarInteraction", nullptr);

		Player.DeactivateCamera(TrackCamera, 2.f);

		// The first player leaving should put the screen back to split
		if (ActiveInteractions[Player.OtherPlayer] != nullptr)
		{
			Player.ClearViewSizeOverride(this);
			Player.OtherPlayer.ClearViewSizeOverride(this);
			SetCarsAudioPanningOverride(Player.OtherPlayer);
		}

		LapTimes[Player].LeftTrack();
	}

	bool BothPlayersInteracting() const
	{
		return ActiveInteractions[0] != nullptr && ActiveInteractions[1] != nullptr;
	}

	const FSlotCarPlayerAnimations& GetAnimations(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			return MayAnimations;
		else
			return CodyAnimations;
	}

	UHazeSkeletalMeshComponentBase GetControllerMeshForPlayer(AHazePlayerCharacter Player)
	{
		return Player.IsMay() ? MayControllerMesh : CodyControllerMesh;
	}

	void ShowStartRaceTutorial()
	{
		if (bStartRaceTutorialVisible)
			return;

		bStartRaceTutorialVisible = true;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			FTutorialPrompt StartRaceTutorial;
			StartRaceTutorial.DisplayType = ETutorialPromptDisplay::Action;
			StartRaceTutorial.Mode = ETutorialPromptMode::Default;
			StartRaceTutorial.Action = n"InteractionTrigger";
			StartRaceTutorial.Text = NSLOCTEXT("SlotCar", "StartRaceTutorial", "Start Race");
			Player.ShowTutorialPrompt(StartRaceTutorial, this);
		}
	}

	void HideStartRaceTutorial()
	{
		if (!bStartRaceTutorialVisible)
			return;
		
		bStartRaceTutorialVisible = false;

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.RemoveTutorialPromptByInstigator(this);
		}
	}

	void SetCarsAudioPanningOverride(AHazePlayerCharacter Player)
	{
		for(ASlotCarActor Car : SlotCars)
		{
			if(Car == nullptr)
				continue;
				
			HazeAudio::SetPlayerPanning(Car.HazeAkComp, Player);
		}
	}
}

struct FSlotCarPlayerAnimations
{
	UPROPERTY()
	UAnimSequence Enter;
	UPROPERTY()
	UBlendSpace BS;
	UPROPERTY()
	UAnimSequence Exit;
};

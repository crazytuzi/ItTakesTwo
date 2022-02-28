import Vino.Interactions.InteractionComponent;
import Vino.Interactions.DoubleInteractComponent;
import Vino.Tutorial.TutorialStatics;
import Vino.MinigameScore.MinigameComp;
import Peanuts.Outlines.Outlines;

import void ActivateWhackACodyForPlayer(AHazePlayerCharacter PlayerRef, AWhackABoard WhackABoardRef) from 'Cake.LevelSpecific.Shed.NailMine.WhackACodyComponent';
import Peanuts.Foghorn.FoghornStatics;

// Order matters!
// Right	= 0 * 90 deg
// Down		= 1 * 90 deg
// Left		= 2 * 90 deg
// Up		= 3 * 90 deg
// This makes it so we can do nice math using the integer representation
enum EWhackACodyDirection
{
	Right,
	Down,
	Left,
	Up,
	Neutral
};

enum EWhackACodyGameStates
{
	Idle,
	ShowingTutorial,
	Countdown,
	Playing,
	PlayerWon,
}

class AWhackABoard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DoorRoot;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UStaticMeshComponent DoorMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent LeftHole;

	UPROPERTY(DefaultComponent, Attach = LeftHole)
	UCapsuleComponent LeftCodyCollision;
	default LeftCodyCollision.RelativeLocation = FVector(0,0,45);
	default LeftCodyCollision.CapsuleHalfHeight = 66;
	default LeftCodyCollision.CapsuleRadius = 50;

	UPROPERTY(DefaultComponent, Attach = LeftHole)
	UStaticMeshComponent LeftLid;

	UPROPERTY(DefaultComponent)
	USceneComponent RightHole;

	UPROPERTY(DefaultComponent, Attach = RightHole)
	UCapsuleComponent RightCodyCollision;
	default RightCodyCollision.RelativeLocation = FVector(0,0,45);
	default RightCodyCollision.CapsuleHalfHeight = 66;
	default RightCodyCollision.CapsuleRadius = 50;

	UPROPERTY(DefaultComponent, Attach = RightHole)
	UStaticMeshComponent RightLid;

	UPROPERTY(DefaultComponent)
	USceneComponent DownHole;

	UPROPERTY(DefaultComponent, Attach = DownHole)
	UCapsuleComponent DownCodyCollision;
	default DownCodyCollision.RelativeLocation = FVector(0,0,45);
	default DownCodyCollision.CapsuleHalfHeight = 66;
	default DownCodyCollision.CapsuleRadius = 50;

	UPROPERTY(DefaultComponent, Attach = DownHole)
	UStaticMeshComponent DownLid;

	UPROPERTY(DefaultComponent)
	USceneComponent UpHole;

	UPROPERTY(DefaultComponent, Attach = UpHole)
	UCapsuleComponent UpCodyCollision;
	default UpCodyCollision.RelativeLocation = FVector(0,0,45);
	default UpCodyCollision.CapsuleHalfHeight = 66;
	default UpCodyCollision.CapsuleRadius = 50;

	UPROPERTY(DefaultComponent, Attach = UpHole)
	UStaticMeshComponent UpLid;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = MayIntComp)
	USceneComponent MayAttachPoint;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CodyWalkToLocation;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent CodyWalkOutLocation;

	UPROPERTY(DefaultComponent)
	UInteractionComponent CodyIntComp;

	UPROPERTY(DefaultComponent)
	UInteractionComponent MayIntComp;

	UPROPERTY(DefaultComponent)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.bCodyAutoReactionAnimations = false;
	default MinigameComp.MinigameTag = EMinigameTag::WhackACody;

	UPROPERTY(DefaultComponent, Attach = DoorRoot)
	UHazeAkComponent WhackDoorAkComp;

	UPROPERTY(Category = "Settings")
	EWhackACodyDirection CurrentCodyPositionEnum;

	UPROPERTY(Category = "Settings")
	EWhackACodyDirection CurrentMayHammerEnum;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet CodySheet;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet MaySheet;

	UPROPERTY(Category = "Setup")
	UAnimSequence CodyEnterSequence;

	UPROPERTY(Category = "Setup")
	UAnimSequence CodyExitSequence;

	UPROPERTY(Category = "Settings")
	float OpenMaxDegree = 80.f;
	UPROPERTY(Category = "Settings")
	float ChangeSpeed = 450.f;

	UPROPERTY(Category = "Setup")
	bool bMayHasHammer = true;

	UPROPERTY(Category = "Scoring")
	int MayScorePerHit = 2;

	UPROPERTY(Category = "Setup")
	FHazeTimeLike DoorTimeLike;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyEnterExitAudioEvent;

	UPROPERTY()
	UFoghornVOBankDataAssetBase VOBank;

	// UPROPERTY(Category = "Setup")
	// bool bRegisterTelemetry = true;

	EWhackACodyGameStates MinigameState = EWhackACodyGameStates::Idle;

	bool CodyIsInteracting = false;
	bool MayIsInteracting = false;
	bool BothPlayersInteracting = false;
	bool bPlayReactionAnim;
	TPerPlayer<bool> bPlayerIn;

	AHazePlayerCharacter CodyRef;
	AHazePlayerCharacter MayRef;

	UStaticMeshComponent ActiveLid;
	
	TArray<UStaticMeshComponent> Lids;
	TArray<UCapsuleComponent> Collisions;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MayIntComp.DisableForPlayer(Game::GetCody(), n"Cody");
		CodyIntComp.DisableForPlayer(Game::GetMay(), n"May");

 		Collisions.Add(RightCodyCollision);
		Collisions.Add(LeftCodyCollision);
		Collisions.Add(UpCodyCollision);
		Collisions.Add(DownCodyCollision);

		Lids.Add(LeftLid);
		Lids.Add(RightLid);
		Lids.Add(UpLid);
		Lids.Add(DownLid);

		DoorTimeLike.BindUpdate(this, n"OnDoorUpdate");

		FHazeTriggerCondition Condition;
		Condition.Delegate.BindUFunction(this, n"InteractionCondition");
		CodyIntComp.AddTriggerCondition(n"Grounded", Condition);
		CodyIntComp.OnActivated.AddUFunction(this, n"HandleInteraction");
		MayIntComp.AddTriggerCondition(n"Grounded", Condition);
		MayIntComp.OnActivated.AddUFunction(this, n"HandleInteraction");

		DoubleInteract.OnTriggered.AddUFunction(this, n"HandleDoubleInteractTriggered");

		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"HandleCountdownFinished");
		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"HandleVictoryFinished");

		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"InitiateGame");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"CancelFromTutorial");
	}

	UFUNCTION()
	bool InteractionCondition(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
		if(Player.MovementState.GroundedState != EHazeGroundedState::Grounded)
			return false;
		else
			return true;
	}

	UFUNCTION()
	void HandleInteraction(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		bPlayerIn[Player] = true;

		if (Player.IsCody())
		{
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			Player.BlockCapabilities(CapabilityTags::Interaction, this);
			Player.PlaySlotAnimation(Animation = CodyEnterSequence, OnBlendingOut = FHazeAnimationDelegate(this, n"HandleCodyEnterFinished"));
			DoorTimeLike.PlayFromStart();
			WhackDoorAkComp.HazePostEvent(CodyEnterExitAudioEvent);
		}
		else
		{
			Player.AddCapabilitySheet(MaySheet);
			ActivateWhackACodyForPlayer(Player, this);
		}

		if (!bPlayerIn[Player.OtherPlayer])
			MinigameComp.PlayPendingStartVOBark(Player, Player.ActorLocation);
	}

	UFUNCTION()
	void HandleCodyEnterFinished()
	{
		auto Cody = Game::Cody;
		Cody.AddCapabilitySheet(CodySheet);
		ActivateWhackACodyForPlayer(Cody, this);

		Cody.UnblockCapabilities(CapabilityTags::Movement, this);
		Cody.UnblockCapabilities(CapabilityTags::Interaction, this);
	}

	UFUNCTION()
	void HandleDoubleInteractTriggered()
	{
		StartGame();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateLids(DeltaTime);
	}

	float DoorOpenMax = -90.f;

	UFUNCTION()
	void OnDoorUpdate(float Value)
	{
		DoorMesh.RelativeRotation = FRotator(DoorMesh.RelativeRotation.Pitch, Value * DoorOpenMax, DoorMesh.RelativeRotation.Roll);
	}

	UFUNCTION()
	void PlayerCancelled(AHazePlayerCharacter Player)
	{
		bPlayerIn[Player] = false;

		if (MinigameState == EWhackACodyGameStates::Playing)
		{
			// If we're currently playing, things get a bit iffy...
			// We need to make sure the control side agrees this is how the game ends
			if (!HasControl())
				return;

			NetForceWinner(Player.OtherPlayer);
		}
		else
		{
			if (Player.IsCody())
				CodyExit(false);
			else
				Player.RemoveCapabilitySheet(MaySheet);
		}
	}

	void CodyExit(bool InPlayReactionAnim)
	{
		// Codys exit is special, since we play the lil' walking out animation :)
		auto Cody = Game::Cody;
		Cody.RemoveCapabilitySheet(CodySheet);
		Cody.BlockCapabilities(CapabilityTags::Movement, this);
		Cody.BlockCapabilities(CapabilityTags::Interaction, this);

		// Teleport cody to where the animation should start
		// He's walking out the door in the WhackABoard's right vector!
		// Slightly hardcoded but should be fine
		FTransform ExitTransform;
		ExitTransform.Location = ActorLocation;
		ExitTransform.Rotation = Math::MakeQuatFromX(ActorRightVector);

		Cody.ActorTransform = ExitTransform;

		// Play it!
		Cody.PlaySlotAnimation(Animation = CodyExitSequence, OnBlendingOut = FHazeAnimationDelegate(this, n"HandleCodyExitFinished"));
		DoorTimeLike.PlayFromStart();
		WhackDoorAkComp.HazePostEvent(CodyEnterExitAudioEvent);

		bPlayReactionAnim = InPlayReactionAnim;
	}

	UFUNCTION()
	void HandleCodyExitFinished()
	{
		auto Cody = Game::Cody;

		Cody.UnblockCapabilities(CapabilityTags::Movement, this);
		Cody.UnblockCapabilities(CapabilityTags::Interaction, this);
		Cody.TriggerMovementTransition(this, n"WhackACodyExit");

		// SO! For safety....
		// Even though the root motion SHOULD take us out of the box, it failing to do so would be a blocker
		// So to be sure, we smooth teleport the player to where they _should_ be after the animation
		FHazeLocomotionTransform RootMotionOffset;
		CodyExitSequence.ExtractTotalRootMotion(RootMotionOffset);

		FTransform ExitTransform;
		ExitTransform.Location = ActorLocation;
		ExitTransform.Rotation = Math::MakeQuatFromX(ActorRightVector);

		ExitTransform.Location = ExitTransform.TransformPosition(RootMotionOffset.DeltaTranslation);
		Cody.SmoothSetLocationAndRotation(ExitTransform.Location, ExitTransform.Rotation.Rotator());
		
		if (bPlayReactionAnim)
		{
			MinigameComp.ActivateReactionAnimations(Cody);
			bPlayReactionAnim = false;
		}
	}
	
	UFUNCTION()
	void StartGame()
	{
		MinigameComp.ActivateTutorial();
		MinigameState = EWhackACodyGameStates::ShowingTutorial;
	}

	UFUNCTION()
	void CancelFromTutorial()
	{
		MinigameState = EWhackACodyGameStates::Idle;
		// MinigameComp.EndGameHud();
		MinigameComp.ResetScoreBoth();
		CodyExit(false);
		Game::May.RemoveCapabilitySheet(MaySheet);

		ActiveLid = nullptr;

		bPlayerIn[0] = false;
		bPlayerIn[1] = false;
	}

	UFUNCTION()
	void InitiateGame()
	{
		MinigameComp.StartCountDown();
		MinigameState = EWhackACodyGameStates::Countdown;
	}

	UFUNCTION()
	void HandleCountdownFinished()
	{
		MinigameState = EWhackACodyGameStates::Playing;
	}

	UFUNCTION()
	void HandleVictoryFinished()
	{			
		CodyIntComp.Enable(n"GameFinished");
		MayIntComp.Enable(n"GameFinished");
		ResetMinigame();
	}

	void ResetMinigame()
	{
		MinigameState = EWhackACodyGameStates::Idle;
		// MinigameComp.EndGameHud();
		MinigameComp.ResetScoreBoth();
		ActiveLid = nullptr;
	}

	UFUNCTION(NetFunction)
	void NetAddMayScore()
	{
		if (MinigameState != EWhackACodyGameStates::Playing)
			return;

		if (MinigameComp.ScoreData.MayScore < MinigameComp.ScoreData.ScoreLimit)
		{
			MinigameComp.AdjustScore(Game::May, MayScorePerHit);
			FMinigameWorldWidgetSettings WidgetSettings;
			WidgetSettings.MinigameTextColor = EMinigameTextColor::May;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "+"+MayScorePerHit, Game::GetMay().GetActorLocation(), WidgetSettings);
			MinigameComp.PlayTauntAllVOBark(Game::May);
		}

		CheckForWinner();
	}

	UFUNCTION(NetFunction)
	void NetAddCodyScore()
	{
		if (MinigameState != EWhackACodyGameStates::Playing)
			return;

		if (MinigameComp.ScoreData.CodyScore < MinigameComp.ScoreData.ScoreLimit)
		{
			MinigameComp.AdjustScore(Game::Cody, 1);
			FMinigameWorldWidgetSettings WidgetSettings;
			WidgetSettings.MinigameTextColor = EMinigameTextColor::Cody;
			MinigameComp.CreateMinigameWorldWidgetText(EMinigameTextPlayerTarget::Both, "+"+1, Game::GetCody().GetActorLocation(), WidgetSettings);
			MinigameComp.PlayTauntAllVOBark(Game::Cody);
		}

		CheckForWinner();
	}

	void CheckForWinner()
	{
		if (HasControl())
		{
			int MayScore = MinigameComp.ScoreData.MayScore;
			int CodyScore = MinigameComp.ScoreData.CodyScore;

			if (MayScore >= MinigameComp.ScoreData.ScoreLimit ||
				CodyScore >= MinigameComp.ScoreData.ScoreLimit)
			{
				NetEndGame(MayScore, CodyScore);
			}
		}
	}

	UFUNCTION(NetFunction)
	void NetEndGame(int MayScore, int CodyScore)
	{
		MinigameState = EWhackACodyGameStates::PlayerWon;

		MinigameComp.SetScore(Game::May, MayScore);
		MinigameComp.SetScore(Game::Cody, CodyScore);

		MinigameComp.AnnounceWinner();

		// Cody's exit is special...
		CodyExit(true);
		Game::May.RemoveCapabilitySheet(MaySheet);

		bPlayerIn[0] = false;
		bPlayerIn[0] = true;

		DoorTimeLike.PlayFromStart();

		CodyIntComp.Disable(n"GameFinished");
		MayIntComp.Disable(n"GameFinished");
	}

	UFUNCTION(NetFunction)
	void NetForceWinner(AHazePlayerCharacter Player)
	{
		MinigameComp.AnnounceWinner(Player);

		// Cody's exit is special...
		CodyExit(true);
		Game::May.RemoveCapabilitySheet(MaySheet);

		bPlayerIn[0] = false;
		bPlayerIn[0] = true;

		DoorTimeLike.PlayFromStart();

		CodyIntComp.Disable(n"GameFinished");
		MayIntComp.Disable(n"GameFinished");
	}

	void EnableCollisionForHole(UCapsuleComponent CollisionToEnable)
	{
		for(auto Capsule : Collisions)
		{
			if(Capsule == CollisionToEnable)
				Capsule.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			else
				Capsule.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		}
	}

	void UpdateLids(float DeltaTime)
	{
		for(auto Lid : Lids)
		{
			if(Lid == ActiveLid)
			{
				float CurrentPitch = Lid.RelativeRotation.Pitch;
				float NewPitch = FMath::FInterpConstantTo(CurrentPitch, OpenMaxDegree, DeltaTime, ChangeSpeed);
				Lid.RelativeRotation = FRotator(NewPitch ,Lid.RelativeRotation.Yaw, Lid.RelativeRotation.Roll);
				//PrintToScreen("lid pitch" + CurrentPitch);

				if(CurrentPitch == 0 and NewPitch != CurrentPitch)
					Game::GetCody().SetCapabilityActionState(n"AudioLidOpened", EHazeActionState::ActiveForOneFrame);
			}
			else
			{
				float CurrentPitch = Lid.RelativeRotation.Pitch;
				float NewPitch = FMath::FInterpConstantTo(CurrentPitch, 0.f, DeltaTime, ChangeSpeed);
				Lid.RelativeRotation = FRotator(NewPitch ,Lid.RelativeRotation.Yaw, Lid.RelativeRotation.Roll);

				if(NewPitch == 0 && NewPitch != CurrentPitch)
					Game::GetCody().SetCapabilityActionState(n"AudioLidClosed", EHazeActionState::ActiveForOneFrame);
			}
		}
	}
}
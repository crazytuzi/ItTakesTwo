import Vino.Interactions.DoubleInteractionActor;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceSideScrollerPlatformDoor;
import Peanuts.Network.RelativeCrumbLocationCalculator;
import Cake.LevelSpecific.PlayRoom.VOBanks.SpacestationVOBank;
import Vino.Tutorial.TutorialStatics;

event void FSpaceSideScrollerStartedMoving();

UCLASS(Abstract)
class ASpaceSideScrollerPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeSkeletalMeshComponentBase TopLeverRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UHazeSkeletalMeshComponentBase BottomLeverRoot;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeComp;

	UPROPERTY(DefaultComponent)
	UHazeInheritPlatformVelocityComponent InheritVelocityComp;

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UHazeAkComponent HazeAkCompPlatform;

	UPROPERTY()
	FSpaceSideScrollerStartedMoving OnStartedMoving;

	UPROPERTY()
	FSpaceSideScrollerStartedMoving OnResetting;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JoystickInteractAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent JoystickCancelInteractAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformStartMoveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlatformStopMoveAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MovePlatformTimeLike;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LeverStart;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence LeverExit;

	UPROPERTY(EditDefaultsOnly)
	USpacestationVOBank VOBank;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;
	FVector StartLocation;

	UPROPERTY(EditDefaultsOnly)
	FText CrouchText;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteraction;

	UPROPERTY()
	ASpaceSideScrollerPlatformDoor StartTopDoor;
	UPROPERTY()
	ASpaceSideScrollerPlatformDoor StartBottomDoor;
	UPROPERTY()
	ASpaceSideScrollerPlatformDoor EndTopDoor;
	UPROPERTY()
	ASpaceSideScrollerPlatformDoor EndBottomDoor;

	bool bResetting = false;

	bool bMayDied = false;
	bool bCodyDied = false;

	bool bRespawnBlocked = false;

	bool bTopInteracted = false;
	bool bBottomInteracted = false;

	bool bMayHasCorrectWorldUp = false;

	UPROPERTY(NotVisible)
	bool bTriggerCrouchTutorialOnNextRespawn = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;
		EndLocation = StartLocation + EndLocation;

		MovePlatformTimeLike.SetPlayRate(0.075f);
		MovePlatformTimeLike.BindUpdate(this, n"UpdateMovePlatform");
		MovePlatformTimeLike.BindFinished(this, n"FinishMovePlatform");

		DoubleInteraction.OnDoubleInteractionCompleted.AddUFunction(this, n"DoubleInteractionCompleted");
		DoubleInteraction.OnLeftInteractionReady.AddUFunction(this, n"TopInteracted");
		DoubleInteraction.OnRightInteractionReady.AddUFunction(this, n"BottomInteracted");
		DoubleInteraction.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"CanceledInteraction");

		ChangeSizeComp.OnCharacterChangedSize.AddUFunction(this, n"CodyChangedSize");
		DoubleInteraction.RightInteraction.DisableForPlayer(Game::GetMay(), n"WorldUp");
	}

	UFUNCTION(NotBlueprintCallable)
	void CodyChangedSize(FChangeSizeEventTempFix Size)
	{
		if (Size.NewSize == ECharacterSize::Large || Size.NewSize == ECharacterSize::Small)
		{
			DoubleInteraction.LeftInteraction.DisableForPlayer(Game::GetCody(), n"Size");
		}
		else
		{
			DoubleInteraction.LeftInteraction.EnableForPlayer(Game::GetCody(), n"Size");
		}
	}

	UFUNCTION()
	void ForceMoveToEnd()
	{
		SetActorLocation(EndLocation);
	}

	UFUNCTION(NotBlueprintCallable)
	void TopInteracted(AHazePlayerCharacter Player)
	{
		bTopInteracted = true;
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LeverStart;
		TopLeverRoot.PlaySlotAnimation(AnimParams);
		UHazeAkComponent::HazePostEventFireForget(JoystickInteractAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void BottomInteracted(AHazePlayerCharacter Player)
	{
		bBottomInteracted = true;
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = LeverStart;
		BottomLeverRoot.PlaySlotAnimation(AnimParams);
		UHazeAkComponent::HazePostEventFireForget(JoystickInteractAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void CanceledInteraction(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		if (bIsLeftInteraction)
		{
			bTopInteracted = false;
			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = LeverExit;
			FHazeAnimationDelegate OnFinished;
			OnFinished.BindUFunction(this, n"TopLeverFullyReset");
			TopLeverRoot.PlaySlotAnimation(FHazeAnimationDelegate(), OnFinished, AnimParams);
			Interaction.Disable(n"LeverReset");
			UHazeAkComponent::HazePostEventFireForget(JoystickCancelInteractAudioEvent, this.GetActorTransform());
		}
		else
		{
			bBottomInteracted = false;
			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = LeverExit;
			FHazeAnimationDelegate OnFinished;
			OnFinished.BindUFunction(this, n"BottomLeverFullyReset");
			BottomLeverRoot.PlaySlotAnimation(FHazeAnimationDelegate(), OnFinished, AnimParams);
			Interaction.Disable(n"LeverReset");
			UHazeAkComponent::HazePostEventFireForget(JoystickCancelInteractAudioEvent, this.GetActorTransform());
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void TopLeverFullyReset()
	{
		DoubleInteraction.LeftInteraction.Enable(n"LeverReset");
	}

	UFUNCTION(NotBlueprintCallable)
	void BottomLeverFullyReset()
	{
		DoubleInteraction.RightInteraction.Enable(n"LeverReset");
	}

	UFUNCTION(NotBlueprintCallable)
	void DoubleInteractionCompleted()
	{
		DoubleInteraction.Disable(n"PlatformMoving");
		StartMovingPlatform();
		OnStartedMoving.Broadcast();
		
		BlockRespawn();

		bMayDied = false;
		bCodyDied = false;
		BindPlayerDeathEvent();

		StartTopDoor.CloseDoor();
		StartBottomDoor.CloseDoor();

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(Player);
			CrumbComp.MakeCrumbsUseCustomWorldCalculator(URelativeCrumbLocationCalculator::StaticClass(), this, PlatformRoot);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (Game::GetMay().MovementWorldUp.Equals(FVector(0.f, 0.f, -1.f), 0.1f))
		{
			if (!bMayHasCorrectWorldUp)
			{
				bMayHasCorrectWorldUp = true;
				DoubleInteraction.RightInteraction.EnableForPlayer(Game::GetMay(), n"WorldUp");
			}
		}
		else
		{
			if (bMayHasCorrectWorldUp)
			{
				bMayHasCorrectWorldUp = false;
				DoubleInteraction.RightInteraction.DisableForPlayer(Game::GetMay(), n"WorldUp");
			}
		}
	}

	void BindPlayerDeathEvent()
	{
		FOnPlayerDied PlayerDiedDelegate;
		PlayerDiedDelegate.BindUFunction(this, n"PlayerDied");
		BindOnPlayerDiedEvent(PlayerDiedDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayerDied(AHazePlayerCharacter Player)
	{
		if (!HasControl())
			return;

		if (Player.IsCody())
			bCodyDied = true;
		else
			bMayDied = true;

		if (bCodyDied && bMayDied)
			NetBothPlayersDied();
	}

	UFUNCTION(NetFunction)
	void NetBothPlayersDied()
	{
		UnblockRespawn();
		ClearOnPlayerDiedEvent();
		StartResetting();

		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(CurPlayer);
			CrumbComp.RemoveCustomWorldCalculator(this);
		}

		System::SetTimer(this, n"PlayRespawnBark", 1.f, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void PlayRespawnBark()
	{
		VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationSideScrollerDeath");
		if (bTriggerCrouchTutorialOnNextRespawn)
		{
			FTutorialPrompt Prompt;
			Prompt.Action = ActionNames::MovementCrouch;
			Prompt.DisplayType = ETutorialPromptDisplay::ActionHold;
			Prompt.MaximumDuration = 4.f;
			Prompt.Text = CrouchText;

			Game::GetMay().ShowTutorialPromptWorldSpace(Prompt, this, ScreenSpaceOffset = 175.f);
			Game::GetCody().ShowTutorialPromptWorldSpace(Prompt, this, ScreenSpaceOffset = -200.f);

			System::SetTimer(this, n"RemoveTutorials", 6.f, false);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void RemoveTutorials()
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
			Player.RemoveTutorialPromptByInstigator(this);
	}

	void StartMovingPlatform()
	{
		MovePlatformTimeLike.SetPlayRate(0.075f);
		MovePlatformTimeLike.PlayFromStart();
		HazeAkCompPlatform.HazePostEvent(PlatformStartMoveAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMovePlatform(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(StartLocation, EndLocation, CurValue);
		SetActorLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMovePlatform()
	{
		if (HasControl())
			NetFinishMovePlatform(bResetting);
	}

	UFUNCTION(NetFunction)
	void NetFinishMovePlatform(bool bMovingBack)
	{
		if (bMovingBack)
		{
			bResetting = false;
			StartTopDoor.OpenDoor();
			StartBottomDoor.OpenDoor();

			HazeAkCompPlatform.HazePostEvent(PlatformStopMoveAudioEvent);

			FHazePlaySlotAnimationParams AnimParams;
			AnimParams.Animation = LeverExit;
			FHazeAnimationDelegate OnFinished;
			UHazeAkComponent::HazePostEventFireForget(JoystickCancelInteractAudioEvent, this.GetActorTransform());
			OnFinished.BindUFunction(this, n"LeversFullyReset");
			TopLeverRoot.PlaySlotAnimation(FHazeAnimationDelegate(), OnFinished, AnimParams);
			BottomLeverRoot.PlaySlotAnimation(AnimParams);

		}
		else
		{
			ClearOnPlayerDiedEvent();
			EndTopDoor.CloseDoor();
			EndBottomDoor.CloseDoor();
			UnblockRespawn();
			HazeAkCompPlatform.HazePostEvent(PlatformStopMoveAudioEvent);

			for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
			{
				UHazeCrumbComponent CrumbComp = UHazeCrumbComponent::Get(CurPlayer);
				CrumbComp.RemoveCustomWorldCalculator(this);
			}

			if (HasControl())
				NetPlayOtherPlayerDiedBark(bMayDied, bCodyDied);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetPlayOtherPlayerDiedBark(bool bMayDead, bool bCodyDead)
	{
		if (bMayDied)
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationSideScrollerDeathReplyCody");
		else if (bCodyDied)
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationSideScrollerDeathReplyMay");
	}

	UFUNCTION(NotBlueprintCallable)
	void LeversFullyReset()
	{
		DoubleInteraction.Enable(n"PlatformMoving");
	}

	UFUNCTION()
	void StartResetting()
	{
		bResetting = true;
		MovePlatformTimeLike.SetPlayRate(0.15f);
		MovePlatformTimeLike.Reverse();
		OnResetting.Broadcast();
	}

	void BlockRespawn()
	{
		if (bRespawnBlocked)
			return;

		bRespawnBlocked = true;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(n"Respawn", this);
		}
	}

	void UnblockRespawn()
	{
		if (!bRespawnBlocked)
			return;

		bRespawnBlocked = false;
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(n"Respawn", this);
		}
	}
}
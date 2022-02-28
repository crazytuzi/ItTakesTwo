import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpaceSpringBoard;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SizeBasedValveCog;

class ASizeBasedValve : AValveTurnInteractionActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InvalidSizeInteractionComp;

	UPROPERTY(DefaultComponent)
	UCharacterChangeSizeCallbackComponent ChangeSizeCallbackComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 8000.f;

	UPROPERTY(DefaultComponent)
	UHazeNetworkControlSideInitializeComponent ControlSideComp;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence TooSmallAnimation;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartValveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopValveAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ValveFullyTurnedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ValveStoppedAfterReleaseAudioEvent;

	UPROPERTY(NotEditable)
	float CurrentLerpValue = 0.f;

	UPROPERTY(NotEditable)
	FRotator TargetRot = FRotator(0.f, 0.f, 360.f);

	UPROPERTY()
	ASpaceSpringBoard TargetSpringBoard;

	UPROPERTY()
	TArray<ASizeBasedValveCog> Cogs;

	bool bInteracting = false;
	bool bValveReleased = false;
	bool bValveFullyTurned = false;

	float LastLerpValue;
	float LastTurnSpeed;
	float LastTurnProgress;
	float LastTurnDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		SetActorTickEnabled(true);

		ChangeSizeCallbackComp.OnCharacterChangedSize.AddUFunction(this, n"ChangedSize");
		InvalidSizeInteractionComp.OnActivated.AddUFunction(this, n"InvalidSizeInteractionActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	void ChangedSize(FChangeSizeEventTempFix NewSize)
	{
		if (NewSize.NewSize == ECharacterSize::Small)
		{
			EnterInteraction.Disable(n"Size");
			InvalidSizeInteractionComp.Enable(n"Size");
		}
		else if (NewSize.NewSize == ECharacterSize::Medium)
		{
			EnterInteraction.Disable(n"Size");
			InvalidSizeInteractionComp.Enable(n"Size");
		}
		else if (NewSize.NewSize == ECharacterSize::Large)
		{
			InvalidSizeInteractionComp.Disable(n"Size");
			EnterInteraction.Enable(n"Size");
		}
	}

	void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Super::OnInteractionActivated(Component, Player);
		HazeAudio::SetPlayerPanning(HazeAkComp, Player);
		HazeAkComp.HazePostEvent(StartValveAudioEvent);
		TargetSpringBoard.HazeAkComp.HazePostEvent(TargetSpringBoard.StartSpringAudioEvent);

		bInteracting = true;
	}

	UFUNCTION()
    void InvalidSizeInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		Player.SmoothSetLocationAndRotation(Player.ActorLocation, Component.WorldRotation);
		Player.PlayEventAnimation(Animation = TooSmallAnimation);
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bInteracting && Game::GetCody().HasControl())
			SyncComponent.Value = FMath::FInterpConstantTo(SyncComponent.Value, 0.f, DeltaTime, 225.f);
		
		CurrentLerpValue = SyncComponent.Value / MaxValue;
		TargetSpringBoard.UpdateTension(CurrentLerpValue);

		for (ASizeBasedValveCog CurCog : Cogs)
		{
			CurCog.UpdateLerpValue(CurrentLerpValue);
		}

		float TurnProgress = SyncComponent.Value;
		float TurnDirection = FMath::Sign(TurnProgress - LastTurnProgress);
		if(TurnDirection != LastTurnDirection)
			LastTurnDirection = TurnDirection;

		float TurnSpeed = FMath::Abs(TurnDirection);
		if(TurnSpeed != LastTurnSpeed)
		{
			HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_Rotators_Velocity", TurnSpeed);
			TargetSpringBoard.HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_Rotators_Velocity", TurnSpeed);
			LastTurnSpeed = TurnSpeed;
		}
		LastTurnProgress = TurnProgress;

		if(bValveReleased && CurrentLerpValue == 0.0)
		{
			bValveReleased = false;
			HazeAkComp.HazePostEvent(ValveStoppedAfterReleaseAudioEvent);
			HazeAkComp.HazePostEvent(StopValveAudioEvent);
			TargetSpringBoard.HazeAkComp.HazePostEvent(TargetSpringBoard.SpringStoppedAfterReleaseAudioEvent);
			TargetSpringBoard.HazeAkComp.HazePostEvent(TargetSpringBoard.StopSpringAudioEvent);
		}

		if(!bValveFullyTurned && CurrentLerpValue >= 1.f)
		{
			bValveFullyTurned = true;
			HazeAkComp.HazePostEvent(ValveFullyTurnedAudioEvent);
			TargetSpringBoard.HazeAkComp.HazePostEvent(TargetSpringBoard.SpringFullyTurnedAudioEvent);
		}

		else if(CurrentLerpValue != 1.f)
			bValveFullyTurned = false;


	}

	void EndInteraction(AHazePlayerCharacter Player) override
	{
		if(CurrentLerpValue == 0.f)
		{
			HazeAkComp.HazePostEvent(StopValveAudioEvent);
			TargetSpringBoard.HazeAkComp.HazePostEvent(TargetSpringBoard.StopSpringAudioEvent);
		}

		if (Game::GetMay().HasControl())
			NetReleaseValve();
	}

	UFUNCTION(NetFunction)
	void NetReleaseValve()
	{
		bInteracting = false;
		EnterInteraction.Enable(n"PlayerIsInInteraction");
		TargetSpringBoard.ValveReleased();
		OnExit.Broadcast(this, Game::GetCody());
		if(CurrentLerpValue > 0.f)
		{
			bValveReleased = true;
		}
		PlayerStatus = EValveTurnInteractionAnimationType::None;
		AnimationSpeed = 0;
		CurrentActivePlayer = nullptr;
	}
}
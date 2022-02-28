import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.PillowFort.TechDoubleInteract.TVHackingActor;
import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Vino.Tutorial.TutorialPrompt;

class ATVHackingRemote : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase JoystickSkelMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BaseCollider;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ButtonMashPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;

	UPROPERTY()
	ATVHackingActor TVActor;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent RemoteHazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;

	FTimerHandle ReenableInteractTimerHandle;	

	UPROPERTY()
	TSubclassOf<UHazeCapability> InputCapability;

	UPROPERTY()
	TSubclassOf<UHazeCapability> StickCapability;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnInteractJoystickAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnExitJoystickAudioEvent;

	UPROPERTY(Category = "Settings")
	bool bIsLeftInteraction = false;

	UPROPERTY(Category = "Settings")
	FTutorialPrompt StickTutorial;

	FRotator CurrentRotation;
	FVector2D NewRotation;

	FRotator TargetRotation;
	FVector2D CurrentInput;

	bool bIsInteractedWith = false;
	bool bButtonMashActive = false;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UMaterialInstance LeftMaterial;

	UPROPERTY(Category = "Setup", EditDefaultsOnly)
	UMaterialInstance RightMaterial;

	AHazePlayerCharacter InteractingPlayer;
	UButtonMashDefaultHandle ButtonMashHandle;

	float ButtonMashProgressSpeed = 6.0f;
	float ButtonMash = 0.f;

	float NetworkNewTime = 0.f;
	float NetworkRate = 0.075f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractComp.OnActivated.AddUFunction(this, n"OnInteracted");

		if(TVActor != nullptr)
		{
			TVActor.StartCounterHackEvent.AddUFunction(this, n"ActivateButtonMash");
			TVActor.CompletedCounterHackEvent.AddUFunction(this, n"DeactivateButtonmash");
			TVActor.HackCompleteEvent.AddUFunction(this, n"InteractionCompleted");
			TVActor.FinalLevelCompleted.AddUFunction(this, n"LockInteractionExit");
		}

		if(bIsLeftInteraction)
		{
			InteractComp.SetExclusiveForPlayer(EHazePlayer::May);
		}
		else
		{
			InteractComp.SetExclusiveForPlayer(EHazePlayer::Cody);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!bButtonMashActive || InteractingPlayer == nullptr)
			return;
		
		float CalculatedButtonMash = CalculateButtonMash(DeltaTime);

		if(Network::IsNetworked())
		{
			if(VerifyNetSendInterval(DeltaTime) && InteractingPlayer.HasControl())
			{
				if(bIsLeftInteraction)
					TVActor.HandlePlayer1ButtonMash(CalculatedButtonMash);
				else
					TVActor.HandlePlayer2ButtonMash(CalculatedButtonMash);
			}
		}
		else
		{
			if(bIsLeftInteraction)
				{
					if(bButtonMashActive)
					{
						TVActor.HandlePlayer1ButtonMash(CalculatedButtonMash);
					}
				}
				else
				{
					if(bButtonMashActive)
					{
						TVActor.HandlePlayer2ButtonMash(CalculatedButtonMash);
					}
				}
			}
	}

	bool VerifyNetSendInterval(float DeltaTime)
	{
		if(NetworkNewTime <= System::GameTimeInSeconds)
		{
			NetworkNewTime = System::GameTimeInSeconds + NetworkRate;

			return true;
		}

		return false;
	}

	UFUNCTION()
	void OnInteracted(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		InteractingPlayer = Player;
		ActivateRemote(Player);
		InteractComp.Disable(n"InUse");
	}

	UFUNCTION()
	void OnInteractionExit(AHazePlayerCharacter Player, bool IsLeftPlayer)
	{
		if(bIsLeftInteraction)
		{
			TVActor.ExitedLeftRemote();
		}
		else
		{
			TVActor.ExitedRightRemote();
		}
		
		if(!TVActor.bInteractionCompleted)
			RemoteHazeAkComp.HazePostEvent(OnExitJoystickAudioEvent);
			
		Player.RemoveCapability(InputCapability);
		Player.RemoveCapability(StickCapability);
		bIsInteractedWith = false;

		if(HasControl())
			TVActor.VerifyCameraToDeactivate(Player, bIsLeftInteraction);

		InteractingPlayer = nullptr;

		SetActorTickEnabled(false);

		ReenableInteractTimerHandle = System::SetTimer(this, n"ReenableInteractAfterTimer", 0.5f, false);
	}

	UFUNCTION()
	void ActivateRemote(AHazeActor Actor)
	{
		SetActorTickEnabled(true);

		InteractingPlayer.SetCapabilityAttributeObject(n"TVActor", TVActor);
		InteractingPlayer.SetCapabilityAttributeObject(n"TVRemoteActor", this);
		InteractingPlayer.AddCapability(InputCapability);
		InteractingPlayer.AddCapability(StickCapability);

		bIsInteractedWith = true;

		RemoteHazeAkComp.HazePostEvent(OnInteractJoystickAudioEvent);

		if(bIsLeftInteraction)
		{
			InteractingPlayer.SetCapabilityActionState(n"InteractingLeftTV", EHazeActionState::Active);
			TVActor.InteractedLeftRemote(InteractingPlayer);
		}
		else
		{
			InteractingPlayer.SetCapabilityActionState(n"InteractingRightTV", EHazeActionState::Active);
			TVActor.InteractedRightRemote(InteractingPlayer);
		}

		TVActor.VerifyCameraToActivate(InteractingPlayer);
	}

	UFUNCTION()
	void InteractionCompleted(AHazePlayerCharacter LeftPlayer, AHazePlayerCharacter RightPlayer, AHazePlayerCharacter FullScreenCharacter)
	{
		if(bIsLeftInteraction && InteractingPlayer != nullptr)
			InteractingPlayer.SetCapabilityActionState(n"InteractingLeftTV", EHazeActionState::Inactive);
		else if(InteractingPlayer != nullptr)
			InteractingPlayer.SetCapabilityActionState(n"InteractingRightTV", EHazeActionState::Inactive);
	}

	UFUNCTION()
	void ReenableInteractAfterTimer()
	{
		InteractComp.EnableAfterFullSyncPoint(n"InUse");
	}

	UFUNCTION()
	void LockInteractionExit()
	{
		InteractingPlayer.SetCapabilityActionState(n"LockedIntoInteraction", EHazeActionState::Active);
	}

	float CalculateButtonMash(float DeltaTime)
	{
		ButtonMash = ButtonMashHandle.MashRateControlSide * ButtonMashProgressSpeed * DeltaTime;
		return ButtonMash;
	}

	UFUNCTION()
	void ActivateButtonMash()
	{
		ButtonMashHandle = StartButtonMashDefaultAttachToComponent(InteractingPlayer, ButtonMashPosition, NAME_None, FVector::ZeroVector);
		bButtonMashActive = true;
	}

	UFUNCTION()
	void DeactivateButtonmash()
	{
		StopButtonMash(ButtonMashHandle);
		bButtonMashActive = false;
		ButtonMash = 0;
	}
}
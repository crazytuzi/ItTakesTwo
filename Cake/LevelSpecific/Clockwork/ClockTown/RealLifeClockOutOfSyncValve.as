import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;
import Vino.Tutorial.TutorialStatics;

event void FRealLifeClockOutOfSyncValveEvent(AHazePlayerCharacter Player);

UCLASS(Abstract)
class ARealLifeClockOutOfSyncValve : AValveTurnInteractionActor
{
	default EnterInteraction.FocusShape.SphereRadius = 50.f;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ArmMesh;

	UPROPERTY(DefaultComponent, Attach = ArmMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ValveRevealAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ValveDisableAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ValveStartInteractionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ValveStopInteractionAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RevealTimeLike;
	default RevealTimeLike.Duration = 1.5f;

	UPROPERTY()
	FRealLifeClockOutOfSyncValveEvent OnInteractionStarted;

	UPROPERTY()
	FRealLifeClockOutOfSyncValveEvent OnInteractionCanceled;

	UPROPERTY()
	bool bControlsMinutes = true;

	UPROPERTY(NotEditable)
	bool bInteracting = false;
	AHazePlayerCharacter InteractingPlayer;

	UPROPERTY(NotEditable)
	float LastValue = 0.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 8000.f;
	default DisableComponent.bRenderWhileDisabled = true;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ArmMesh.SetCullDistance(Editor::GetDefaultCullingDistance(ArmMesh) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		RevealTimeLike.BindUpdate(this, n"UpdateReveal");
		RevealTimeLike.BindFinished(this, n"FinishReveal");

		EnterInteraction.Disable(n"Revealed");
		SetActorTickEnabled(false);

		ValveSkeletalMesh.AttachToComponent(ArmMesh, AttachmentRule = EAttachmentRule::KeepWorld);

		ArmMesh.SetRelativeRotation(FRotator(-80.f, ArmMesh.RelativeRotation.Yaw, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bInteracting)
			return;

		if (SyncComponent.Value != LastValue)
		{
			if (SyncComponent.Value > LastValue)
				BP_SetClockRotationStatus(ERealLifeClockOutOfSyncRotationDirection::Clockwise);
			else
				BP_SetClockRotationStatus(ERealLifeClockOutOfSyncRotationDirection::CounterClockwise);
			
			LastValue = SyncComponent.Value;
		}
		else
		{
			BP_SetClockRotationStatus(ERealLifeClockOutOfSyncRotationDirection::Idle);
		}
	}
	UFUNCTION(BlueprintEvent)
	void BP_SetClockRotationStatus(ERealLifeClockOutOfSyncRotationDirection Direction) {}

	void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Super::OnInteractionActivated(Component, Player);

		LastValue = SyncComponent.Value;

		bInteracting = true;
		InteractingPlayer = Player;

		ShowCancelPrompt(Player, this);

		OnInteractionStarted.Broadcast(Player);

		HazeAkComp.HazePostEvent(ValveStartInteractionAudioEvent);
	}

	void EndInteraction(AHazePlayerCharacter Player) override
	{
		bInteracting = false;
		EnterInteraction.Enable(n"PlayerIsInInteraction");

		OnExit.Broadcast(this, Player);
		
		RemoveCancelPromptByInstigator(InteractingPlayer, this);

		OnInteractionCanceled.Broadcast(InteractingPlayer);

		BP_SetClockRotationStatus(ERealLifeClockOutOfSyncRotationDirection::Automatic);

		HazeAkComp.HazePostEvent(ValveStopInteractionAudioEvent);
	}

	UFUNCTION()
	void DisableValve()
	{
		EnterInteraction.Disable(n"ClockSynced");
		SetActorTickEnabled(false);
		RevealTimeLike.ReverseFromEnd();
		HazeAkComp.HazePostEvent(ValveDisableAudioEvent);
	}

	UFUNCTION()
	void RevealValve()
	{
		RevealTimeLike.PlayFromStart();
		HazeAkComp.HazePostEvent(ValveRevealAudioEvent);
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateReveal(float CurValue)
	{
		float CurPitch = FMath::Lerp(-80.f, 0.f, CurValue);

		ArmMesh.SetRelativeRotation(FRotator(CurPitch, ArmMesh.RelativeRotation.Yaw, 0.f));
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishReveal()
	{
		if (RevealTimeLike.IsReversed())
			return;
			
		EnterInteraction.Enable(n"Revealed");
		SetActorTickEnabled(true);
	}
}

enum ERealLifeClockOutOfSyncRotationDirection
{
	Idle,
	Clockwise,
	CounterClockwise,
	Automatic
}
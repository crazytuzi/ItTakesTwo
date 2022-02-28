import Cake.LevelSpecific.Music.NightClub.DJStationComponent;
import Cake.LevelSpecific.Music.NightClub.UI.DJStationUIWidget;
import Cake.LevelSpecific.Music.NightClub.DJStandType;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.NightClub.DJDanceCommon;


class UDJVinylDummyComponent : UActorComponent
{
	float RhythmActorDummyComponentVisualizerTime = 0.0f;
}

#if EDITOR

class UDJVinylDummyComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = UDJVinylDummyComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        UDJVinylDummyComponent Comp = Cast<UDJVinylDummyComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
		{
			return;
		}

		Comp.RhythmActorDummyComponentVisualizerTime += 0.1f;

		// Just visual fluff
		float R = FMath::MakePulsatingValue(Comp.RhythmActorDummyComponentVisualizerTime, 0.1f);
		float G = FMath::MakePulsatingValue(Comp.RhythmActorDummyComponentVisualizerTime, 0.2f);
		float B = FMath::MakePulsatingValue(Comp.RhythmActorDummyComponentVisualizerTime, 0.3f);

		ADJVinylPlayer DJVinyl = Cast<ADJVinylPlayer>(Comp.Owner);
		const FVector WorldLocation = DJVinyl.DJLocation;

		DrawWireSphere(WorldLocation, DJVinyl.TriggerRadius, FLinearColor(R, G, B), 3.0f, 12);
		DrawArrow(WorldLocation, WorldLocation - (FVector::UpVector * 500.0f), FLinearColor::Green, 20.0f, 5.0f);
    }   
}

#endif // EDITOR

EDJStandType GetDJStandTypeFromActor(AHazeActor HazeActor)
{
	ADJVinylPlayer DJVinyl = Cast<ADJVinylPlayer>(HazeActor);

	if(DJVinyl != nullptr)
	{
		return DJVinyl.DJStandType;
	}

	return EDJStandType::None;
}

event void FDJStationResultsDelegate(ADJVinylPlayer DJStand, AHazePlayerCharacter PlayerCharacter, float BassDropValue);
event void FDJStationStartDelegate(ADJVinylPlayer DJStand);

enum EDJStationState
{
	Active,
	Inactive,
	Success,
	Failure
}

class ADJVinylPlayer : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;
	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent DJStationMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent ProgressBarMesh;

	UPROPERTY(DefaultComponent)
	USceneComponent VFXLoc;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeLazyPlayerOverlapComponent PlayerOverlap;
	default PlayerOverlap.Shape.Type = EHazeShapeType::Box;
	default PlayerOverlap.Shape.BoxExtends = FVector(130.0f, 235.0f, 155.0f);
	default PlayerOverlap.ResponsiveDistanceThreshold = 5000.0f;

	// We attach the widget to this scene node.
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent WidgetLocation;
	default WidgetLocation.RelativeLocation = FVector(0.0f, 55.0f, 118.0f);

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;

	UPROPERTY(DefaultComponent, NotEditable)
	UDJVinylDummyComponent DJVinylComponentVisualizer;
	default DJVinylComponentVisualizer.bIsEditorOnly = true;

	FTimerHandle OverlapTimerHandle;
	FTimerHandle SyncProgressTimerHandle;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncedProgress;

	AHazePlayerCharacter MainDJPlayer;
	AHazePlayerCharacter SecondaryDJPlayer;

	TArray<AHazePlayerCharacter> AvailablePlayers;

	float ProgressRate = 0.0f;

	// At how much progress will this dj station start with.
	UPROPERTY(Category = Setup, meta = (ClampMin = 0.1))
	float StartProgress = 0.4f;

	UPROPERTY(Category = Setup)
	float DecayRate = 0.1f;

	UPROPERTY(Category = Setup)
	float ProgressMultiplier = 0.1f;

	UPROPERTY(Category = Setup)
	float StationSuccessValue = 0.06f;

	UPROPERTY(Category = Setup)
	float StationFailureValue = 0.05f;

	UPROPERTY(Category = Setup)
	AActor FloorIndicatorActor;

	UPROPERTY(Category = Setup)
	EDJStandType DJStandType = EDJStandType::None;

	UPROPERTY(Category = VFX)
	UNiagaraSystem OnSuccessEffect = Asset("/Game/Effects/Niagara/GameplayDancePerfect_01.GameplayDancePerfect_01");

	UPROPERTY(Category = VFX)
	UNiagaraSystem OnFailEffect = Asset("/Game/Effects/Niagara/GameplayDanceMiss_01.GameplayDanceMiss_01");

	// Paste the value from the animation and convert between world/local space blabla
	UPROPERTY(Category = Setup, meta = (MakeEditWidget))
	FTransform MayTransform;

	UPROPERTY(Category = Setup, meta = (MakeEditWidget))
	FTransform CodyTransform;

	UPROPERTY()
	FDJStationResultsDelegate OnSuccess;
	UPROPERTY()
	FDJStationResultsDelegate OnFailure;
	UPROPERTY()
	FDJStationStartDelegate OnStartStation;

	UPROPERTY()
	TSubclassOf<UHazeCapability> AudioCapability;

	UPROPERTY(Category = UI)
	TSubclassOf<UDJStationUIWidget> DJStationWidgetClass;
	private UDJStationUIWidget DJStationWidgetInstance = nullptr;

	EDJStationState StationState = EDJStationState::Inactive;

	float Remote_CurrentProgress = 0.0f;
	float Remove_AccumulatedProgress = 0.0f;

	bool bForceComplete = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UClass AudioClass = AudioCapability.Get();
		if(AudioClass != nullptr)
			AddCapability(AudioClass);

		PlayerOverlap.OnPlayerBeginOverlap.AddUFunction(this, n"Handle_OverlapBegin");
		PlayerOverlap.OnPlayerEndOverlap.AddUFunction(this, n"Handle_OverlapEnd");
	}

    UFUNCTION(NotBlueprintCallable)
    private void Handle_OverlapBegin(AHazePlayerCharacter InPlayer)
    {
		UDJStationComponent DJStationComp = UDJStationComponent::Get(InPlayer);
		DJStationComp.VinylPlayer = this;
		AvailablePlayers.Add(InPlayer);
    }

    UFUNCTION(NotBlueprintCallable)
    private void Handle_OverlapEnd(AHazePlayerCharacter InPlayer)
    {
		UDJStationComponent DJStationComp = UDJStationComponent::Get(InPlayer);
		if(DJStationComp != nullptr)
			DJStationComp.VinylPlayer = nullptr;
		AvailablePlayers.Remove(InPlayer);
    }

	UFUNCTION(BlueprintPure)
	bool IsStationActive() const
	{
		return StationState == EDJStationState::Active;
	}

	// Called from Dance manager 
	void OnStartDJ()
	{
		SetActorTickEnabled(true);
	}

	void AddToProgress(float NewProgress)
	{
		if(HasControl())
		{
			ProgressRate += NewProgress;
		}
		else
		{
			Remove_AccumulatedProgress += NewProgress;
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetAddToProgress(float NewProgress)
	{
		if(!HasControl())
			return;

		ProgressRate += NewProgress;
	}

	float Remote_UpdateProgress = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Remote_UpdateProgress -= DeltaTime;
		
		if(HasControl() && bPendingStart)
		{
			bPendingStart = false;
			_Internal_NetStartDJStand();
		}
		
		if(HasControl() && StationState == EDJStationState::Active && bIsDJStandActive)
		{
			const bool bCanChangeState = CanChangeState();
			
			SyncedProgress.Value = Math::Saturate(FMath::FInterpTo(SyncedProgress.Value, SyncedProgress.Value + (ProgressRate * ProgressMultiplier * DeltaTime), DeltaTime, 20.0f ));
			ProgressRate = 0.0f;
			BP_OnProgress(Progress);

			if(bCanChangeState)
			{
				if(IsProgressFailure())
				{
					NetFailure();
				}
				else if(IsProgressSuccess())
				{
					NetSuccess();
				}
			}

			if(ShouldDecayProgress())
				SyncedProgress.Value = Math::Saturate(FMath::FInterpTo(SyncedProgress.Value, SyncedProgress.Value - DecayRate * DeltaTime, DeltaTime, 25.0f) );
		}
		else if(!HasControl())
		{
			Remote_CurrentProgress = FMath::FInterpConstantTo(Remote_CurrentProgress, Remote_GetTargetProgress(), DeltaTime, 100.0f);
			BP_OnProgress(Progress);

			if(!FMath::IsNearlyZero(Remove_AccumulatedProgress) && Remote_UpdateProgress < 0.0f)
			{
				NetAddToProgress(Remove_AccumulatedProgress);
				Remove_AccumulatedProgress = 0.0f;
				Remote_UpdateProgress = 0.15f;
			}
		}

		// On remote we need to wait for the progress to catch up before we can proceed.
		if(StationState == EDJStationState::Success)
		{
			if(HasControl())
			{
				OnDJStandSuccess();
			}
			else if(!HasControl() && IsProgressSuccess())
			{
				OnDJStandSuccess();
			}
		}
		else if(StationState == EDJStationState::Failure)
		{
			if(HasControl())
			{
				OnDJStandFailure();
			}
			else if(!HasControl() && IsProgressFailure())
			{
				OnDJStandFailure();
			}
		}

		if(HasControl() && AvailablePlayers.Num() != 0
		&& AvailablePlayers[0].HasControl() != HasControl())
		{
			NetUpdateControlSide(AvailablePlayers[0]);
		}

#if TEST
		if(bDebugEnabled)
			BP_OnDebugUpdate(DeltaTime);
#endif // TEST
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetUpdateControlSide(AHazePlayerCharacter Player)
	{
		SetControlSide(Player);
	}

	UFUNCTION(NetFunction)
	private void NetSuccess()
	{
		StationState = EDJStationState::Success;
		SyncedProgress.Value = 0.0f;
	}

	UFUNCTION(NetFunction)
	private void NetFailure()
	{
		StationState = EDJStationState::Failure;
		SyncedProgress.Value = 0.0f;
	}

	bool CanChangeState() const
	{
		if(bForceComplete)
			return true;
#if !RELEASE
		if(CVar_DebugDJDisableStations.GetInt() == 1)
		{
			return false;
		}
#endif // !RELEASE
		return true;
	}

	void StopDJPlayer()
	{
		ClearWidget();
		bIsDJStandActive = false;
	}

	bool bIsDJStandActive = false;

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Progress"))
	void BP_OnProgress(float NewProgress) {}

	UPROPERTY()
	bool bIsSpinning = false;

	UPROPERTY()
	float SpinDiffSize = 0.f;

	UPROPERTY()
	float ButtonMashRate;

	UPROPERTY()
	float TargetLightTableRate = 0.f;

	UPROPERTY()
	float TriggerRadius = 170.0f;
	float GetTriggerRadiusSq() const property { return FMath::Square(TriggerRadius); }

	UPROPERTY(meta = (MakeEditWidget))
	FVector Origin;

	// Get the transformed location of where the DJ is intended to stand.
	UFUNCTION()
	FVector GetDJLocation() const property
	{
		return ActorTransform.TransformPosition(Origin);
	}

	void SetToComplete()
	{
		NetSuccess();
	}

	UFUNCTION(NetFunction)
	private void NetSetToComplete()
	{
		SyncedProgress.Value = 1.0f;
		bForceComplete = true;
	}

	// Call this, from somehwere else (like blueprint) to start the dj-stand. Should initialize widgets, lights and whatever else is nice to have.
	UFUNCTION()
	void StartDJStand(bool bNetworkSyncStart = false)
	{
		// Something else that is networked might be calling this so by default we are not syncing this start.
		if(bNetworkSyncStart)
		{
			NetStartDJStand();
		}
		else
		{
			Internal_StartDJStand();
		}
	}

	bool bPendingStart = false;
	UFUNCTION(NetFunction)
	void NetStartDJStand()
	{
		if(!HasControl())
			return;

		bPendingStart = true;
	}

	private void _Internal_NetStartDJStand()
	{
		Internal_StartDJStand();
	}

	private void Internal_StartDJStand()
	{
		bIsDJStandActive = true;	// Will trigger the DJStandProgressCapability that networks progress and events for success / fail.
		StationState = EDJStationState::Active;
		SyncedProgress.Value = StartProgress;
		OnDJStandStart();
	}

	UFUNCTION(BlueprintPure)
	float GetProgress() const property
	{
		if(HasControl())
			return SyncedProgress.Value;

		return Remote_CurrentProgress;
	}

	float Remote_GetTargetProgress() const
	{
		if(StationState == EDJStationState::Active)
			return SyncedProgress.Value;
		else if(StationState == EDJStationState::Success)
			return 1.0f;
		else if(StationState == EDJStationState::Failure)
			return 0.0f;

		return 0.0f;
	}

	bool IsProgressSuccess() const
	{
		if(HasControl())
			return FMath::IsNearlyEqual(SyncedProgress.Value, 1.0f);
		
		return FMath::IsNearlyEqual(Remote_CurrentProgress, 1.0f);
	}

	bool IsProgressFailure() const
	{
		if(HasControl())
			return FMath::IsNearlyZero(SyncedProgress.Value);
		
		return FMath::IsNearlyZero(Remote_CurrentProgress);
	}

	void OnPlayerAnimationStart() {}
	void OnPlayerAnimationEnd() {}

	bool ShouldDecayProgress() const
	{
		if(StationState == EDJStationState::Success || StationState == EDJStationState::Success)
			return false;

		EGodMode CurGodMode = GetGodMode(PlayerInControl);
		if(CurGodMode == EGodMode::God || CurGodMode == EGodMode::Jesus)
		{
			return false;
		}

		return true;
	}

	// Typically called when button is mashed etc
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Progress Increase"))
	void BP_OnProgressIncrease() {}
	void OnProgressIncrease() 
	{
		BP_OnProgressIncrease();
		Widget_OnProgressIncreased();
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On DJ Stand Start"))
	void BP_OnDJStandStart() {}
	void OnDJStandStart() 
	{
		BP_OnDJStandStart();
		CreateWidget();
		OnStartStation.Broadcast(this);
		ShowFloorIndicator();
		ProgressRate = 0.0f;
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On DJ Stand Failure"))
	void BP_OnDJStandFailure() {}
	void OnDJStandFailure() 
	{
		OnFailure.Broadcast(this, GetClosestPlayer(), StationFailureValue);
		BP_OnDJStandFailure();
		ClearWidget();
		Niagara::SpawnSystemAtLocation(OnFailEffect, VFXLoc.WorldLocation);
		HideFloorIndicator();
		StationState = EDJStationState::Inactive;
		bIsDJStandActive = false;
		bForceComplete = false;
		BP_OnProgress(0.0f);
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On DJ Stand Success"))
	void BP_OnDJStandSuccess() {}
	void OnDJStandSuccess() 
	{
		// Default to COdy just in case
		AHazePlayerCharacter PlayerToSend = Game::Cody;
		if(AvailablePlayers.Num() == 1)
			PlayerToSend = AvailablePlayers[0];
		else
		{
			PlayerToSend = GetClosestPlayer();
		}

		OnSuccess.Broadcast(this, PlayerToSend, StationSuccessValue);
		BP_OnDJStandSuccess();
		ClearWidget();
		Niagara::SpawnSystemAtLocation(OnSuccessEffect, VFXLoc.WorldLocation);
		HideFloorIndicator();
		StationState = EDJStationState::Inactive;
		bIsDJStandActive = false;
		bForceComplete = false;
		BP_OnProgress(0.0f);
	}

	UFUNCTION(BlueprintEvent)
	void ButtonMashPulse() {}

	// When a player activates this dj-stand by moving close enough to it. The player should be able to interact witht his DJ stand after this has been called
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Player Interaction Begin"))
	void BP_OnPlayerInteractionBegin(AHazePlayerCharacter Player) {}
	void OnPlayerInteractionBegin(AHazePlayerCharacter Player)
	{
		BP_OnPlayerInteractionBegin(Player);
		SetCapabilityActionState(n"AudioInteractionStarted", EHazeActionState::ActiveForOneFrame);
		Widget_OnPlayerInteractionBegin(Player);
	}

	// When a player that used to interact with thsi dj-stand no longer does so, most likely by moving away from it.
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Player Interaction End"))
	void BP_OnPlayerInteractionEnd(AHazePlayerCharacter Player) {}
	void OnPlayerInteractionEnd(AHazePlayerCharacter Player)
	{
		BP_OnPlayerInteractionEnd(Player);
		SetCapabilityActionState(n"AudioInteractionStopped", EHazeActionState::ActiveForOneFrame);
		Widget_OnPlayerInteractionEnd(Player);
	}

	FVector GetTargetLocation(AHazePlayerCharacter Player) const
	{
		return Player.IsMay() ? MayLocation : CodyLocation;
	}

	FQuat GetTargetRotation(AHazePlayerCharacter Player) const
	{
		return Player.IsMay() ? MayRotation : CodyRotation;
	}

	FVector GetMayLocation() const property
	{
		return ActorTransform.TransformPosition(MayTransform.Location);
	}

	FVector GetCodyLocation() const property
	{
		return ActorTransform.TransformPosition(CodyTransform.Location);
	}

	FQuat GetMayRotation() const property
	{
		return MayTransform.Rotation;
	}

	FQuat GetCodyRotation() const property
	{
		return CodyTransform.Rotation;
	}

	protected void CreateWidget()
	{
		if(!DJStationWidgetClass.IsValid())
			return;

		if(DJStationWidgetInstance != nullptr)
			return;

		DJStationWidgetInstance = Cast<UDJStationUIWidget>(PlayerInControl.AddWidget(DJStationWidgetClass));
		DJStationWidgetInstance.AttachWidgetToComponent(WidgetLocation);
		DJStationWidgetInstance.SetWidgetShowInFullscreen(true);
	}

	protected void ClearWidget()
	{
		if(DJStationWidgetInstance == nullptr)
			return;

		DJStationWidgetInstance.Player.RemoveWidget(DJStationWidgetInstance);
		DJStationWidgetInstance = nullptr;
	}

	protected void Widget_OnPlayerInteractionBegin(AHazePlayerCharacter InPlayer)
	{	
		if(DJStationWidgetInstance == nullptr)
			return;
		
		if(AvailablePlayers.Num() == 1)
		{
			if(DJStationWidgetInstance.Player != InPlayer)
				DJStationWidgetInstance.OverrideWidgetPlayer(InPlayer);
			DJStationWidgetInstance.OnPlayerInteractionBegin(InPlayer);
		}
		else if(Network::IsNetworked() && DJStationWidgetInstance.Player != PlayerInControl)
		{
				DJStationWidgetInstance.OverrideWidgetPlayer(InPlayer);
		}
	}

	protected void Widget_OnPlayerInteractionEnd(AHazePlayerCharacter InPlayer)
	{
		if(DJStationWidgetInstance == nullptr)
			return;

		if(AvailablePlayers.Num() == 1 && DJStationWidgetInstance.Player != AvailablePlayers[0])
		{
			DJStationWidgetInstance.OverrideWidgetPlayer(AvailablePlayers[0]);
		}
		else if(AvailablePlayers.Num() == 0)
		{
			DJStationWidgetInstance.OnPlayerInteractionEnd(InPlayer);
		}
	}

	protected void Widget_OnProgressIncreased()
	{
		if(DJStationWidgetInstance == nullptr)
			return;

		DJStationWidgetInstance.OnProgressIncreased();
	}

	private void ShowFloorIndicator()
	{
		if(FloorIndicatorActor != nullptr)
		{
			FloorIndicatorActor.SetActorHiddenInGame(false);
		}
	}

	private void HideFloorIndicator()
	{
		if(FloorIndicatorActor != nullptr)
		{
			FloorIndicatorActor.SetActorHiddenInGame(true);
		}
	}

	private bool bDebugEnabled = false;

	void SetDebugEnabled(bool bInDebugEnabled)
	{
		bDebugEnabled = bInDebugEnabled;

		if(bDebugEnabled)
			BP_OnDebugEnabled();
		else
			BP_OnDebugDisabled();
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Debug Enabled"))
	void BP_OnDebugEnabled() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Debug Disabled"))
	void BP_OnDebugDisabled() {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Debug Update"))
	void BP_OnDebugUpdate(float DeltaTime) {}

	AHazePlayerCharacter GetPlayerInControl() const property
	{
		return Game::FirstLocalPlayer;
	}

	AHazePlayerCharacter GetRemotePlayer() const property
	{
		return PlayerInControl.OtherPlayer;
	}

	AHazePlayerCharacter GetClosestPlayer() const
	{
		if(Game::Cody.ActorLocation.DistSquared(ActorLocation) > Game::May.ActorLocation.DistSquared(ActorLocation))
			return Game::May;
		return Game::Cody;
	}
}

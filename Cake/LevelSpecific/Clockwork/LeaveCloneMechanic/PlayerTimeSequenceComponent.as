import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.SequenceCloneActor;
import Vino.Camera.Actors.StaticCamera;

enum ESequenceEventType
{
    OnPlacedClone,
    OnStartedTeleport,
	OnPostStartedTeleport,
	OnTeleportExecuted,
    OnTeleportFinished,
}
delegate void FSequenceDelegate(AHazePlayerCharacter Player);
event void FSequenceEvent(AHazePlayerCharacter Player);

UFUNCTION()
void BindOnSequenceDelegate(ESequenceEventType DelegateType, AHazePlayerCharacter Player, FSequenceDelegate Delegate)
{
    if(Player != nullptr)
    {
        UTimeControlSequenceComponent Comp = UTimeControlSequenceComponent::Get(Player);
        if(Comp != nullptr)
        {
            if(DelegateType == ESequenceEventType::OnPlacedClone)
                Comp.OnPlacedClone.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
            else if(DelegateType == ESequenceEventType::OnStartedTeleport)
                Comp.OnStartedTeleport.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
			else if(DelegateType == ESequenceEventType::OnPostStartedTeleport)
                Comp.OnPostStartedTeleport.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
			else if(DelegateType == ESequenceEventType::OnTeleportExecuted)
                Comp.OnExecuteTeleport.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
            else if(DelegateType == ESequenceEventType::OnTeleportFinished)
                Comp.OnTeleportFinished.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void UnbindOnSequenceDelegate(ESequenceEventType DelegateType, AHazePlayerCharacter Player, FSequenceDelegate Delegate)
{
    if(Player != nullptr)
    {
        UTimeControlSequenceComponent Comp = UTimeControlSequenceComponent::Get(Player);
        if(Comp != nullptr)
        {
            if(DelegateType == ESequenceEventType::OnPlacedClone)
                Comp.OnPlacedClone.Unbind(Delegate.GetUObject(), Delegate.GetFunctionName());
            else if(DelegateType == ESequenceEventType::OnStartedTeleport)
                Comp.OnStartedTeleport.Unbind(Delegate.GetUObject(), Delegate.GetFunctionName());
				else if(DelegateType == ESequenceEventType::OnTeleportExecuted)
                Comp.OnExecuteTeleport.Unbind(Delegate.GetUObject(), Delegate.GetFunctionName());
            else if(DelegateType == ESequenceEventType::OnTeleportFinished)
                Comp.OnTeleportFinished.Unbind(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void ClearSequenceDelegates(AHazePlayerCharacter Player)
{
    if(Player != nullptr)
    {
        UTimeControlSequenceComponent Comp = UTimeControlSequenceComponent::Get(Player);
        if(Comp != nullptr)
		{
			Comp.OnPlacedClone.Clear();
			Comp.OnStartedTeleport.Clear();
			Comp.OnExecuteTeleport.Clear();
			Comp.OnTeleportFinished.Clear();
		}
	}
}

UCLASS(hidecategories="ComponentReplication Activation Variable Cooking Collision")
class UTimeControlSequenceComponent : UActorComponent
{
	UPROPERTY()
    TSubclassOf<ASequenceCloneActor> CloneClass;

	UPROPERTY()
	UMaterialParameterCollection WorldShaderParameters;

	UPROPERTY()
    UNiagaraSystem TeleportStartEffect;

	UPROPERTY()
    UNiagaraSystem TeleportEndEffect;

	UPROPERTY()
	UForceFeedbackEffect LeaveCloneForceFeedback;

	UPROPERTY()
	UForceFeedbackEffect TeleportForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> LeaveCloneCameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> TeleportCameraShake;

	UPROPERTY()
	bool bValidateTeleport = true;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    AHazePlayerCharacter Player = nullptr;

	AStaticCamera CloneCamera;
	AStaticCamera CloneCamera_Start;

    private ASequenceCloneActor CurrentClone = nullptr;

    FSequenceEvent OnPlacedClone;
    FSequenceEvent OnStartedTeleport;
	FSequenceEvent OnPostStartedTeleport;
	FSequenceEvent OnExecuteTeleport;
    FSequenceEvent OnTeleportFinished;

	bool bIsCurrentlyTeleporting = false;
	bool bStartedChargingClone = false;

	const FVector AirborneCloneImpulse(0.f, 0.f, 1500.f);
	bool bCloneWasAirborne = false;

    void CallCloneOnEvent(ESequenceEventType DelegateType)
    {   
        if(DelegateType == ESequenceEventType::OnPlacedClone)
        {
			Player.SetCapabilityActionState(n"AudioCloneCreated", EHazeActionState::ActiveForOneFrame);
            OnPlacedClone.Broadcast(Player);
        }
        else if(DelegateType == ESequenceEventType::OnStartedTeleport)
        {
			Player.SetCapabilityActionState(n"AudioActivatedTeleport", EHazeActionState::ActiveForOneFrame);
            OnStartedTeleport.Broadcast(Player);
        }
		else if(DelegateType == ESequenceEventType::OnPostStartedTeleport)
        {
            OnPostStartedTeleport.Broadcast(Player);
        }
		else if(DelegateType == ESequenceEventType::OnTeleportExecuted)
        {
			Player.SetCapabilityActionState(n"AudioCompletedTeleport", EHazeActionState::ActiveForOneFrame);
            OnExecuteTeleport.Broadcast(Player);
        }
        else if(DelegateType == ESequenceEventType::OnTeleportFinished)
        {
            OnTeleportFinished.Broadcast(Player);
        }
    }



    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        Player = Cast<AHazePlayerCharacter>(GetOwner());
		
		CurrentClone = Cast<ASequenceCloneActor>(SpawnPersistentActor(CloneClass, Player.ActorLocation, Player.ActorRotation));
		CloneCamera_Start = Cast<AStaticCamera>(SpawnPersistentActor(AStaticCamera::StaticClass()));
		CloneCamera = Cast<AStaticCamera>(SpawnPersistentActor(AStaticCamera::StaticClass()));
		DeactiveClone(Player);
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		// Clean up the clone
		if(CurrentClone != nullptr)
		{
			CurrentClone.DestroyActor();
			CurrentClone = nullptr;
		}

		if(CloneCamera != nullptr)
		{			
			CloneCamera.DestroyActor();
			CloneCamera = nullptr;
		}

		if(CloneCamera_Start != nullptr)
		{			
			CloneCamera_Start.DestroyActor();
			CloneCamera_Start = nullptr;
		}
	}

	bool IsCloneActive()const
	{
		if(CurrentClone != nullptr)
			return CurrentClone.IsActorDisabled() == false;
		
		return false;
	}

	UFUNCTION(BlueprintPure)
	ASequenceCloneActor GetClone() const property
	{
		return CurrentClone;
	}

	UFUNCTION(BlueprintEvent)
	void BP_StartCloneActiveEffects()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_EndCloneActiveEffects()
	{
	}

	void ActiveClone(FVector Location, FRotator Rotation, AHazePlayerCharacter Instigator)
	{
		if(CurrentClone != nullptr)
		{
			if(CurrentClone.IsActorDisabled(Instigator))
			{
				CurrentClone.EnableActor(Instigator);
				BP_StartCloneActiveEffects();
			}
				
			CurrentClone.SetActorLocationAndRotation(Location, Rotation);
			CurrentClone.SetActorHiddenInGame(false);
			CurrentClone.InitializeSequenceClone(Instigator.Mesh);
		}

		// Store the exact position of the camera to blend to later
		CloneCamera.ActorTransform = Instigator.CurrentlyUsedCamera.WorldTransform;
	}

	void DeactiveClone(AHazePlayerCharacter Instigator)
	{
		if(CurrentClone.IsActorDisabled(Instigator))
			return;
			
		if(CurrentClone != nullptr)
		{
			CurrentClone.DisableActor(Instigator);
			CurrentClone.SetActorHiddenInGame(true);
		}

		Player.SetCapabilityActionState(n"AudioCloneDestroyed", EHazeActionState::ActiveForOneFrame);
		BP_EndCloneActiveEffects();
	}

	FTransform GetCloneTransform() const property
	{
		if(CurrentClone != nullptr)
			return CurrentClone.GetActorTransform();
		return Player.GetActorTransform();
	}
}

UFUNCTION()
void DeactivateMayClone()
{
	UTimeControlSequenceComponent SeqComp = UTimeControlSequenceComponent::Get(Game::GetMay());
	if (SeqComp == nullptr)
		return;

	SeqComp.DeactiveClone(Game::GetMay());
}

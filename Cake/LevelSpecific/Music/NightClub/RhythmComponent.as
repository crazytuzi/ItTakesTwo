import Cake.LevelSpecific.Music.NightClub.RhythmTempoActor;
import Vino.PlayerHealth.PlayerHealthComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Rice.GUI.InputButtonWidget;

import void TempoHit(AHazeActor, ARhythmTempoActor) from "Cake.LevelSpecific.Music.Nightclub.RhythmActor";
import AHazePlayerCharacter GetCurrentDancer(AActor) from "Cake.LevelSpecific.Music.Nightclub.RhythmActor";
import AHazePlayerCharacter GetLastDancer(AActor) from "Cake.LevelSpecific.Music.Nightclub.RhythmActor";

#if TEST
const FConsoleVariable CVar_DanceAlwaysSuccess("Music.DJ.DanceAlwaysSuccess", 0);
#endif // TEST

event void FOnTempoHit(ARhythmTempoActor TempoActor);
event void FOnTempoFail(ARhythmTempoActor TempoActor);
event void FOnTempoStart(ARhythmTempoActor TempoActor);
event void FOnTempoSpawned(ARhythmTempoActor TempoActor);

class URhythmComponent : USceneComponent
{
	UPROPERTY(meta = (MakeEditWidget))
	FTransform StartTransform = FTransform(FVector(0.0f, 0.0f, 1500.0f));

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<ARhythmTempoActor> TempoClass;

	UPROPERTY()
	TSubclassOf<UInputButtonWidget> InputButtonClass;
	default InputButtonClass = Asset("/Game/GUI/InputIcon/WBP_InputButton.WBP_InputButton_C");
	private UInputButtonWidget InputButtonInstance = nullptr;

	UPROPERTY()
	FName ActionName;

	UPROPERTY()
	FOnTempoHit OnTempoHit;

	UPROPERTY()
	FOnTempoFail OnTempoFail;

	UPROPERTY()
	FOnTempoStart OnTempoStart;

	UPROPERTY()
	FOnTempoSpawned OnTempoSpawned;

	// Tempos in play, from oldest to newest
	TArray<ARhythmTempoActor> ActiveTempoActors;

	int Failures = 0;
	private int Internal_SpawnCounter = 0;

	AHazeActor RhythmActor;

	int MaxSpawnCounter = 10;
	int SpawnedCurrent = 0;

	int TempoCount = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RhythmActor = Cast<AHazeActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(!RhythmActor.HasControl())
		{
			for(int Index = ActiveTempoActors.Num() - 1; Index >= 0; --Index)
			{
				ARhythmTempoActor CurrentTempoActor = ActiveTempoActors[Index];
				if(CurrentTempoActor == nullptr)
					continue;

				if(CurrentTempoActor.bReadyToDie && CurrentTempoActor.bControlSaysOkayToDie)
				{
					OnTempoFail.Broadcast(CurrentTempoActor);
					ActiveTempoActors.RemoveAt(Index);
					CurrentTempoActor.StopTempo();
					Failures++;
				}
			}
		}
		else
		{
			for(int Index = ActiveTempoActors.Num() - 1; Index >= 0; --Index)
			{
				ARhythmTempoActor CurrentTempoActor = ActiveTempoActors[Index];

				if(CurrentTempoActor == nullptr)
					continue;

				if(CurrentTempoActor.bReadyToDie && !CurrentTempoActor.bStopped)
				{
#if !TEST
					HandleTempoFail(CurrentTempoActor);
#else

					EGodMode CurGodMode = GetGodMode(Game::GetMay());	// Does not matter which player we get here

					if(CurGodMode != EGodMode::Mortal)
					{
						Net_Debug_Success(CurrentTempoActor);
					}
					else
					{
						HandleTempoFail(CurrentTempoActor);
					}
#endif // !TEST
					ActiveTempoActors.RemoveAt(Index);
				}
			}
		}
	}

	void HandleTempoFail(ARhythmTempoActor TempoActor)
	{
		OnTempoFail.Broadcast(TempoActor);
		TempoActor.StopTempo();
		Failures++;
		NetHandleFail(TempoActor);
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetHandleFail(ARhythmTempoActor TempoActor)
	{
		if(TempoActor == nullptr)
			return;
		TempoActor.Handshake();
	}

	UFUNCTION(NetFunction)
	void Net_Debug_Success(ARhythmTempoActor TempoActor)
	{
		TempoHit(RhythmActor, TempoActor);
		TempoActor.StopTempo();
	}

	bool IsSameTempoClass(TSubclassOf<ARhythmTempoActor> TempoClassToTest) const
	{
		return true;
	}

	int GetNumTemposTotal() const
	{
		return ActiveTempoActors.Num();
	}

	// Called from Control in DanceMoveCapability so w can send a successful hit to the remote
	ARhythmTempoActor TestTempo()
	{
		if(!RhythmActor.HasControl())
		{
			return nullptr;
		}

		for(int Index = ActiveTempoActors.Num() - 1; Index >= 0; --Index)
		{
			ARhythmTempoActor CurrentTempoActor = ActiveTempoActors[Index];
			if(CurrentTempoActor == nullptr)
				continue;

			if(CurrentTempoActor.TestTempo())
			{
				return CurrentTempoActor;
			}
		}

		return nullptr;
	}

	void CleanupRhythmTempoActors()
	{
		for(ARhythmTempoActor CurrentTempoActor : ActiveTempoActors)
		{
			if(CurrentTempoActor == nullptr)
				continue;

			CurrentTempoActor.SetActorHiddenInGame(true);
			CurrentTempoActor.ClearWidget();
			CurrentTempoActor.SetLifeSpan(3.0f);
		}

		ActiveTempoActors.Empty();
	}

	// Called from RhythmActor to notify when a new dancer has started dancing.
	void OnNewDancer(AHazePlayerCharacter NewDancer, FVector InputButtonLocation)
	{
		for(ARhythmTempoActor CurrentTempoActor : ActiveTempoActors)
		{
			if(CurrentTempoActor == nullptr)
				continue;

			if(!CurrentTempoActor.bReadyToDie)
			{
				CurrentTempoActor.OnNewDancer(NewDancer);
			}

			CurrentTempoActor.SetControlSide(NewDancer);
		}
	}

	UFUNCTION(BlueprintCallable, Category = Rhythm)
	void PushTempo(float Tempo)
	{
		ARhythmTempoActor NewTempoActor = GetNewTempoActor(Tempo);
		AHazePlayerCharacter PlayerDancer = GetLastDancer(Owner);
		if(PlayerDancer == nullptr)
			PlayerDancer = Game::FirstLocalPlayer;

		NewTempoActor.ActionName = ActionName;
		NewTempoActor.RefreshWidget(PlayerDancer);

		OnTempoStart.Broadcast(NewTempoActor);
	}

	void OnDancerLeft(AHazePlayerCharacter InPlayer)
	{
		
	}

	private ARhythmTempoActor GetNewTempoActor(float Tempo)
	{
		ARhythmTempoActor NewTempoActor = Cast<ARhythmTempoActor>(SpawnActor(TempoClass, WorldLocation + StartTransform.Location, WorldRotation + StartTransform.Rotation.Rotator(), bDeferredSpawn = true));
		NewTempoActor.RhythmComp = this;
		NewTempoActor.RhythmActor = RhythmActor;
		NewTempoActor.MakeNetworked(this, Internal_SpawnCounter);
		Internal_SpawnCounter++;
		NewTempoActor.SetControlSide(RhythmActor);
		FinishSpawningActor(NewTempoActor);
		OnTempoSpawned.Broadcast(NewTempoActor);

		NewTempoActor.SetupTempo(WorldLocation, WorldLocation + StartTransform.Location, WorldRotation + StartTransform.Rotation.Rotator(), Tempo);
		ActiveTempoActors.Add(NewTempoActor);

		return NewTempoActor;
	}

	bool HasActiveTempos() const
	{
		return ActiveTempoActors.Num() > 0;
	}
}

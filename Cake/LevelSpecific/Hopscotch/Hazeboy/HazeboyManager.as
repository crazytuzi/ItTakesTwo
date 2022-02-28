import Cake.LevelSpecific.Hopscotch.Hazeboy.Hazeboy;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyRing;
import Vino.Interactions.DoubleInteractComponent;
import Vino.MinigameScore.MinigameComp;
import Peanuts.Triggers.PlayerTrigger;
import Vino.Interactions.DoubleInteractComponent;

event void FHazeboyOnReset();

import void StartUsingHazeboy(AHazePlayerCharacter Player, AHazeboy Device) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyPlayerComponent';
import void StopUsingHazeboy(AHazePlayerCharacter Player) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyPlayerComponent';

enum EHazeboyGameState
{
	Title,
	Tutorial,
	Countdown,
	Playing,
	PlayerDead,
	EndGame,
}

AHazeboyManager GetHazeboyManager()
{
	auto ManagerComp = UHazeboyManagerComponent::GetOrCreate(Game::May);
	if (ManagerComp.Manager == nullptr)
	{
		TArray<AHazeboyManager> Managers;
		GetAllActorsOfClass(Managers);

		if (Managers.Num() == 0)
			return nullptr;

		ManagerComp.Manager = Managers[0];
	}

	return ManagerComp.Manager;
}

void HazeboyRegisterVisibleActor(AActor Actor, int ExclusivePlayer = -1)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return;

	Manager.RegisterVisibleActor(Actor, ExclusivePlayer);
}

void HazeboyUnregisterVisibleActor(AActor Actor)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return;

	Manager.UnregisterVisibleActor(Actor);
}

void HazeboyRegisterRing(AHazeboyRing Ring)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return;

	Manager.Ring = Ring;
}

void HazeboyRegisterGameEndCallback(UObject Object, FName Function)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return;

	Manager.OnHazeboyGameEnd.AddUFunction(Object, Function);
}

void HazeboyRegisterResetCallback(UObject Object, FName Function)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return;

	Manager.OnHazeboyReset.AddUFunction(Object, Function);
}

void HazeboyTankDie(AHazeboyTank DeadTank)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return;

	if (Manager.HasControl())
		Manager.NetEndGame(DeadTank);
}

bool HazeboyIsTitleScreen()
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return false;

	return Manager.State == EHazeboyGameState::Title || Manager.State == EHazeboyGameState::Tutorial;
}

bool HazeboyGameIsActive()
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return false;

	return Manager.State == EHazeboyGameState::Playing;
}

bool HazeboyGameHasEnded()
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return false;

	return Manager.State == EHazeboyGameState::EndGame;
}

bool HazeboyIsPointWithinRing(FVector Point)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return false;

	if (Manager.Ring == nullptr)
		return true;

	FVector Diff = (Point - Manager.Ring.ActorLocation);
	Diff.Z = 0.f;

	float DistSqrd = Diff.SizeSquared();
	return DistSqrd < FMath::Square(Manager.Ring.CurrentRadius);
}

UFUNCTION(BlueprintPure, Category = "Minigames|Hazeboy")
float HazeboyGetDistanceToPlayerTank(FVector From, AHazePlayerCharacter Player)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr) return 0.f;

	if (Manager == nullptr)
		return 0.f;

	for(auto Hazeboy : Manager.Hazeboys)
	{
		if (Hazeboy.InteractedPlayer == Player)
			return From.Distance(Hazeboy.TargetTank.ActorLocation);
	}

	return 0.f;
}

UFUNCTION(Category = "Minigames|Hazeboy")
void HazeboyPlayPendingBark(AHazePlayerCharacter WaitingPlayer)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr)
		return;

	AHazeboy OtherHazeboy;
	for(auto Hazeboy : Manager.Hazeboys)
	{
		if (Hazeboy.TargetTank.PlayerIndex != int(WaitingPlayer.Player))
		{
			OtherHazeboy = Hazeboy;
			break;
		}
	}

	Manager.MinigameComp.PlayPendingStartVOBark(WaitingPlayer, OtherHazeboy.ActorLocation);
}

UFUNCTION(Category = "Minigames|Hazeboy")
void HazeboyPlayDamageBark(AHazePlayerCharacter DamagedPlayer)
{
	auto Manager = GetHazeboyManager();
	if (Manager == nullptr)
		return;

	if (DamagedPlayer == Manager.LastBarkedPlayer)
	{
		Manager.MinigameComp.PlayTauntAllVOBark(DamagedPlayer.OtherPlayer);
		Manager.LastBarkedPlayer = DamagedPlayer.OtherPlayer;
	}
	else
	{
		Manager.MinigameComp.PlayFailGenericVOBark(DamagedPlayer);
		Manager.LastBarkedPlayer = DamagedPlayer;
	}
}

struct FHazeboyActorVisibility
{
	AActor Actor;
	int ExclusivePlayer;
}

class UHazeboyManagerComponent : UActorComponent
{
	AHazeboyManager Manager;
}

class AHazeboyManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UMinigameComp MinigameComp;
	default MinigameComp.bPlayWinningAnimations = false;
	default MinigameComp.bPlayLosingAnimations = false;
	default MinigameComp.bPlayDrawAnimations = false;
	default MinigameComp.MinigameTag = EMinigameTag::TankBrothers;

	UPROPERTY(DefaultComponent)
	UDoubleInteractComponent DoubleInteract;

	UPROPERTY(EditInstanceOnly, Category = "Hazeboy")
	APlayerTrigger ActiveTrigger;

	UPROPERTY(EditInstanceOnly, Category = "Hazeboy")
	TPerPlayer<AHazeboy> Hazeboys;

	UPROPERTY(EditConst, Category = "Hazeboy")
	TPerPlayer<AHazeboyTank> Tanks;

	TArray<FHazeboyActorVisibility> VisibleActors;
	AHazeboyRing Ring;

	EHazeboyGameState State = EHazeboyGameState::Title;

	FHazeboyOnReset OnHazeboyGameEnd;
	FHazeboyOnReset OnHazeboyReset;
	int ActiveCounter = 0;

	AHazeboyTank LoserTank;
	float GameEndTimer = 2.f;

	AHazePlayerCharacter LastBarkedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteract.OnTriggered.AddUFunction(this, n"HandleDoubleInteractTriggered");
		
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"HandleCountdownFinished");
		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"HandleVictoryScreenFinished");
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"OnTutorialAccepted");
        MinigameComp.OnTutorialCancel.AddUFunction(this, n"OnTutorialCanceled");

		ActiveTrigger.OnPlayerEnter.AddUFunction(this, n"HandlePlayerEnterActive");
		ActiveTrigger.OnPlayerLeave.AddUFunction(this, n"HandlePlayerLeaveActive");

		for(int i = 0; i < 2; ++i)
			Tanks[i] = Hazeboys[i].TargetTank;

		// Add all visible actors to the tanks ShowOnly array
		for(auto Tank : Tanks)
		{
			for(auto Entry : VisibleActors)
			{
				if (Entry.ExclusivePlayer == -1 || Tank.PlayerIndex == Entry.ExclusivePlayer)
					Tank.Camera.ShowOnlyActors.Add(Entry.Actor);
			}
		}
	}

	UFUNCTION()
	void HandlePlayerEnterActive(AHazePlayerCharacter Player)
	{
		ActiveCounter++;
		if (ActiveCounter == 1)
		{
			if (HasControl())
				NetEnableEverything();
		}
	}

	UFUNCTION()
	void HandlePlayerLeaveActive(AHazePlayerCharacter Player)
	{
		ActiveCounter--;
		if (ActiveCounter == 0)
		{
			if (HasControl())
				NetDisableEverything();

			State = EHazeboyGameState::Title;
		}
	}

	UFUNCTION(NetFunction)
	void NetEnableEverything()
	{
		// Enable everything!
		for(auto VisibleActor : VisibleActors)
		{
			auto HazeActor = Cast<AHazeActor>(VisibleActor.Actor);
			if (HazeActor == nullptr)
				continue;

			HazeActor.EnableActor(this);
		}
	}

	UFUNCTION(NetFunction)
	void NetDisableEverything()
	{
		// Disable everything!
		for(auto VisibleActor : VisibleActors)
		{
			auto HazeActor = Cast<AHazeActor>(VisibleActor.Actor);
			if (HazeActor == nullptr)
				continue;

			HazeActor.DisableActor(this);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleDoubleInteractTriggered()
	{
		SetNewState(EHazeboyGameState::Tutorial);
		MinigameComp.ActivateTutorial();	
	}

	UFUNCTION(NotBlueprintCallable)
    void OnTutorialAccepted()
    {
		OnHazeboyReset.Broadcast();
		MinigameComp.StartCountDown();
		SetNewState(EHazeboyGameState::Countdown);

		SetActorTickEnabled(true);
    }
    
    UFUNCTION(NotBlueprintCallable)
    void OnTutorialCanceled()
    {
   		auto Players = Game::GetPlayers();
		for(auto Player : Players)
		{
			auto HazeBoy = Hazeboys[Player.Player];
			Player.StopUsingHazeboy();
		}

		SetNewState(EHazeboyGameState::Title);
    }

	UFUNCTION(NotBlueprintCallable)
	void HandleCountdownFinished()
	{
		SetNewState(EHazeboyGameState::Playing);
	}

	UFUNCTION()
	void HandleVictoryScreenFinished()
	{
		SetNewState(EHazeboyGameState::Title);
	}

	void SetNewState(EHazeboyGameState NewState)
	{
		if (State == NewState)
			return;

		State = NewState;
		switch(State)
		{
			case EHazeboyGameState::Title:
				Hazeboys[0].InteractionComp.Enable(n"GameRunning");
				Hazeboys[1].InteractionComp.Enable(n"GameRunning");
				break;

			case EHazeboyGameState::Playing:
				Hazeboys[0].InteractionComp.Disable(n"GameRunning");
				Hazeboys[1].InteractionComp.Disable(n"GameRunning");
				break;
		}
	}

	UFUNCTION(NetFunction)
	void NetEndGame(AHazeboyTank InLoserTank)
	{
		if (State != EHazeboyGameState::Playing)
			return;

		LoserTank = InLoserTank;
		SetNewState(EHazeboyGameState::PlayerDead);
		GameEndTimer = 2.f;

		OnHazeboyGameEnd.Broadcast();
	}

	void RegisterVisibleActor(AActor Actor, int ExclusivePlayer)
	{
		FHazeboyActorVisibility Entry;
		Entry.Actor = Actor;
		Entry.ExclusivePlayer = ExclusivePlayer;

		VisibleActors.Add(Entry);

		// If we're not active, disable this immediately
		if (ActiveCounter <= 0)
		{
			auto HazeActor = Cast<AHazeActor>(Actor);
			if (HazeActor != nullptr)
				HazeActor.DisableActor(this);
		}

		for(auto Tank : Tanks)
		{
			if (ExclusivePlayer == -1 || Tank.PlayerIndex == ExclusivePlayer)
				Tank.Camera.ShowOnlyActors.Add(Actor);
		}

	}

	UFUNCTION()
	void PlayReactionAnimation(AHazePlayerCharacter Player)
	{
		MinigameComp.ActivateReactionAnimations(Player);
	}

	void UnregisterVisibleActor(AActor Actor)
	{
		for(int i=0; i<VisibleActors.Num(); ++i)
		{
			if (VisibleActors[i].Actor == Actor)
			{
				VisibleActors.RemoveAt(i);
				return;
			}
		}

		for(auto Tank : Tanks)
			Tank.Camera.ShowOnlyActors.Remove(Actor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		switch(State)
		{
			case EHazeboyGameState::Title:
				break;

			case EHazeboyGameState::Playing:
				break;

			case EHazeboyGameState::PlayerDead:
				GameEndTimer -= DeltaTime;
				if (GameEndTimer <= 0.f)
				{
					auto Winner = LoserTank.OwningPlayer.OtherPlayer;
					float CurrentScore = Winner.IsMay() ? MinigameComp.ScoreData.MayScore : MinigameComp.ScoreData.CodyScore;
					MinigameComp.SetScore(Winner, CurrentScore + 1);
					MinigameComp.AnnounceWinner(Winner);
					SetNewState(EHazeboyGameState::EndGame);
				}

				break;

			case EHazeboyGameState::EndGame:
				SetActorTickEnabled(false);
				break;
		}
	}
}
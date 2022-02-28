import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceCheckpoint;
import Cake.LevelSpecific.SnowGlobe.IceRace.IceRaceBoostPickup;
import Vino.Interactions.DoubleInteractionActor;
import Vino.MinigameScore.ScoreHud;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowfolkSplineFollower;
import Vino.MinigameScore.MinigameComp;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;
import Vino.Audio.AudioActors.SideCharacterAudioInteractionPlayerTrigger;
import Cake.LevelSpecific.SnowGlobe.VOBanks.SnowGlobeLakeVOBank;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;

class AIceRaceStart : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteractionActor;

	UPROPERTY()
	AActor POIActor;

	UPROPERTY()
	TArray<ASnowfolkSplineFollower> SnowfolkContesters;

	UPROPERTY()
	TSubclassOf<UIceRaceWidget> IceRaceWidgetClass;

	UIceRaceWidget IceRaceWidget;

	UPROPERTY()
	UHazeCapabilitySheet IceRaceCapabilitySheet;

	UPROPERTY()
	AIceRaceCheckpoint FinishLineCheckpoint;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UMinigameComp MinigameComp;
	default MinigameComp.StartingScore = 1.f;
	default MinigameComp.ScoreData.ScoreLimit = 3.f;
	default MinigameComp.MinigameTag = EMinigameTag::IceRace;

	UPROPERTY()
	float RaceTime = 0.f;

	UPROPERTY()
	int Laps = 3;

	UPROPERTY()
	float CheckpointTimeout = 10.f;

	UPROPERTY()
	bool bIgnoreCheckpointTimeout = false;

	UPROPERTY()
	UAnimSequence MayWaitAnimation;

	UPROPERTY()
	UAnimSequence CodyWaitAnimation;

	UPROPERTY()
	UAnimSequence MayStartAnimation;

	UPROPERTY()
	UAnimSequence CodyStartAnimation;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CheckPointPassByAudioEvent;

	UPROPERTY()
	ASideCharacterAudioInteractionPlayerTrigger SideCharacterVOVolume;

	UPROPERTY()
	USnowGlobeLakeVOBank VOBank;

	UPROPERTY()
	FName MayTauntEvent = NAME_None;

	UPROPERTY()
	FName CodyTauntEvent = NAME_None;

	FHazePointOfInterest POISettings;
	
	bool bIceRaceRunnning;

	TArray<AIceRaceCheckpoint> MayCheckpoints;
	TArray<AIceRaceCheckpoint> CodyCheckpoints;

	UIceRaceComponent MayIceRaceComponent;
	UIceRaceComponent CodyIceRaceComponent;

	TPerPlayer<float> TimeoutTimers;

	TArray<AIceRaceBoostPickup> Pickups;

	TArray<ASnowGlobeSwimmingVolume> SwimmingVolumes;

	TMap<ASnowfolkSplineFollower, UDopplerEffect> ContestantDopplers;

	bool bPlayVOMay;
	int PlayVOIndex;
	int PlayVOMin = 2;
	int PlayVOMax = 3;
	int PlayVOCount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Capability::AddPlayerCapabilitySheetRequest(IceRaceCapabilitySheet);

		POISettings.FocusTarget.WorldOffset = POIActor.ActorLocation;
		POISettings.Blend = 1.f;
		POISettings.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
		
		MayIceRaceComponent = UIceRaceComponent::Get(Game::May);
		CodyIceRaceComponent = UIceRaceComponent::Get(Game::Cody);

		if (DoubleInteractionActor != nullptr)
			DoubleInteractionActor.OnDoubleInteractionCompleted.AddUFunction(this, n"OnDoubleInteractionCompleted");

		SetupCheckpoints();
		SetupPickups();

		for (auto SnowfolkContester : SnowfolkContesters)
		{
			SnowfolkContester.ResetSnowfolk();
			SnowfolkContester.bCanMove = false;
			UDopplerEffect ContesterDoppler = Cast<UDopplerEffect>(SnowfolkContester.SnowfolkHazeAkComp.AddEffect(UDopplerEffect::StaticClass(), bStartEnabled = false));

			ContesterDoppler.SetObjectDopplerValues(true, MaxSpeed = 500.f, Scale = 10.f, Driver = EHazeDopplerDriverType::Both);
			ContestantDopplers.Add(SnowfolkContester, ContesterDoppler);
		}

		if(SnowfolkContesters.Num() == 0 and SideCharacterVOVolume != nullptr)
			SideCharacterVOVolume.BrushComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(IceRaceCapabilitySheet);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bIceRaceRunnning)
			return;

		RaceTime += DeltaTime;
		MinigameComp.SetTimer(RaceTime);
		MinigameComp.UpdateCurrentLapTimes(DeltaTime);

		if (!HasControl() || bIgnoreCheckpointTimeout)
			return;

		// Both players timed out, draw
		if (TimeoutTimers[0] <= 0.f && TimeoutTimers[1] <= 0.f)
		{
			NetFinishIceRace(nullptr);
			return;
		}
		
		for (auto Player : Game::Players)
		{
			if (TimeoutTimers[Player.Player] <= 0.f)
			{
				NetFinishIceRace(Player.OtherPlayer);
				return;
			}

			TimeoutTimers[Player.Player] -= DeltaTime;
		}
	}

	UFUNCTION()
	void BindMinigameEvents()
	{
		MinigameComp.OnCountDownCompletedEvent.AddUFunction(this, n"StartIceRace");
		MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"EndIceRace");
		MinigameComp.OnMinigameTutorialComplete.AddUFunction(this, n"OnTutorialComplete");
		MinigameComp.OnTutorialCancel.AddUFunction(this, n"OnTutorialCancelled");
	}

	UFUNCTION()
	void SetupCheckpoints()
	{
		AIceRaceCheckpoint NextCheckpoint = FinishLineCheckpoint;

		while (NextCheckpoint != nullptr)
		{
			MayCheckpoints.Add(NextCheckpoint);
			NextCheckpoint = NextCheckpoint.NextCheckpoint;
			if (NextCheckpoint == FinishLineCheckpoint)
				NextCheckpoint = nullptr;
		}

	//	PrintScaled("Number of Checkpoints: " + MayCheckpoints.Num(), 2.f, FLinearColor::Green, 2.f);

		for (auto MayCheckpoint : MayCheckpoints)
		{
			AIceRaceCheckpoint CodyCheckpoint = CreateCheckpointClone(MayCheckpoint);
			CodyCheckpoints.Add(CodyCheckpoint);

			MayCheckpoint.OnIceRaceCheckpointTriggered.AddUFunction(this, n"OnIceRaceCheckpointTriggered");
			CodyCheckpoint.OnIceRaceCheckpointTriggered.AddUFunction(this, n"OnIceRaceCheckpointTriggered");
		}
	}

	UFUNCTION()
	void SetupPickups()
	{
		GetAllActorsOfClass(Pickups);

	//	PrintScaled("Number of Pickups: " + Pickups.Num(), 2.f, FLinearColor::Green, 2.f);
	}

	UFUNCTION()
	void SetupSwimmingVolumes()
	{
		GetAllActorsOfClass(SwimmingVolumes);

	//	PrintScaled("Number of SwimmingVolumes: " + SwimmingVolumes.Num(), 2.f, FLinearColor::Green, 2.f);

		for (auto SwimmingVolume : SwimmingVolumes)
		{
			SwimmingVolume.OnSwimmingVolumeEntered.AddUFunction(this, n"OnSwimmingVolumeEntered");
		}
	}

	UFUNCTION()
	AIceRaceCheckpoint CreateCheckpointClone(AIceRaceCheckpoint Checkpoint)
	{
		auto CheckpointClone = Cast<AIceRaceCheckpoint>(SpawnActor(Checkpoint.Class, Checkpoint.ActorLocation, Checkpoint.ActorRotation, bDeferredSpawn = true, Level = Checkpoint.GetLevel()));
		CheckpointClone.SetOwner(Game::GetCody());

		FinishSpawningActor(CheckpointClone);

		// Set the scale
		CheckpointClone.SetActorScale3D(Checkpoint.ActorScale3D);

		return CheckpointClone;
	}

    UFUNCTION()
    void OnDoubleInteractionCompleted()
	{
		DoubleInteractionActor.DisableActor(this);

		ActivateRaceTrack();

		// Get the SwimmingVolumes here, since they are in other layers and could not be streamed in at begin play
		SetupSwimmingVolumes();

		// Show tutorial
		MinigameComp.ActivateTutorial();
		MinigameComp.ResetScoreBoth();
		BindMinigameEvents();

		// Freeze players
		for (auto Player : Game::GetPlayers())
		{
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			Player.PlaySlotAnimation(Animation = Player.IsMay() ? MayWaitAnimation : CodyWaitAnimation, bLoop = true);
		}

		if(SideCharacterVOVolume != nullptr)
			SideCharacterVOVolume.BrushComponent.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	void OnIceRaceCheckpointTriggered(AIceRaceCheckpoint Checkpoint, AHazePlayerCharacter Player)
	{
		if (!bIceRaceRunnning)
			return;

		if (Player.HasControl())
		{
			auto PlayerCheckpoints = Player.IsMay() ? MayCheckpoints : CodyCheckpoints;
			int CheckpointIndex = PlayerCheckpoints.FindIndex(Checkpoint);

			NetCheckpointReached(Player, CheckpointIndex);
		}

		Player.PlayerHazeAkComp.HazePostEvent(CheckPointPassByAudioEvent);
	}

	UFUNCTION()
	void ActivateRaceTrack()
	{
		MayCheckpoints[1].ActivateCheckpoint();
		CodyCheckpoints[1].ActivateCheckpoint();

		for (auto Pickup : Pickups)
		{
			Pickup.ActivatePickup();
			Pickup.Spawn();
		}
	}

	UFUNCTION()
	void DeactivateRaceTrack()
	{
		for (auto Pickup : Pickups)
		{
			Pickup.Despawn();
			Pickup.DeactivatePickup();
		}

		for (auto MayCheckpoint : MayCheckpoints)
		{
			MayCheckpoint.DeactivateCheckpoint();
		}

		for (auto CodyCheckpoint : CodyCheckpoints)
		{
			CodyCheckpoint.DeactivateCheckpoint();
		}
	}

	UFUNCTION()
	void StartIceRaceCountdown()
	{

	}

	// Network
	UFUNCTION()
	void StartIceRace()
	{
		// Unreeze players
		for (auto Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.StopAllSlotAnimations();
		}

		Game::May.ClearCurrentPointOfInterest();
		Game::Cody.ClearCurrentPointOfInterest();

		// PrintScaled("StartIceRace!", 2.f, FLinearColor::Green, 2.f);
		MinigameComp.BlockGameHudDeactivation();

		for (auto Player : Game::Players)
			TimeoutTimers[Player.Player] = CheckpointTimeout;

		bIceRaceRunnning = true;

		for (auto SnowfolkContester : SnowfolkContesters)
		{
			SnowfolkContester.bCanMove = true;
			UDopplerEffect ContestantDoppler;
			ContestantDopplers.Find(SnowfolkContester, ContestantDoppler);

			ContestantDoppler.SetEnabled(true);

			SnowfolkContester.PatrolAudioComp.BP_RegisterToManager();
		}

		EnableIceSkatingCheerForLevel();
	}

	UFUNCTION()
	void OnTutorialComplete()
	{
		// Start the count down
		MinigameComp.StartCountDown();

		Game::May.ApplyPointOfInterest(POISettings, this, EHazeCameraPriority::High);
		Game::Cody.ApplyPointOfInterest(POISettings, this, EHazeCameraPriority::High);

		for (auto Player : Game::GetPlayers())
		{
			Player.PlaySlotAnimation(Animation = Player.IsMay() ? MayStartAnimation : CodyStartAnimation);
		}

		for (auto SnowfolkContester : SnowfolkContesters)
		{
			SnowfolkContester.bIsReady = true;
		}
	}

	UFUNCTION()
	void OnTutorialCancelled()
	{
		DoubleInteractionActor.EnableActor(this);
		DeactivateRaceTrack();

		// Unreeze players
		for (auto Player : Game::GetPlayers())
		{
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			Player.StopAllSlotAnimations();
		}
	}

	UFUNCTION()
	void EndIceRace()
	{
		MinigameComp.UnblockGameHudDeactivation();

		DoubleInteractionActor.EnableActor(this);

		for (auto SnowfolkContester : SnowfolkContesters)
		{
			SnowfolkContester.ResetSnowfolk();
			SnowfolkContester.bCanMove = false;
			SnowfolkContester.bIsReady = false;

			UDopplerEffect ContestantDoppler;
			ContestantDopplers.Find(SnowfolkContester, ContestantDoppler);

			ContestantDoppler.SetEnabled(false);

			SnowfolkContester.PatrolAudioComp.BP_UnregisterToManager();
		}

		for (auto Player : Game::GetPlayers())
		{
			auto IceRaceComponent = UIceRaceComponent::Get(Player);
			IceRaceComponent.Laps = 0;
			IceRaceComponent.Checkpoints = 0;
		}

		if(SideCharacterVOVolume != nullptr && SnowfolkContesters.Num() > 0)
			SideCharacterVOVolume.BrushComponent.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		RaceTime = 0.f;
		DisableIceSkatingCheerForLevel();
	}
	
	UFUNCTION(NetFunction)
	void NetFinishIceRace(AHazePlayerCharacter WinningPlayer)
	{
		bIceRaceRunnning = false;

		DeactivateRaceTrack();

		if (WinningPlayer != nullptr)
			MinigameComp.AnnounceWinner(WinningPlayer);
		else
			MinigameComp.AnnounceWinner();
	}

	UFUNCTION(NetFunction)
	void NetCheckpointReached(AHazePlayerCharacter Player, int CheckpointIndex)
	{
		auto RaceComp = Player.IsMay() ? MayIceRaceComponent : CodyIceRaceComponent;
		auto PlayerCheckpoints = Player.IsMay() ? MayCheckpoints : CodyCheckpoints;

		if (RaceComp == nullptr || 
			PlayerCheckpoints.Num() == 0 || 
			PlayerCheckpoints.Num() < CheckpointIndex)
			return;

		RaceComp.Checkpoints += 1;

		if (CheckpointIndex == 0)
		{
			RaceComp.Laps += 1;

			MinigameComp.SetBestAndLastLapTimes(Player);

			if (RaceComp.Laps == Laps)
			{
				if (HasControl())
					NetFinishIceRace(Player);

				return;
			}

			MinigameComp.SetScore(Player, RaceComp.Laps + 1);
		}

		int NextCheckpointIndex = (CheckpointIndex + 1) % PlayerCheckpoints.Num();
		PlayerCheckpoints[CheckpointIndex].DeactivateCheckpoint();
		PlayerCheckpoints[NextCheckpointIndex].ActivateCheckpoint();

		TimeoutTimers[Player.Player] = CheckpointTimeout;

		VOTauntHandler(Player);
	}

	UFUNCTION()
	void OnSwimmingVolumeEntered(AHazePlayerCharacter Player)
	{
		if (!HasControl() || !bIceRaceRunnning)
			return;

		NetFinishIceRace(Player.OtherPlayer);
	}

	void VOTauntHandler(AHazePlayerCharacter Player)
	{
		PlayVOCount++; 

		if (PlayVOCount >= 6)
		{
			MinigameComp.PlayTauntAllVOBark(Player);
			PlayVOCount = 0;
		}
		else
		{
			if (Player.IsMay() && bPlayVOMay && PlayVOIndex == 0)
			{
				MinigameComp.PlayTauntAllVOBark(Player);
				bPlayVOMay = !bPlayVOMay;			
				PlayVOIndex = FMath::RandRange(PlayVOMin, PlayVOMax);
				PlayVOCount = 0;
			}
			else if (Player.IsCody() && !bPlayVOMay && PlayVOIndex == 0)
			{
				MinigameComp.PlayTauntAllVOBark(Player);
				bPlayVOMay = !bPlayVOMay;			
				PlayVOIndex = FMath::RandRange(PlayVOMin, PlayVOMax);
				PlayVOCount = 0;
			}
			
			if (Player.IsMay() && bPlayVOMay && PlayVOIndex > 0)
				PlayVOIndex--;
			else if (Player.IsCody() && !bPlayVOMay && PlayVOIndex > 0)
				PlayVOIndex--;		
		}
	}
}
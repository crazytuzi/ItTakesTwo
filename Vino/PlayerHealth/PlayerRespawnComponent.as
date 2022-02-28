import Vino.PlayerHealth.PlayerHealthSettings;
import Vino.PlayerHealth.PlayerGenericEffect;
import Vino.PlayerHealth.PlayerRespawnEffect;
import void ResetStickyCheckpointVolume(AHazePlayerCharacter Player) from "Vino.Checkpoints.Statics.CheckpointStatics";

import void UpdateCheckpointVolumes(AHazePlayerCharacter Player) from "Vino.Checkpoints.Volumes.CheckpointVolume";
import bool PrepareCheckpointRespawn(AHazePlayerCharacter Player, FPlayerRespawnEvent& OutEvent) from "Vino.Checkpoints.Checkpoint";
import bool PrepareRespawnInPlace(AHazePlayerCharacter Player, FPlayerRespawnEvent& OutEvent) from "Vino.PlayerHealth.RespawnInPlace";
import FString Debug_ShowCheckpoints(AHazePlayerCharacter Player) from "Vino.Checkpoints.Checkpoint";

delegate void FOnPlayersGameOver();

delegate bool FOnPrepareRespawn(AHazePlayerCharacter Player, FPlayerRespawnEvent& OutEvent); 

delegate void FOnPlayerDissolveStarted(AHazePlayerCharacter Player);

event void FOnPlayerRespawned(AHazePlayerCharacter Player);
event void FOnGameOverCompleted();

event void FOnPlayerDissolveCompleted(AHazePlayerCharacter Player);

const FConsoleVariable CVar_DebugCheckpoints("Haze.DebugCheckpoints", 0, "Debug enabled checkpoints. 1=Both, 2=May, 3=Cody");

struct FPlayerRespawnOverride
{
	FOnPrepareRespawn Prepare;
	UObject Instigator;
};

class UDummyPlayerRespawnEffect : UPlayerRespawnEffect
{
	void Activate() override
	{
		Super::Activate();
		TriggerRespawn();
		FinishEffect();
	}
};

class UPlayerRespawnComponent : UActorComponent
{
	UPROPERTY()
	TSubclassOf<UPlayerRespawnEffect> DefaultRespawnEffect = UDummyPlayerRespawnEffect::StaticClass();

	UPROPERTY()
	TSubclassOf<UPlayerRespawnEffect> RespawnInPlaceEffect = UDummyPlayerRespawnEffect::StaticClass();

	UPROPERTY()
	TSubclassOf<UPlayerGameOverEffect> DefaultGameOverEffect = UDummyPlayerGameOverEffect::StaticClass();

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> WaitRespawnWidget;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> TensionModeWidget;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettingsWhileDead;

	bool bIsUnDissolving = false;

	UPROPERTY()
	float DissolveDuration = 2.f;
	UPROPERTY()
	FRuntimeFloatCurve DissolveCurve;
	FHazeTimeLike DissolveTimeLike;
	default DissolveTimeLike.Duration = 1.f;

	UPROPERTY()
	UNiagaraSystem RespawnSystem;
	UNiagaraSystem DefaultRespawnSystem;

    FOnPlayerRespawned OnRespawn;
	FOnPlayersGameOver OnGameOver;
	FOnGameOverCompleted OnGameOverCompleted;
	FOnPlayerDissolveStarted OnPlayerDissolveStarted;
	FOnPlayerDissolveCompleted OnPlayerDissolveCompleted;

	bool bIsGameOver = false;
	bool bManualGameOverTrigger = false;

	bool bAudioGamerOverIsDirty = false;
	bool bIsAudioGameOver = false;
	bool bWaitingForRespawn = false;
	bool bIsRespawning = false;
	bool bRespawnBlocked = false;
	bool bCheckpointVolumesBlocked = false;
	bool bPlayerHiddenFromDeath = false;

	float GameTimeStartedRespawning = -1.f;

	float CurrentRespawnProgress = 0.f;
	float RespawnMashRate = 0.f;
	bool bRespawnMashPulse = false;

	UObject StickyCheckpointVolume;
	UObject StickyCheckpoint; 

	AHazePlayerCharacter Player;

	UPlayerHealthSettings HealthSettings;

	private TArray<FPlayerRespawnOverride> Overrides;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HealthSettings = UPlayerHealthSettings::GetSettings(Player);

		DissolveTimeLike.Curve = DissolveCurve;
		DissolveTimeLike.SetPlayRate(1/DissolveDuration);
		DissolveTimeLike.BindUpdate(this, n"UpdateDissolveEffect");
		DissolveTimeLike.BindFinished(this, n"FinishDissolveEffect");

		DefaultRespawnSystem = RespawnSystem;
	}

#if !RELEASE
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (CVar_DebugCheckpoints.GetInt() != 0)
		{
			if (
				CVar_DebugCheckpoints.GetInt() == 1
				|| Player.IsMay() && CVar_DebugCheckpoints.GetInt() == 2
				|| Player.IsCody() && CVar_DebugCheckpoints.GetInt() == 3)
			{
				FString DebugText;
				DebugText += "Checkpoints Enabled For "+Player.Name;
				if (StickyCheckpointVolume != nullptr)
					DebugText += "\n   Sticky Volume: "+StickyCheckpointVolume.Name;
				if (StickyCheckpoint != nullptr)
					DebugText += "\n   Sticky Checkpoint: "+StickyCheckpoint.Name;
				DebugText += "\n";
				DebugText += Debug_ShowCheckpoints(Player);

				PrintToScreen(DebugText,
					Color = Player.IsMay() ? FLinearColor::LucBlue : FLinearColor::Green);
			}
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		Overrides.Empty();
		OnRespawn.Clear();
		OnGameOver.Clear();
		bIsGameOver = false;
		bManualGameOverTrigger = false;
		bWaitingForRespawn = false;
		bIsRespawning = false;
		bIsAudioGameOver = false;
		GameTimeStartedRespawning = -1.f;
		ResetStickyCheckpointVolume(Player);
		ShowPlayerFromRespawn();
		StopDissolveEffect();
		RespawnSystem = DefaultRespawnSystem;
	}

	TSubclassOf<UPlayerRespawnEffect> GetDefaultEffect_Respawn()
	{
		if (HealthSettings.DefaultRespawnEffect.IsValid())
			return HealthSettings.DefaultRespawnEffect;
		return DefaultRespawnEffect;
	}

	TSubclassOf<UPlayerGameOverEffect> GetDefaultEffect_GameOver()
	{
		if (HealthSettings.DefaultGameOverEffect.IsValid())
			return HealthSettings.DefaultGameOverEffect;
		return DefaultGameOverEffect;
	}

	bool CanRespawn()
	{
		if (bIsGameOver)
			return false;
		if (bRespawnBlocked)
			return false;
		return true;
	}

	void PrepareRespawn(FPlayerRespawnEvent& OutEvent)
	{
		// First see if any overrides want to take over this respawn
		for (auto& Override : Overrides)
		{
			if (Override.Prepare.ExecuteIfBound(Player, OutEvent))
				return;
		}

		// Check if we are allowed to respawn in place
		if (PrepareRespawnInPlace(Player, OutEvent))
			return;

		// Check if any checkpoints are available to respawn from
		if (PrepareCheckpointRespawn(Player, OutEvent))
			return;

		// If all else fails, respawn at the player's current location directly
		OutEvent.RelativeLocation = Player.ActorLocation;
		OutEvent.Rotation = Player.ActorRotation;
	}

	void PerformRespawn(FPlayerRespawnEvent Event)
	{
        OnRespawn.Broadcast(Player);
		Event.OnRespawn.ExecuteIfBound(Player);

        UpdateCheckpointVolumes(Player);
		ShowPlayerFromRespawn();
	}

	void ForceAlive()
	{
        UpdateCheckpointVolumes(Player);
		ShowPlayerFromRespawn();
		StopDissolveEffect();
	}

	void AddRespawnOverride(FOnPrepareRespawn PrepareRespawn, UObject Instigator)
	{
		FPlayerRespawnOverride Override;
		Override.Prepare = PrepareRespawn;
		Override.Instigator = Instigator;
		Overrides.Add(Override);
	}

	void RemoveRespawnOverride(UObject Instigator)
	{
		for (int i = 0, Count = Overrides.Num(); i < Count; ++i)
		{
			if (Overrides[i].Instigator == Instigator)
			{
				Overrides.RemoveAt(i);
				--i; --Count;
			}
		}
	}

	void HidePlayerFromDeath()
	{
		if (bPlayerHiddenFromDeath)
			return;
		bPlayerHiddenFromDeath = true;
		Player.BlockCapabilities(CapabilityTags::Visibility, this);
	}

	void ShowPlayerFromRespawn()
	{
		if (!bIsUnDissolving)
		{
			SetDissolve(0.f);
		}

		if (bPlayerHiddenFromDeath)
		{
			bPlayerHiddenFromDeath = false;
			Player.UnblockCapabilities(CapabilityTags::Visibility, this);
		}
	}

	UFUNCTION()
	void FlagGameOverAudio(bool bAudioGameOver)
	{
		bIsAudioGameOver = bAudioGameOver;

		if(bAudioGameOver)
			bAudioGamerOverIsDirty = true;
	}

	void TriggerDissolveEffect()
	{
		if (bIsUnDissolving)
			return;

		DissolveTimeLike.PlayFromStart();
		bIsUnDissolving = true;
	}

	void StopDissolveEffect()
	{
		SetDissolve(0.f);
		DissolveTimeLike.Stop();
		bIsUnDissolving = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void UpdateDissolveEffect(float CurValue)
	{
		float CurrentDissolveValue = FMath::Lerp(1.f, 0.f, CurValue);
		SetDissolve(CurrentDissolveValue);
	}

	void SetDissolve(float value)
	{
		// Recursively get all attached components
		TArray<USceneComponent> AttachedComponents = TArray<USceneComponent>();
		AttachedComponents.Add(Player.RootComponent);
		int CheckIndex = 0;
		while (CheckIndex < AttachedComponents.Num())
		{
			for (int i = 0; i < AttachedComponents[CheckIndex].GetNumChildrenComponents(); i++)
			{
				USceneComponent Child = AttachedComponents[CheckIndex].GetChildComponent(i);
				if (Child != nullptr)
					AttachedComponents.AddUnique(Child);
			}

			CheckIndex++;
		}

		for(USceneComponent Actor : AttachedComponents)
		{
			USkinnedMeshComponent SkinnedMeshComponent = Cast<USkinnedMeshComponent>(Actor);
			if(SkinnedMeshComponent != nullptr)
				SkinnedMeshComponent.SetScalarParameterValueOnMaterials(n"Dissolve", value);

			UStaticMeshComponent StaticMeshComponent = Cast<UStaticMeshComponent>(Actor);
			if(StaticMeshComponent != nullptr)
				StaticMeshComponent.SetScalarParameterValueOnMaterials(n"Dissolve", value);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void FinishDissolveEffect()
	{
		bIsUnDissolving = false;
		OnPlayerDissolveCompleted.Broadcast(Player);
	}
};

UFUNCTION()
void SetRespawnSystem(AHazePlayerCharacter Player, UNiagaraSystem System)
{
	UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
	if (RespawnComp != nullptr)
		RespawnComp.RespawnSystem = System;
}

UFUNCTION()
void ResetRespawnSystem(AHazePlayerCharacter Player)
{
	UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
	if (RespawnComp != nullptr)
		RespawnComp.RespawnSystem = RespawnComp.DefaultRespawnSystem;
}

UFUNCTION()
void ResetPlayerDissolveEffect(AHazePlayerCharacter Player)
{
	UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::Get(Player);
	if (RespawnComp != nullptr)
		RespawnComp.StopDissolveEffect();
}
import Cake.LevelSpecific.Music.NightClub.DJDanceCommon;

import bool IsSuperDanceMode(AHazeActor) from "Cake.LevelSpecific.Music.Nightclub.DJDanceRevolutionManager";
import int GetCurrentRoundIndex(AHazeActor) from "Cake.LevelSpecific.Music.Nightclub.DJDanceRevolutionManager";
import void SetDebugEnabled_DJStations(AActor, bool) from "Cake.LevelSpecific.Music.Nightclub.DJDanceRevolutionManager";

//GetCurrentRoundIndex

class ABassDropOMeter : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddDebugCapability(n"DropOMeterDebugCapability");
		PreventFailElapsed = PreventFailDuration;
	}

	UPROPERTY()
	float BassDropOMeterProgress;

	UPROPERTY(BlueprintReadWrite)
	float CurrentBassDropMaster = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = BassDropO)
	float TargetBassDropValue = 0.0f;

	UPROPERTY(Category = PreventFail)
	bool bPreventFailAfterDuration = false;
	UPROPERTY(Category = PreventFail, meta = (EditCondition = "bPreventFailAfterDuration", EditConditionHides))
	float PreventFailDuration = 180.0f;
	float PreventFailElapsed = 0.0f;

	AHazeActor DJDanceManager;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartCrowdEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopCrowdEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CheersCrowdEvent;

	int LastRoundIndex = -2;

	private bool bDebugDropOActive = true;
	private bool bDebugText = false;

#if TEST
	float ElapsedDebugTime = 0.0f;

	bool bWasDebugEnabled = false;
	bool bWasSuperDanceMode = false;
#endif // TEST

	void SetDropOMeterActive(bool bValue)
	{
		if(bDebugText)
			BP_OnUpdateActive(bValue);

		bDebugDropOActive = bValue;
	}

	void ToggleDropOActive()
	{
		NetToggleDropOMeter();
	}

	UFUNCTION()
	void EnableBassDropOMeter()
	{
		SetActorTickEnabled(true);
	}

	UFUNCTION(NetFunction)
	private void NetToggleDropOMeter()
	{
		SetDropOMeterActive(!bDebugDropOActive);
	}

	void ToggleDebugText()
	{
		NetToggleDebugText();
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	private void NetToggleDebugText()
	{
		bDebugText = !bDebugText;
		SetDebugEnabled_DJStations(DJDanceManager, bDebugText);
	}

	UFUNCTION()
	void AddToMasterMeter(float ValueToAdd)
	{
#if TEST
		if(!bDebugDropOActive)
			return;
#endif // TEST
		TargetBassDropValue = FMath::Min(TargetBassDropValue + ValueToAdd, 1.0f);
	}

	UFUNCTION()
	void RemoveFromMasterMeter(float ValueToRemove)
	{
#if TEST
		if(!bDebugDropOActive)
			return;
#endif // TEST
		if(!CanRemoveFromMasterMeter())
			return;

		TargetBassDropValue = FMath::Max(TargetBassDropValue - ValueToRemove, 0.0f);
	}

	UFUNCTION(meta = (DevelopmentOnly))
	void Dev_AddToMasterMeter(float ValueToAdd)
	{
		Dev_NetAddToMasterMeter(ValueToAdd);
	}

	bool CanRemoveFromMasterMeter() const
	{
		if(!bPreventFailAfterDuration)
			return true;

		return PreventFailElapsed >= 0.0f;
	}

	UFUNCTION(NetFunction)
	private void Dev_NetAddToMasterMeter(float ValueToAdd)
	{
		TargetBassDropValue = FMath::Min(TargetBassDropValue + ValueToAdd, 1.0f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{	
		PreventFailElapsed -= DeltaTime;
#if TEST
		const bool bIsDebugEnabled = bDebugText;
		const bool bIsSuperDanceMode = bIsDebugEnabled && IsSuperDanceMode(DJDanceManager);
		const int CurrentRoundIndex = GetCurrentRoundIndex(DJDanceManager);

		if(bIsDebugEnabled && !bWasDebugEnabled)
		{
			BP_OnActivateDebugDraw();
			BP_OnUpdateActive(bDebugDropOActive);
			BP_OnUpdateRoundIndex(CurrentRoundIndex);
		}
		else if(!bIsDebugEnabled && bWasDebugEnabled)
		{
			BP_OnDisableDebugDraw();
		}

		if(bIsSuperDanceMode && !bWasSuperDanceMode)
		{
			BP_OnActivateSuperDanceMode();
		}
		else if(!bIsSuperDanceMode && bWasSuperDanceMode)
		{
			BP_OnDisableSuperDanceMode();
		}

		if(bIsDebugEnabled)
		{
			BP_OnUpdateDropOMeterDebug(CurrentBassDropMaster, TargetBassDropValue);

			if(bIsSuperDanceMode)
			{
				ElapsedDebugTime += (12.0f * CurrentBassDropMaster) * DeltaTime;
				float R = FMath::MakePulsatingValue(ElapsedDebugTime, 0.1f);
				float G = FMath::MakePulsatingValue(ElapsedDebugTime, 0.2f);
				float B = FMath::MakePulsatingValue(ElapsedDebugTime, 0.3f);
				BP_OnUpdateSuperDanceMode(FLinearColor(R, G, B));
			}

			if(LastRoundIndex != CurrentRoundIndex)
			{
				BP_OnUpdateRoundIndex(CurrentRoundIndex);
			}
		}

		bWasDebugEnabled = bIsDebugEnabled;
		bWasSuperDanceMode = bIsSuperDanceMode;
		LastRoundIndex = CurrentRoundIndex;
#endif // TEST
	}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Activate Debug Draw"))
	void BP_OnActivateDebugDraw() {}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Disable Debug Draw"))
	void BP_OnDisableDebugDraw() {}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Update Drop O Meter Debug"))
	void BP_OnUpdateDropOMeterDebug(float Current, float Target) {}

	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Activate Super Dance Mode"))
	void BP_OnActivateSuperDanceMode() {}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Disable Super Dance Mode"))
	void BP_OnDisableSuperDanceMode() {}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Update Super Dance Mode"))
	void BP_OnUpdateSuperDanceMode(FLinearColor NewColor) {}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Update Active"))
	void BP_OnUpdateActive(bool bDropOMeterActive) {}
	UFUNCTION(BlueprintEvent, meta = (DisplayName = "On Update CurrentRound Index"))
	void BP_OnUpdateRoundIndex(int CurrentRoundIndex) {}
}
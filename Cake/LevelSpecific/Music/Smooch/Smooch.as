import Cake.LevelSpecific.Music.Smooch.SmoochHoldWidget;
import Peanuts.Audio.AudioStatics;

delegate void FSmoochCallback();
const float SmoochHoldTime = 24.f;
const float SmoochPeekPercent = 0.05f;
const float SmoochAdvancePercent = 0.05f;
const float SmoochMaxProgress = 0.965f;

struct FPlayAudioOnSmoochProgress
{
	UPROPERTY()
	float ProgressToPlayAudio = 0.f;

	UPROPERTY()
	UAkAudioEvent ProgressAudioEvent;

	bool bHasPlayedAudio = false;
}

class USmoochUserComponent : UActorComponent
{
	UPROPERTY(Category = "Widget", EditDefaultsOnly)
	TSubclassOf<USmoochHoldWidget> HoldWidgetType;

	UPROPERTY(Category = "Widget", EditDefaultsOnly)
	TSubclassOf<USmoochHoldButtonWidget> ButtonWidgetType;

	UPROPERTY(Category = "Animation", EditDefaultsOnly)
	TPerPlayer<UHazeLocomotionFeatureBase> AnimFeature;
	
	UPROPERTY()
	TArray<FPlayAudioOnSmoochProgress> MayAudioSmoochProgressDatas;

	UPROPERTY()
	TArray<FPlayAudioOnSmoochProgress> CodyAudioSmoochProgressDatas;

	UPROPERTY(BlueprintReadOnly)
	bool bIsHolding = false;
	bool bHasFinished = false;

	UPROPERTY(Category = "Smooch", BlueprintReadOnly)
	float Progress = 0.f;

	void FinishProgress()
	{
		Sync::FullSyncPoint(this, n"FinishProgressSyncPoint");
	}

	UFUNCTION()
	void FinishProgressSyncPoint()
	{
		OnCompleted.ExecuteIfBound();
	}	

	UFUNCTION(BlueprintEvent)
	void OnSmoochBegin() {}

	UFUNCTION(BlueprintEvent)
	void OnSmoochEnd() {}

	FSmoochCallback OnCompleted;
	UHazeCapabilitySheet OwningSheetType;
	AHazeLevelSequenceActor CameraSequence;
	AHazeActor RotateRoot;

	USmoochHoldButtonWidget ButtonWidget;
}

UFUNCTION(Category = "Music|Smoochin")
void StartSmooch(UHazeCapabilitySheet Sheet, AHazeLevelSequenceActor CameraSequence, AHazeActor RotateRoot, FSmoochCallback OnCompleted)
{
	for(auto Player : Game::Players)
		Player.AddCapabilitySheet(Sheet, EHazeCapabilitySheetPriority::Normal, nullptr);

	// Set some 'global' settings on May's component
	auto SmoochComp = USmoochUserComponent::Get(Game::May);
	SmoochComp.OnCompleted = OnCompleted;
	SmoochComp.OwningSheetType = Sheet;
	SmoochComp.CameraSequence = CameraSequence;
	SmoochComp.RotateRoot = RotateRoot;
}

//UFUNCTION()
//void Tick(float DeltaTime)
//{
//	
//}

UFUNCTION(Category = "Music|Smoochin")
void EndSmooch()
{
	auto SmoochComp = USmoochUserComponent::Get(Game::May);
	auto SheetType = SmoochComp.OwningSheetType;

	Game::May.RemoveCapabilitySheet(SheetType);
	Game::Cody.RemoveCapabilitySheet(SheetType);
}

UFUNCTION(BlueprintPure, Category = "Music|Smoochin")
float GetSmoochMinimumProgress()
{
	float Progress = BIG_NUMBER;
	for(auto Player : Game::Players)
	{
		auto SmoochComp = USmoochUserComponent::Get(Player);
		if (SmoochComp == nullptr)
			return 0.f;

		Progress = FMath::Min(Progress, SmoochComp.Progress);
	}

	return Progress;
}

UFUNCTION(BlueprintPure, Category = "Music|Smoochin")
int GetSmoochNumPlayersHolding()
{
	int HoldCount = 0;
	for(auto Player : Game::Players)
	{
		auto SmoochComp = USmoochUserComponent::Get(Player);
		if (SmoochComp != nullptr && SmoochComp.bIsHolding)
			HoldCount++;
	}

	return HoldCount;
}

UFUNCTION(BlueprintPure, Category = "Music|Smoochin")
bool HasBothPlayersFinishedSmooch()
{
	int FinishCount = 0;
	for(auto Player : Game::Players)
	{
		auto SmoochComp = USmoochUserComponent::Get(Player);
		if (SmoochComp != nullptr && SmoochComp.bHasFinished)
			FinishCount++;
	}

	return FinishCount == 2;
}

enum EFoghornEventState
{
	PreDelay,
	Playing,
	Finished
}

struct FFoghornMultiActors
{
	AActor Actor1 = nullptr;
	AActor Actor2 = nullptr;
	AActor Actor3 = nullptr;
	AActor Actor4 = nullptr;
}

struct FFoghornResumeInfo
{
	UFoghornBarkDataAsset BarkAsset = nullptr;
	UFoghornDialogueDataAsset DialogueAsset = nullptr;
	AActor Actor = nullptr;
	FFoghornMultiActors Actors;
	AActor ActiveActor = nullptr;
	int VoiceLineIndex = -1;
	bool SkipResumeTransitions = false;
	float Playime = 0.0f;
}

#if !RELEASE
struct FFoghornEventDebugInfo
{
	FString Asset;
	FString Type;
	AActor Actor;
	int Priority;
	float PreDelayTimer;
}
#endif

UCLASS(Abstract)
class UFoghornEventBase
{
	FFoghornResumeInfo Stop() { return FFoghornResumeInfo(); }
	void PauseAkEvent() {}
	void ResumeAkEvent() {}

	void Initialize() {}
	bool Tick(float DeltaTime) { return true; }

	int GetPriority() property {return 0; }
	AActor GetActiveActor() property { return nullptr; }

	void OnReplacedInLane() {}

	#if !RELEASE
	FFoghornEventDebugInfo GetDebugInfo() property {return FFoghornEventDebugInfo(); }
	#endif

}

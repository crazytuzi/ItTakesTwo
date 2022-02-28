USTRUCT()
struct FAmbientZoneLinkedActor
{	
	UPROPERTY(BlueprintReadWrite)
	AHazeActor Actor = nullptr;
	UPROPERTY(NotVisible)
	UHazeAkComponent HazeAkComp = nullptr;
	UPROPERTY(NotVisible)
	int32 HighestLinkedZonePriority = 0.f;
}
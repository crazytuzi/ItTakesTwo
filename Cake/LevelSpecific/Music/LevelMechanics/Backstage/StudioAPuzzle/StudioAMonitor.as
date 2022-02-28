import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongInfo;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioAStatics;

// Called when Monitor handles song impact. StudioAMovingPlatform listens for this event and moves accordingly
event void FStudioAMonitorSignature(EMonitorDirection Direction);
event void FStudioAMonitorSignatureBool(bool bStarted, EMonitorDirection Direction);

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AStudioAMonitor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MonitorMesh;

	FStudioAMonitorSignature MonitorHandledPowerfulSongImpact;

	FStudioAMonitorSignatureBool MonitorHandledSongOfLife;

	UPROPERTY()
	EMonitorDirection MonitorDirection;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"PowerfulSongAbstractShootCapability");
	}

	void HandlePowerfulSongImpact()
	{
		MonitorHandledPowerfulSongImpact.Broadcast(MonitorDirection);
	}

	void HandleSongOfLife(bool bStarted)
	{
		MonitorHandledSongOfLife.Broadcast(bStarted, MonitorDirection);
	}

	
}
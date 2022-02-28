import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.Environment.BreakableComponent;
import Cake.Environment.BreakableStatics;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;

UCLASS(Abstract)
class APowerfulSong : AHazeActor
{
	default SetActorHiddenInGame(true);

	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ConeRoot;

	UPROPERTY(DefaultComponent, Attach = ConeRoot)
	UStaticMeshComponent ConeMesh;

	UPROPERTY(DefaultComponent, Attach = ConeRoot)
	UArrowComponent SongDirection;

	void ActivatePowerfulSong()
	{
		SetActorHiddenInGame(false);
	}

	void DeactivatePowerfulSong()
	{
		SetActorHiddenInGame(true);
	}
}

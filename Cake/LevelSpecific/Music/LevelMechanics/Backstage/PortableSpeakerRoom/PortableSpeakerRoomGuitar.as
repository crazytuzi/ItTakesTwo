import Cake.LevelSpecific.Music.LevelMechanics.Backstage.PortableSpeakerRoom.PortableSpeakerRoomGuitarAmp;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class PortableSpeakerRoomGuitar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent GuitarMesh;

	UPROPERTY(DefaultComponent)
	USongReactionComponent SongReaction;

	UPROPERTY()
	APortableSpeakerRoomGuitarAmp ConnectedAmp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}

	UFUNCTION()
	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		ConnectedAmp.LaunchPlayer();
	}
}
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioAMonitor;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SwayMicrophoneComponent;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AStudioAMicrophone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MicMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MicMeshLegs;

	UPROPERTY(DefaultComponent, ShowOnActor, Attach = MicMesh)
	USongReactionComponent SongReaction;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	USphereComponent SphereCollision;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 128.0f;

	UPROPERTY()
	AStudioAMonitor ConnectedMonitor;

	UPROPERTY()
	AHazePlayerCharacter May;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}

	UFUNCTION(NotBlueprintCallable)
	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		USingingComponent SingingComp = USingingComponent::Get(Info.Instigator);

		if (ConnectedMonitor == nullptr)
			return;			

		ConnectedMonitor.HandlePowerfulSongImpact();	
	}

	UFUNCTION()
	void SongOfLifeStart(FSongOfLifeInfo Info)
	{
		SongOfLifeInMic(true);
	}

	UFUNCTION()
	void SongOfLifeStop(FSongOfLifeInfo Info)
	{
		SongOfLifeInMic(false);
	}

	void SongOfLifeInMic(bool bSinging)
	{
		if (ConnectedMonitor == nullptr)
			return;			
		ConnectedMonitor.HandleSongOfLife(bSinging); 
	}
}
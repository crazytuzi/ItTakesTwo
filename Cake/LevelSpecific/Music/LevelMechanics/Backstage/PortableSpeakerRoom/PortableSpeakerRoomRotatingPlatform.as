import Cake.LevelSpecific.Music.LevelMechanics.Backstage.PortableSpeakerRoom.PortableSpeakerRoomDoor;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.PortableSpeakerRoom.PortableSpeakerRoomDoorStopper;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class APortableSpeakerRoomRotatingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USongReactionComponent SongReaction;

	UPROPERTY()
	FHazeTimeLike RotateActorTimeline;

	UPROPERTY()
	APortableSpeakerRoomDoor ConnectedDoor;

	UPROPERTY()
	float TimelineDuration = 2.f;
	
	bool bShouldRotate = false;

	float RotationToAdd = 0.f;

	float RotationTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"SongImpact");
		
		RotateActorTimeline.BindUpdate(this, n"RotateActorTimelineUpdate");
		RotateActorTimeline.SetPlayRate(1 / TimelineDuration);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldRotate)
			return;

		MeshRoot.AddLocalRotation(FRotator(0.f, 0.f, RotationToAdd * DeltaTime));

		RotationTimer += DeltaTime;
		
		if (RotationTimer >= TimelineDuration)
		{
			bShouldRotate = false;
			RotationTimer = 0.f;
		}
	}

	UFUNCTION()
	void RotateActorTimelineUpdate(float CurrentValue)
	{
		RotationToAdd = FMath::Lerp(0.f, 900.f, CurrentValue);
	} 

	UFUNCTION()
	void SongImpact(FPowerfulSongInfo Info)
	{
		if (Info.Instigator == Game::GetMay())
			return;

		if (!bShouldRotate)
		{
			bShouldRotate = true;	
			RotateActorTimeline.PlayFromStart();
			ConnectedDoor.MoveDoor();
		}
	}
}
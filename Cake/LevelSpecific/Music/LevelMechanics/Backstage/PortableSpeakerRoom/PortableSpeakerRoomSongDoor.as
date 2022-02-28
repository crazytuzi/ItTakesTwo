import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class APortableSpeakerRoomSongDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	USongReactionComponent SongReaction;

	bool bHasBeenOpened = false;

	UPROPERTY()
	FHazeTimeLike OpenDoorWrongWayTimeline;

	UPROPERTY()
	FHazeTimeLike OpenDoorRightWayTimeline;

	FRotator StartRot = FRotator::ZeroRotator;
	FRotator TargetRotWrongWay = FRotator(0.f, -5.f, 0.f);
	FRotator TargetRotRightWay = FRotator(0.f, -135.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenDoorWrongWayTimeline.BindUpdate(this, n"DoorWrongWayTimelineUpdate");
		OpenDoorRightWayTimeline.BindUpdate(this, n"DoorRightWayTimelineUpdate");

		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"SongImpact");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		System::DrawDebugArrow(GetActorLocation(), GetActorLocation() + (MeshRoot.ForwardVector * 500.f), 10.f);
	}

	UFUNCTION()
	void DoorWrongWayTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartRot, TargetRotWrongWay, CurrentValue));
	}

	UFUNCTION()
	void DoorRightWayTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartRot, TargetRotRightWay, CurrentValue));
	}

	UFUNCTION()
	void SongImpact(FPowerfulSongInfo Info)
	{
		if (bHasBeenOpened)
			return;

		if (Info.Instigator == Game::GetMay())
		{
			OpenDoorWrongWayTimeline.PlayFromStart();
		}
		else
		{
			OpenDoorRightWayTimeline.PlayFromStart();
			bHasBeenOpened = true;
		}		
	}
}
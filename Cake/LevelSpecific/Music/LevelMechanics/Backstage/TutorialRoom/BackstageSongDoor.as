import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

event void FOnSongDoorOpen();
class ABackstageSongDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent DoorMesh;
	UPROPERTY(DefaultComponent, Attach = DoorMesh)
	UArrowComponent NewTargetLocation;
	UPROPERTY(DefaultComponent, Attach = DoorMesh)
	USongOfLifeComponent SongOfLifeComponent;

	UPROPERTY()
	FOnSongDoorOpen OnSongDoorOpen;


	bool bSongOfLifeActive = false;
//	bool bPowerfulSongActive = false;
	FHazeAcceleratedVector AcceleratedVector;
	FVector NewTargetLocationValue;
	FVector NewActorLocationValue;
	FVector ActorOriginalLoction;
	UPROPERTY()
	float PlatformSpeedUp = 10;
	UPROPERTY()
	float PlatformSpeedDown = 10;
	UPROPERTY()
	float StiffnessUp = 0.475f;
	UPROPERTY()
	float StiffnessDown = 0.85f;

	float SongOfLifeActiveTime = 0;
	bool bBroadCastSent = false;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongOfLifeComponent.OnStartAffectedBySongOfLife.AddUFunction(this, n"SongOfLifeStarted");
		SongOfLifeComponent.OnStopAffectedBySongOfLife.AddUFunction(this, n"SongOfLifeEnded");
		AcceleratedVector.Value = GetActorLocation();
		NewTargetLocationValue = NewTargetLocation.GetWorldLocation();
		ActorOriginalLoction = GetActorLocation();
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bSongOfLifeActive)
		{
			AcceleratedVector.SpringTo(NewTargetLocationValue, PlatformSpeedUp, StiffnessUp, DeltaSeconds);
			NewActorLocationValue = AcceleratedVector.Value;
			SetActorLocation(AcceleratedVector.Value);

			if(Game::GetMay().HasControl())
			{
				if(bBroadCastSent == false)
				{
					SongOfLifeActiveTime += DeltaSeconds;
					if(SongOfLifeActiveTime >= 1.0f)
					{
						bBroadCastSent = true;
						NetBroadCastDoorOpen();
					}
				}
			}
		}
		if(!bSongOfLifeActive)
		{
			SongOfLifeActiveTime = 0;
			AcceleratedVector.SpringTo(ActorOriginalLoction, PlatformSpeedDown, StiffnessDown, DeltaSeconds);
			NewActorLocationValue = AcceleratedVector.Value;
			SetActorLocation(AcceleratedVector.Value);
		}
	}

	UFUNCTION(NetFunction)
	void NetBroadCastDoorOpen()
	{
		OnSongDoorOpen.Broadcast();
	}

	UFUNCTION()
	void SongOfLifeStarted(FSongOfLifeInfo Info)
	{
		bSongOfLifeActive = true;
	}
	UFUNCTION()
	void SongOfLifeEnded(FSongOfLifeInfo Info)
	{
		bSongOfLifeActive = false;
	}
}


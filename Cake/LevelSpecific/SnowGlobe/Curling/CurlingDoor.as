import Cake.LevelSpecific.SnowGlobe.Curling.StaticsCurling;

event void FDoorHasOpened();

class ACurlingDoor : AHazeActor
{
	FDoorHasOpened EventDoorHasOpened;

	UPROPERTY(Category = "Setup")
	ECurlingPlayerTarget PlayerTarget;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp; 

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UBoxComponent BoxCollision;
	default BoxCollision.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(Category = "Capabilities")
	TSubclassOf<UHazeCapability> DoorCapability;

	UPROPERTY(Category = "Setup")
	UMaterialInterface DoorMaterial;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent ShuffleAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OpenDoorEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CloseDoorEvent;

	FVector OpenDoorLoc;
	FVector ClosedDoorLoc;

	bool bCanActivateDoor;
	bool bIsOpening;

	float OpenValue = -1550.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.SetMaterial(0, DoorMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenDoorLoc = MeshComp.RelativeLocation + FVector(0.f, 0.f, OpenValue);

		ClosedDoorLoc = MeshComp.RelativeLocation;
		
		AddCapability(DoorCapability);
	}

	void AudioOpenDoorEvent()
	{
		ShuffleAkComp.HazePostEvent(OpenDoorEvent);
	}
	
	void AudioCloseDoorEvent()
	{
		ShuffleAkComp.HazePostEvent(CloseDoorEvent);
	}
}
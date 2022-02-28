import Cake.LevelSpecific.Garden.LevelActors.WateringPlantActor;

event void FOnPlantDoorOpened();

UCLASS(Abstract)
class AGardenPlantDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USkeletalMeshComponent StalkSkelMesh;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	UPROPERTY(EditInstanceOnly, Category = "Setup")
	AWateringPlantActor WateringPlantActor;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoorOpenAudioEvent;

	UPROPERTY(Category = "Animation Data")
	bool bIsClosed = false;

	UPROPERTY(Category = "Animation Data")
	float ExtraDoorRotation;

	UPROPERTY()
	FOnPlantDoorOpened OnDoorOpened;

	bool bIsOpen;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(WateringPlantActor != nullptr)
		{
			WateringPlantActor.AttachToComponent(StalkSkelMesh, n"PlantSocket", EAttachmentRule::SnapToTarget);
			FHitResult Hit;
			WateringPlantActor.SetActorRelativeRotation(FRotator(90.f, 0.f, 0.f),false, Hit, false);

			WateringPlantActor.OnWateringPlantFinished.AddUFunction(this, n"OnFullyWatered");
		}
	}

	UFUNCTION()
	void OnFullyWatered()
	{
		bIsOpen = true;
		OnDoorOpened.Broadcast();
		UHazeAkComponent::GetOrCreate(this).HazePostEvent(DoorOpenAudioEvent);
	}

	UFUNCTION()
	void SetCompletedAndClosed()
	{
		bIsOpen = false;
		
		if(WateringPlantActor != nullptr)
		{
			WateringPlantActor.VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			WateringPlantActor.WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}

	}

	UFUNCTION()
	void SetCompleted(bool ShouldBroadcastComplete)
	{
		bIsOpen = true;

		if(WateringPlantActor != nullptr)
		{
			WateringPlantActor.VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			WateringPlantActor.WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}

		if(ShouldBroadcastComplete)
			OnDoorOpened.Broadcast();
	}
}
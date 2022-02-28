import Cake.LevelSpecific.Garden.LevelActors.GardenPlantDoor;
class UGardenGardenPlantStalkAnimInstance : UHazeAnimInstanceBase
{
    UPROPERTY(Category = "GardenPlantStalk")
    FHazePlaySequenceData MH;

	UPROPERTY(Category = "GardenPlantStalk_Door")
    FHazePlaySequenceData DoorMH;

	UPROPERTY(Category = "GardenPlantStalk_Door")
    FHazePlaySequenceData DoorOpen;

	UPROPERTY(Category = "GardenPlantStalk_Door")
    FHazePlaySequenceData DoorOpenMH;

	UPROPERTY(Category = "GardenPlantStalk_Door")
    FHazePlaySequenceData DoorClose;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator ExtraDoorRootation;

	UPROPERTY(BlueprintReadOnly)
	bool bIsDoor = false;
	UPROPERTY(BlueprintReadOnly)
	bool bIsOpened = false;

	AGardenPlantDoor PlantActor;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		PlantActor = Cast<AGardenPlantDoor>(OwningActor);

		if(PlantActor == nullptr)
			return;
			
		bIsDoor = PlantActor.bIsClosed;
		ExtraDoorRootation.Pitch = PlantActor.ExtraDoorRotation;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (PlantActor == nullptr)
            return;

		bIsOpened = PlantActor.bIsOpen;

		if (PlantActor.WateringPlantActor == nullptr)
			return;

		if (PlantActor.WateringPlantActor.bIsAttached)
		{
			const float TargetRotation = (1 - PlantActor.WateringPlantActor.WaterAmount) * 5.f;
			ExtraDoorRootation.Pitch = FMath::FInterpTo(ExtraDoorRootation.Pitch, 0, DeltaTime, 2.f);
		}
		else if (ExtraDoorRootation.Pitch != 20)
		{
			ExtraDoorRootation.Pitch = FMath::FInterpTo(ExtraDoorRootation.Pitch, PlantActor.ExtraDoorRotation, DeltaTime, 2.f);
		}

    }

}
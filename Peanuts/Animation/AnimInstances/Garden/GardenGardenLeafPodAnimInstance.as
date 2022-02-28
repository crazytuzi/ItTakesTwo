class UGardenGardenLeafPodAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData Mh;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData PollenPuff;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData VineAttach;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData VineDetach;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlayRndSequenceData Hits;

	UPROPERTY(Category = "GardenLeafPod")
    FHazePlaySequenceData Death;

	UPROPERTY(Category = "GardenLeafPodFoutain")
    FHazePlaySequenceData MhFountain;

	UPROPERTY(Category = "GardenLeafPodFoutain")
    FHazePlaySequenceData PollenPuffFountain;
	
	UPROPERTY(Category = "GardenLeafPodFoutain")
    FHazePlayRndSequenceData HitsFountain;

	UPROPERTY(Category = "GardenLeafPodFoutain")
    FHazePlaySequenceData DeathFountain;

	UPROPERTY(Category = "GardenLeafPodGreenHouse")
    FHazePlaySequenceData MhGreenHouse;

	UPROPERTY(Category = "GardenLeafPodGreenHouse")
    FHazePlaySequenceData PollenPuffGreenHouse;
	
	UPROPERTY(Category = "GardenLeafPodGreenHouse")
    FHazePlayRndSequenceData HitsGreenHouse;

	UPROPERTY(Category = "GardenLeafPodGreenHouse")
    FHazePlaySequenceData DeathGreenHouse;

	UPROPERTY(Category = "GardenLeafPodNoStalk")
    FHazePlaySequenceData MhNoStalk;

	UPROPERTY(Category = "GardenLeafPodNoStalk")
    FHazePlaySequenceData PollenPuffNoStalk;
	
	UPROPERTY(Category = "GardenLeafPodNoStalk")
    FHazePlayRndSequenceData HitsNoStalk;

	UPROPERTY(Category = "GardenLeafPodNoStalk")
    FHazePlaySequenceData DeathNoStalk;


	UPROPERTY()
	bool bIsPollenPuff;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        System::SetTimer(this, n"SetRandomPollenPuff", 40.f, true, 2.f, 10.f);

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

    }

	UFUNCTION()
	void SetRandomPollenPuff()
	{
		bIsPollenPuff = true;
		System::SetTimer(this, n"SetRandomPollenPuffFalse", 0.1f, false);

	}

	UFUNCTION()
	void SetRandomPollenPuffFalse()
	{
		bIsPollenPuff = false;

	}

    

}
import Cake.LevelSpecific.Garden.Greenhouse.JoyHammerPlant;

class UGardenVinesHammerBossAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(Category = "Animations General")
	FHazePlaySequenceData Hidden;

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData Appear;

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData BackToHiding;

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData PrepareToSlamMh;

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData MhToPrepareSlam;

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData Slam;

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData SlamExit;	

	UPROPERTY(Category = "Phase 1")
	FHazePlaySequenceData SlamExitToMh;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData AppearPhase3;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData MhPhase3;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData BackToHidingPhase3;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData MhToPrepareSlamPhase3;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData PrepareToSlamMhPhase3;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData SlamPhase3;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData SlamExitPhase3;	

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData SlamExitToMhPhase3;

	UPROPERTY(Category = "Phase 3")
	FHazePlaySequenceData SlamPlateDestroyed;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlantIdle;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlantPrepareSmash;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlantSmash;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlantAlive;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPhase3;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlateDestroyed;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector HeadScale = FVector(1, 1, 1);

	UPROPERTY(NotEditable, BlueprintReadOnly)
	float RandomStartPos = 0.f;


	AJoyHammerPlant PlantHammer;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		PlantHammer = Cast<AJoyHammerPlant>(OwningActor);
		if (PlantHammer == nullptr)
			return;

		HeadScale = PlantHammer.HeadScale;
		RandomStartPos = FMath::RandRange(0.f, 1.f);
	
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		// Valid check the actor
		if(PlantHammer == nullptr)
			return;

		bPlantAlive = PlantHammer.bPlantIdle;
		bPlantIdle = PlantHammer.bPlantIdle;
		bPlantPrepareSmash = PlantHammer.bPlantPrepareSmash;
		bPlantSmash = PlantHammer.bPlantSmash;
		bPhase3 = PlantHammer.bPlantIsInPhase3;
		
		if (PlantHammer.JoyPotGrowingPlant != nullptr)
			bPlateDestroyed = PlantHammer.JoyPotGrowingPlant.bPlateDestroyed;

	}

}
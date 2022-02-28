import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenGroundVines;
import Cake.LevelSpecific.Garden.Greenhouse.JoyPotGrowingPlants;

class UGardenGroundVinesJoyBossAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureGardenGroundVines GardenGroundVinesFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlateFallDown;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRisePlateFromGround;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlateDestroyed;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSkipEnter;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSkipBeginning;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGoToMh;

	AJoyPotGrowingPlants PlantsActor;

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		if (OwningActor == nullptr)
			return;

		PlantsActor = Cast<AJoyPotGrowingPlants>(OwningActor);
		if (PlantsActor != nullptr)
			GardenGroundVinesFeature = PlantsActor.GardenGroundVinesFeature;
			
		bGoToMh = false;
	}

	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (PlantsActor == nullptr)
			return;

		bPlateFallDown = PlantsActor.bPlateFallDown;
		bRisePlateFromGround = PlantsActor.bRisePlateFromGround;
		bExit = PlantsActor.bExit;
		bPlateDestroyed = PlantsActor.bPlateDestroyed;
		bHitReaction = GetAnimBoolParam(n"TookDamage", true);
		bSkipBeginning = GetAnimBoolParam(n"SkipBeginning", true);
	}

	UFUNCTION()	
	void GoToMhState()
	{
		bGoToMh = true;
	}
}
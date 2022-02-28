// Imports
import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenVinesSwiper;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantHammer;

class UGardenVinesHammerAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Hidden;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Appear;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(Category = "Animations")
	FHazePlayBlendSpaceData Struggle;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData AttackSlam;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData ReleaseStruggleSlam;

	UPROPERTY(Category = "Animations")
	FHazePlaySequenceData Death;


	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsAlive;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlayAttackAnimation;

	UPROPERTY()
	float MashProgress;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlayStruggle;

	ABossControllablePlantHammer PlantHammer;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		PlantHammer = Cast<ABossControllablePlantHammer>(OwningActor);
		
	}

	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		// Valid check the actor
		if(PlantHammer == nullptr)
			return;

		const float CurrentMashProgress = PlantHammer.CurrentMashProgress;
		if (CurrentMashProgress > MashProgress)
		{
			MashProgress = CurrentMashProgress;
		}

		bPlayStruggle = (CurrentMashProgress > 0.2f);
		bPlayAttackAnimation = (PlantHammer.bPlayerIsInRange && MashProgress < 0.9f);

		bIsAlive = PlantHammer.bIsAlive;

	}

}
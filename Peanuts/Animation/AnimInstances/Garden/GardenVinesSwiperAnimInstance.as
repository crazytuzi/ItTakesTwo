// Imports
import Peanuts.Animation.Features.Garden.LocomotionFeatureGardenVinesSwiper;
import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantSwiper;

class UGardenVinesSwiperAnimInstance : UHazeAnimInstanceBase
{

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsAlive;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bPlaySwipeAttack = false;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	bool bIsButtonMashing;

	// A float between 0 - 1 depending on how much Cody has taken over the plant (w/ button mash)
	UPROPERTY(NotEditable, BlueprintReadOnly)
	float MashProgress = 0.0f;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	FVector2D StickInput;

	UPROPERTY(NotEditable, BlueprintReadOnly)
	ULocomotionFeatureGardenVinesSwiper Feature;

	ABossControllablePlantSwiper PlantSwiper;


	// On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		PlantSwiper = Cast<ABossControllablePlantSwiper>(OwningActor);
		if (PlantSwiper == nullptr)
			return;
		Feature = PlantSwiper.LocomotionFeature;

	}


	// On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		// Valid check the actor
		if(PlantSwiper == nullptr)
			return;

		const float CurrentMashProgress = PlantSwiper.CurrentMashProgress;
		float InterpSpeed = 20.0f;
		
		if (MashProgress > CurrentMashProgress)
		{
			InterpSpeed = 1.7f;
		}
		MashProgress = FMath::FInterpTo(MashProgress, CurrentMashProgress, DeltaTime, InterpSpeed);
		//Print("MP: " + MashProgress);

		bIsButtonMashing = (CurrentMashProgress != 0.0f);
		bPlaySwipeAttack = (PlantSwiper.bPlayerIsOnBridge && CurrentMashProgress < 0.9f);

		bIsAlive = PlantSwiper.bIsAlive;
		StickInput = PlantSwiper.StickInput;
		//Print("+a"+StickInput);

	}

}
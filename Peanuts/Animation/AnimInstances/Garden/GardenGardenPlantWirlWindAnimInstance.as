import Cake.LevelSpecific.Garden.ControllablePlants.Dandelion.DandelionLaunchPad;

class UGardenGardenPlantWirlWindAnimInstance : UHazeAnimInstanceBase
{
    UPROPERTY(Category = "GardenPlantWirlWind")
    FHazePlayBlendSpaceData BS_MHSpin;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float YawRotation = 0.f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float WaterAmount = 0.f;

	float RotationSpeed = 800.f;

	ADandelionLaunchPad DandelionActor;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

        DandelionActor = Cast<ADandelionLaunchPad>(OwningActor);

		if(DandelionActor != nullptr)
			RotationSpeed = DandelionActor.LeafRotationSpeed;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;

		if(DandelionActor != nullptr && DandelionActor.WateringPlant != nullptr)
		{
			WaterAmount = DandelionActor.WateringPlant.WaterAmount;

			//Calculate YawRotation
			YawRotation = Math::FWrap(YawRotation + (DeltaTime * (-RotationSpeed * WaterAmount)), 0.f, 360.f);
		}
    }
}
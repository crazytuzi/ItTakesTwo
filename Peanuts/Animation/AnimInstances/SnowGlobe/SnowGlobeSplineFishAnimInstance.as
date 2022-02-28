import Vino.Animations.PoseTrailComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.SnowGlobeSplineFish;
import Cake.LevelSpecific.SnowGlobe.MagnetHarpoon.MagnetFishActor;

class USnowGlobeSplineFishAnimInstance : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FSplineFishBoneRotations BoneRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "SplineFish")	
	float AnimAmplitudeScale = 1.f;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "MagnetFish")	
	FRotator RootRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "MagnetFish")
	float PlayRate = 0.7f;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "MagnetFish")
	bool bCaught;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "MagnetFish")
	EMagnetFishState FishState;

	UPoseTrailComponent PoseTrailComp;
	ASnowGlobeSplineFish SplineFish;
	AMagnetFishActor MagnetFish;

	FVector PrevWorldLocation;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        PoseTrailComp = UPoseTrailComponent::Get(OwningActor);
		SplineFish = Cast<ASnowGlobeSplineFish>(OwningActor);
		MagnetFish = Cast<AMagnetFishActor>(OwningActor);

    }
    


    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (PoseTrailComp == nullptr)
            return;
			
		SnowGlobeSplineFish::GetSplineFishPose(PoseTrailComp, BoneRotation);

		if (MagnetFish != nullptr)
		{
			PlayRate = MagnetFish.PlayRateMultiplier * 0.7f;
			FishState = MagnetFish.MagnetFishState;
			bCaught = FishState == EMagnetFishState::Caught;
			
			if (FishState == EMagnetFishState::Released)
			{
				const FVector DeltaVector  = OwningActor.ActorLocation - PrevWorldLocation;
				PrevWorldLocation = OwningActor.ActorLocation;
				RootRotation = (DeltaVector * DeltaTime).Rotation();
			}

		}
		else if (SplineFish != nullptr)
		{
			AnimAmplitudeScale = FMath::GetMappedRangeValueClamped(FVector2D(500.f, 2000.f), FVector2D(0.5f, 1.f), SplineFish.SpeedAlongSpline);
		}
    }

    

}
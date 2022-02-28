import Peanuts.Animation.Features.ClockWork.LocomotionFeatureClockWorkPedalBoat;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPlayerComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;
import Peanuts.Animation.AnimInstances.ClockWork.ClockWorkPedalBoatAnimInstance;

class UClockWorkPedalBoatPlayersAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureClockWorkPedalBoat Feature;

	UPROPERTY(BlueprintReadOnly)
	float PedalProgressTime;

	UPROPERTY(BlueprintReadOnly)
	float PedalSpeed;

	UClockWorkPedalBoatAnimInstance BoatAnimInstance;
	bool bIsActorMay;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Feature = Cast<ULocomotionFeatureClockWorkPedalBoat>(GetFeatureAsClass(ULocomotionFeatureClockWorkPedalBoat::StaticClass()));
		const USplineBoatPlayerComponent BoatPlayerComp = Cast<USplineBoatPlayerComponent>(OwningActor.GetComponentByClass(USplineBoatPlayerComponent::StaticClass()));
		if (BoatPlayerComp == nullptr)
			return;
		const ASplineBoatActor SplineBoatActor = Cast<ASplineBoatActor>(BoatPlayerComp.BoatRef);
		BoatAnimInstance = Cast<UClockWorkPedalBoatAnimInstance>(SplineBoatActor.BoatSkeleton.AnimInstance);

		bIsActorMay = (OwningActor == Game::GetMay());

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (BoatAnimInstance == nullptr)
            return;

		if (bIsActorMay)
		{
			PedalProgressTime = BoatAnimInstance.PedalProgressTimeMay;
			PedalSpeed = BoatAnimInstance.MayPedalSpeed;
		}
		else
		{
			PedalProgressTime = BoatAnimInstance.PedalProgressTimeCody;
			PedalSpeed = BoatAnimInstance.CodyPedalSpeed;
		}


    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}
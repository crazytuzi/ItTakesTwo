import Peanuts.Animation.Features.ClockWork.LocomotionFeatureClockWorkHorseDerby;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyPlayerComponent;

class UClockWorkHorseDerbyPlayerAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureClockWorkHorseDerby Feature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PlayRate;

	UPROPERTY(NotEditable)
	float GallopStartPos;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EDerbyHorseMovementState MovementState;

	UHorseDerbyPlayerComponent DerbyComp;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Feature = Cast<ULocomotionFeatureClockWorkHorseDerby>(GetFeatureAsClass(ULocomotionFeatureClockWorkHorseDerby::StaticClass()));
		DerbyComp = Cast<UHorseDerbyPlayerComponent>(OwningActor.GetComponentByClass(UHorseDerbyPlayerComponent::StaticClass()));
		

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (DerbyComp == nullptr)
            return;

		MovementState = DerbyComp.MovementState;
		PlayRate = 1.1f + (DerbyComp.CurrentProgress / 200.f);
    }

	UFUNCTION()
	void ResetGallopStartPosition()
	{
		SetAnimFloatParam(n"GallopStartPos", 0.f);
		GallopStartPos = 0.f;
	}

}
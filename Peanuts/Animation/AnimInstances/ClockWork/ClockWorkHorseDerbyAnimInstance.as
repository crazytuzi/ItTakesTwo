import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;

class UClockWorkHorseDerbyAnimInstance : UHazeAnimInstanceBase
{
    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Trot;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Run;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData Jump;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Jump")
    FHazePlaySequenceData JumpLand;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Crouch")
    FHazePlaySequenceData CrouchEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Crouch")
    FHazePlaySequenceData Crouch;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Crouch")
    FHazePlaySequenceData CrouchExit;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData HitReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EDerbyHorseMovementState MovementState;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float PlayRate = 1.f;

	UPROPERTY(NotEditable)
	float GallopStartPos;

	UDerbyHorseComponent HorseComponent;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

		HorseComponent = Cast<UDerbyHorseComponent>(OwningActor.GetComponentByClass(UDerbyHorseComponent::StaticClass()));
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (HorseComponent == nullptr)
            return;

		MovementState = HorseComponent.MovementState;
		
		PlayRate = 1.1f + (HorseComponent.CurrentProgress / 200.f);

		if (HorseComponent.MovementState == EDerbyHorseMovementState::Hit)
		{
			GallopStartPos = 0.136f;
		}
    }

	UFUNCTION()
	void ResetGallopStartPosition()
	{
		GallopStartPos = 0.f;
	}
}
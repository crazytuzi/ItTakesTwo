import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureCannonFly;
import Peanuts.Animation.AnimationStatics;

class UPlayRoomCannonFlyAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureCannonFly LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator FwdRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator SideRotation;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	FRotator ActorRotation;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureCannonFly>(GetFeatureAsClass(ULocomotionFeatureCannonFly::StaticClass()));
		SideRotation = FRotator::ZeroRotator;
		FwdRotation = FRotator::ZeroRotator;
		ActorRotation = OwningActor.GetActorRotation();
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		const FRotator DeltaRotation = (OwningActor.ActorRotation - ActorRotation).Normalized;
		ActorRotation = OwningActor.GetActorRotation();

		const FVector LocalVelocity = GetActorLocalVelocity(OwningActor);
		FwdRotation.Pitch = FMath::FInterpTo(FwdRotation.Pitch, LocalVelocity.Z / 70.f, DeltaTime, 1.f);
		if (DeltaTime != 0)
		{
			SideRotation.Yaw = FMath::FInterpTo(SideRotation.Yaw, -DeltaRotation.Yaw * 1.2f / DeltaTime, DeltaTime, 1.f);
			BlendspaceValues.X = FMath::Clamp(DeltaRotation.Yaw * .01f / DeltaTime, -1.f, 1.f);
		}
			

    }


    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureControllingUFO;
import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableUFO;
import Peanuts.Animation.AnimationStatics;

class UPlayRoomControllableUFOAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureControllingUFO LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FVector2D BlendspaceValues;

	AControllableUFO ControllableUFO;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureControllingUFO>(GetFeatureAsClass(ULocomotionFeatureControllingUFO::StaticClass()));
		ControllableUFO = Cast<AControllableUFO>(OwningActor.GetAttachParentActor());

    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		const FVector LocalVelocity = GetActorLocalVelocity(ControllableUFO);
		BlendspaceValues.X = LocalVelocity.Y / 3000.f;
		BlendspaceValues.Y = LocalVelocity.X / 3000.f;		

    }

}
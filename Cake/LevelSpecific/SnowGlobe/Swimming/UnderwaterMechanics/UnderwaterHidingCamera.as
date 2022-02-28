import Vino.Camera.Components.CameraSpringArmComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.UnderwaterHidingComponent;

class AUnderwaterHidingCamera : AHazeCameraActor
{
   	UPROPERTY(DefaultComponent, ShowOnActor)
	UCameraUnderwaterHidingComponent UnderwaterHiding;

   	UPROPERTY(DefaultComponent, Attach = UnderwaterHiding, ShowOnActor)
	UCameraSpringArmComponent SpringArm;

	UPROPERTY(DefaultComponent, Attach = SpringArm, ShowOnActor)
	UHazeCameraComponent Camera;
}

class UCameraUnderwaterHidingComponent : UHazeCameraParentComponent
{
   	UFUNCTION(BlueprintOverride)
	void OnCameraActivated(UHazeCameraUserComponent User, EHazeCameraState PreviousState)
	{
		UUnderwaterHidingComponent HidingComp = UUnderwaterHidingComponent::Get(User.Owner);
		SetWorldLocation(HidingComp.HidingLocation + FVector(0, 0, HidingComp.ActiveHidingPlace.Radius + 1000.f));
	}	
}
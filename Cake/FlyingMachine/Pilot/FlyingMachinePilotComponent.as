import Peanuts.Spline.SplineComponent;
import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.FlyingMachineOrientation;

class UFlyingMachinePilotComponent : UActorComponent
{
	UPROPERTY(BlueprintReadOnly, Transient)
	AFlyingMachine CurrentMachine;
	UHazeCapabilitySheet Sheet;

	UHazeCameraComponent TargetCamera;

	UHazeCameraComponent PilotCamera;

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		//CurrentMachine = nullptr;
		//Sheet = nullptr;
	}
}
import Cake.FlyingMachine.FlyingMachine;

class UFlyingMachineGunnerCrosshairWidget : UHazeUserWidget
{
	UPROPERTY()
	AFlyingMachine Machine;

	UPROPERTY()
	FVector AimWorldLocation;

	UPROPERTY()
	bool IsAimClamped = false;

	UPROPERTY()
	float ReloadProgress = 1.f;

	UFUNCTION(BlueprintEvent)
	void BP_PlayFireAnimation() {}
}
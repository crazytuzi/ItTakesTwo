
class UNailWeaponCrosshairWidget : UHazeUserWidget
{
	UPROPERTY(Category = "NailWidget | Runtime", Transient, NotEditable)
	FVector AimWorldLocation_Desired = FVector::ZeroVector;

	UPROPERTY(Category = "NailWidget | Runtime", Transient, NotEditable)
	FHazeAcceleratedVector AimWorldLocation_Current;

	UPROPERTY(Category = "NailWidget | Runtime", Transient, NotEditable)
	USceneComponent AutoAimComponent = nullptr;
}
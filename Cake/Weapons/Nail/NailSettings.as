import Cake.Weapons.Nail.NailWeaponActor;

UCLASS(meta = (ComposeSettingsOnto = "UNailWeaponSettings"))
class UNailWeaponSettings : UHazeComposableSettings
{
	UPROPERTY(Category = "Spawning")
	TSubclassOf<ANailWeaponActor> NailWeaponActorClass;

	UPROPERTY(Category = "Spawning")
	UStaticMesh NailHolserStaticMesh;

	UPROPERTY(Category = "Spawning")
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY(Category = "Spawning")
	UHazeLocomotionStateMachineAsset IdleLocomotionAsset;
//
//	UPROPERTY(Category = "Throw")
//	float ThrowTraceLength = 10000.f;
//
//	/* How fast the camera settings will be blended in*/
//	UPROPERTY(BlueprintReadOnly, Category = "Camera")
//	float CameraSettingsBlendInTime = 0.5f;
//
//	UPROPERTY(Category = "Animation")
//	UHazeLocomotionAssetBase StrafeAsset;
};

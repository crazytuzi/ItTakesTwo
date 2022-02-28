import Cake.Weapons.Match.MatchWeaponActor;

UCLASS(meta = (ComposeSettingsOnto = "UMatchWeaponComposeableSettings"))
class UMatchWeaponComposeableSettings: UHazeComposableSettings
{
	UPROPERTY()
	int NumMatchesToRecycle = 10;

	UPROPERTY()
	TSubclassOf<AMatchProjectileActor > MatchProjectileActorClass;

	UPROPERTY()
	TSubclassOf<AMatchWeaponActor > MatchWeaponActorClass;

	UPROPERTY()
	UStaticMesh QuiverMesh;

	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;

	UPROPERTY()
	UHazeLocomotionAssetBase LocomotionAsset_NotAiming;

	UPROPERTY()
	UHazeLocomotionAssetBase LocomotionAsset_Aiming;
}
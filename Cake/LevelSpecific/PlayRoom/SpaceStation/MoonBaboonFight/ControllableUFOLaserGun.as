class AControllableUfoLaserGun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase LaserGunSkelMesh;

	UPROPERTY(DefaultComponent, Attach = LaserGunSkelMesh, AttachSocket = Coil)
	UArrowComponent TurretNozzle;
}
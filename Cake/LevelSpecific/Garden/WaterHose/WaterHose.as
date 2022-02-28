import Cake.LevelSpecific.Garden.WaterHose.WaterHoseProjectile;
import Peanuts.Outlines.Outlines;

UCLASS(Abstract)
class AWaterHose : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase RootComp;
	default RootComp.AddTag(ComponentTags::HideOnCameraOverlap);
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent Muzzle;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent WaterSpawnEffect;


	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Muzzle.AttachToComponent(RootComp, n"Muzzle");
		WaterSpawnEffect.AttachToComponent(RootComp, n"Muzzle");
    }


	USkeletalMeshComponent GetGunMesh() const property
	{
		return RootComp;
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveMeshFromPlayerOutline(GunMesh, this);
	}
}
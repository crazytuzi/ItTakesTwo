import Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingTargetComponent;

class ABasementBossShootingTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UParentBlobShootingTargetComponent TargetComp;

	UPROPERTY()
	FParentBlobShootingTargetImpactSignature OnImpact;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TargetComp.OnProjectileImpact.AddUFunction(this, n"Impact");
	}

	UFUNCTION(NotBlueprintCallable)
	void Impact(FParentBlobShootingTargetComponentImpactDelegateData Data)
	{
		OnImpact.Broadcast(Data);
	}
}
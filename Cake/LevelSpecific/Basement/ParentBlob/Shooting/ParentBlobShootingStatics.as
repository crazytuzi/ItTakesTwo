import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;
import Cake.LevelSpecific.Basement.ParentBlob.Shooting.ParentBlobShootingComponent;


delegate void FParentBlobButtonProjetileShootDelegate(FParentBlobShootingDelegateData Data);
delegate void FParentBlobButtonProjetileImpactDelegate(FParentBlobShootingImpactDelegateData Data);
delegate void FParentBlobButtonProjetileTargetImpactDelegate(FParentBlobShootingTargetComponentImpactDelegateData Data);


UFUNCTION(Category = "ParentBlob")
void BindOnParentBlobProjectileShoot(FParentBlobButtonProjetileShootDelegate Delegate)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

    auto ShootingComponent = UParentBlobShootingComponent::Get(ParentBlob);
	ShootingComponent.OnShootProjectile.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}

UFUNCTION(Category = "ParentBlob")
void BindOnParentBlobProjectileImpact(FParentBlobButtonProjetileImpactDelegate Delegate)
{
	AParentBlob ParentBlob = GetActiveParentBlobActor();
	if (ParentBlob == nullptr)
		return;

    auto ShootingComponent = UParentBlobShootingComponent::Get(ParentBlob);
	ShootingComponent.OnProjectileImpact.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}

UFUNCTION(Category = "ParentBlob")
void BindOnParentBlobProjectileTargetComponentImpact(AHazeActor Actor, FParentBlobButtonProjetileTargetImpactDelegate Delegate, FName OptionalComponentName = NAME_None)
{
    auto TargetComponent = UParentBlobShootingTargetComponent::Get(Actor, OptionalComponentName);
	if(TargetComponent == nullptr)
		return;

	TargetComponent.OnProjectileImpact.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}
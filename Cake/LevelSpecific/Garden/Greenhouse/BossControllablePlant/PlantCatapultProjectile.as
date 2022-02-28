import Vino.PlayerHealth.PlayerHealthComponent;

event void FOnPlantCatapultProjectileHit(FHitResult CollisionHit);

UCLASS(Abstract)
class APlantCatapultProjectile : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	bool bLaunched;	

	UPROPERTY()
	UNiagaraSystem NiagaraFX;

	UPROPERTY()
	FOnPlantCatapultProjectileHit OnPlantCatapultProjectileHit;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		//sAddCapability(n"BossControllablePlantButtonMashCapability");
	}

	void LaunchProjectile()
	{
		//FlyTrail.Activate();
		bLaunched = true;		
	}

	UFUNCTION()
	void ActivateProjectile()
	{
		RootComp.SetHiddenInGame(false, true);
		//FlyTrail.Deactivate();
		//ProjectileTimer = 0.0f;
		//bActivated = false;		
	}

	UFUNCTION()
	void DeactivateProjectile()
	{
		RootComp.SetHiddenInGame(true, true);
		//FlyTrail.Deactivate();
	}


}
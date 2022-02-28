class ACastleEnemyProjectile : AHazeActor
{
    UPROPERTY()
    AHazePlayerCharacter Target;
    UPROPERTY()
    FVector TargetLocation;
    UPROPERTY()
    FVector FireDirection;
    UPROPERTY()
    float ProjectileDamageRoll = 0.f;

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent CollisionBox;
	default CollisionBox.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent, NotVisible)
	UHazeAkComponent ProjectileHazeAkComp;
	default ProjectileHazeAkComp.SetStopWhenOwnerDestroyed(false);
	
    void ProjectileFired()
    {
        BP_ProjectileFired();
    }

    UFUNCTION(BlueprintEvent, Meta=(DisplayName = "Projectile Fired"))
    void BP_ProjectileFired() {}

	void ProjectileTargeted()
	{
		BP_ProjectileTargeted();
	}

    UFUNCTION(BlueprintEvent, Meta=(DisplayName = "Projectile Targeted"))
    void BP_ProjectileTargeted() {}

	void ProjectileFizzled()
	{
		BP_ProjectileFizzled();
		DestroyActor();
	}

    UFUNCTION(BlueprintEvent, Meta=(DisplayName = "Projectile Fizzled"))
    void BP_ProjectileFizzled() {}
};
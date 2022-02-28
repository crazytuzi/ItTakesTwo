import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAudio.CastleEnemyAudioBaseCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyArrowProjectile;

class UCastleEnemyRangedAudioCapability : UCastleEnemyAudioBaseCapability	
{
	UPROPERTY(Category = "Projectile")
	UAkAudioEvent ProjectileFiredEvent;

	UPROPERTY(Category = "Passby")
	UAkAudioEvent ProjectilePassbyEvent;

	UPROPERTY(Category = "Passby")
	bool bSetDopplerRTPC = false;

	UPROPERTY(Category = "Passby")
	float ProjectilePassbyApexTime = 0.f;

	UPROPERTY(Category = "Passby")
	float ProjectilePassbyCooldown = 1.f;

	UPROPERTY(Category = "Passby")
	float ProjectilePassbyVelocityAngle = 0.5f;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		UObject RawObject;
		if(ConsumeAttribute(n"AudioProjectileFired", RawObject))
		{
			ACastleEnemyArrowProjectile ArrowProjectile = Cast<ACastleEnemyArrowProjectile>(RawObject);
			if(ArrowProjectile != nullptr)
			{
				EnemyHazeAkComp.HazePostEvent(ProjectileFiredEvent);	

				if(ProjectilePassbyApexTime > 0)
				{
					ArrowProjectile.ProjectileDoppler.PlayPassbySound(ProjectilePassbyEvent, ProjectilePassbyApexTime, ProjectilePassbyCooldown, VelocityAngle = ProjectilePassbyVelocityAngle);
					ArrowProjectile.ProjectileDoppler.SetObjectDopplerValues(bSetDopplerRTPC, Observer = EHazeDopplerObserverType::ClosestPlayer);
				}	
			}
		}
	}
}
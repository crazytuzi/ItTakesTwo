import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyAudio.CastleEnemyRangedAudioCapability;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyProjectile;
import Peanuts.Audio.HazeAudioEffects.DopplerEffect;

class UCastleEnemyTeleporterAudioCapability : UCastleEnemyAudioBaseCapability
{
	UPROPERTY(Category = "Projectile")
	UAkAudioEvent ChargingMagicBallEvent;

	UPROPERTY(Category = "Projectile")
	UAkAudioEvent ShootMagicBallEvent;

	UPROPERTY(Category = "Projectile")
	UAkAudioEvent MagicBallLoopingEvent;

	UPROPERTY(Category = "Teleport")
	UAkAudioEvent TeleportStartEvent;

	UPROPERTY(Category = "Teleport")
	UAkAudioEvent TeleportStopEvent;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime) override
	{
		Super::TickActive(DeltaTime);

		if(ConsumeAction(n"AudioStartedTeleport") == EActionStateStatus::Active)
		{
			bBlockMovementAudio = true;
			EnemyHazeAkComp.HazePostEvent(TeleportStartEvent);
		}

		if(ConsumeAction(n"AudioStoppedTeleport") == EActionStateStatus::Active)
		{
			bBlockMovementAudio = false;
			EnemyHazeAkComp.HazePostEvent(TeleportStopEvent);
		}

		if(ConsumeAction(n"AudioStartedChargingProjectile") == EActionStateStatus::Active)
			EnemyHazeAkComp.HazePostEvent(ChargingMagicBallEvent);

		if(ConsumeAction(n"AudioProjectileFired") == EActionStateStatus::Active)
			EnemyHazeAkComp.HazePostEvent(ShootMagicBallEvent);
	}
}
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemyProjectile.CastleEnemyProjectile;

class ACastleArrowShooter : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;

	UPROPERTY()
	TSubclassOf<ACastleEnemyProjectile> ProjectileType;

	UPROPERTY(Meta = (MakeEditWidget))
	FTransform SpawnTransform;

	UPROPERTY()
	EHazePlayer ControllingPlayer = EHazePlayer::May;

	UPROPERTY()
	int MinPlayerDamageDealt = 50;

	UPROPERTY()
	int MaxPlayerDamageDealt = 50;

	UPROPERTY()
	float Interval = 1.f;

	UPROPERTY()
	float Offset = 0.f;

	private float Timer = 0.f;
	private int SpawnProjectileCounter = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetPlayer(ControllingPlayer));
		Timer = Offset;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Timer -= DeltaTime;
		if (Timer <= 0.f)
		{
			if (HasControl())
				NetFire();
			Timer = Interval;
		}
	}

	UFUNCTION(NetFunction)
	void NetFire()
	{
		ACastleEnemyProjectile Projectile = Cast<ACastleEnemyProjectile>(SpawnActor(
			ProjectileType.Get(),
			ActorTransform.TransformPosition(SpawnTransform.Location),
			ActorTransform.TransformRotation(SpawnTransform.Rotation).Rotator()
			));
		if (Projectile == nullptr)
			return;

		Projectile.MakeNetworked(this, SpawnProjectileCounter++);
		Projectile.Target = nullptr;
		Projectile.TargetLocation = Projectile.ActorLocation + Projectile.ActorForwardVector * 1000.f;
		Projectile.FireDirection = Projectile.ActorForwardVector;
		Projectile.ProjectileDamageRoll = FMath::RandRange(MinPlayerDamageDealt, MaxPlayerDamageDealt);
		Projectile.ProjectileTargeted();
		Projectile.ProjectileFired();
	}
};
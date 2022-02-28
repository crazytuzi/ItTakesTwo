import Cake.LevelSpecific.SnowGlobe.SnowballFight.SnowballFightProjectile;
import Cake.LevelSpecific.SnowGlobe.Snowfolk.SnowFolkSplineFollower;
import Peanuts.Aiming.AutoAimTarget;

class USnowfolkSnowballFightComponent : UActorComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	UPROPERTY()
	TSubclassOf<ASnowballFightProjectile> ProjectileClass;

	UPROPERTY()
	UAnimSequence ThrowAnimation;
	UPROPERTY()
	UAnimSequence PickupAnimation;
	UPROPERTY()
	UAnimSequence AggroAnimation;
	UPROPERTY()
	UAnimSequence LaughingAnimation;

	UPROPERTY()
	float ThrowPower = 1.0f;
	UPROPERTY()
	float MaxRange = 3000.f;
	UPROPERTY()
	float Cooldown = 4.f;
	
	ASnowfolkSplineFollower Snowfolk;
	AActor AggroTarget;
	int Attemts = 0;
	int MaxAttemts = 3;
	bool bRetaliationSuccess;
	FVector AimTargetRelativeLocation;
	USceneComponent AimTargetComponent;
	USnowballFightResponseComponent ResponseComponent;

	private int NumSpawnedProjectiles;
	private float CooldownEndTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Snowfolk = Cast<ASnowfolkSplineFollower>(Owner);
	}

	UFUNCTION()
	bool HasValidTargetInRange(float Range)
	{
		if (!IsTargetActorInRange(AggroTarget, Range))
			return false;

		auto ResponseComp = USnowballFightResponseComponent::Get(AggroTarget);
		if (ResponseComp == nullptr)
			return false;
			
		auto TargetComp = UAutoAimTargetComponent::Get(AggroTarget);
		if (TargetComp == nullptr)
			return false;

		AimTargetComponent = TargetComp;
		AimTargetRelativeLocation = AggroTarget.ActorTransform.InverseTransformPosition(TargetComp.WorldLocation);

		// Set lookat
		Snowfolk.bEnableLookAt = true;
		Snowfolk.LookAtLocation = AggroTarget.ActorLocation;

		// Line of sight
		FHazeTraceParams Trace;
		Trace.From = Snowfolk.Collision.ShapeCenter;
		Trace.To = TargetComp.WorldLocation;
		Trace.IgnoreActor(Owner);
		Trace.SetToLineTrace();
		Trace.InitWithTraceChannel(ETraceTypeQuery::Visibility);

		FHazeHitResult Hit;
		if (Trace.Trace(Hit))
		{
			if (Hit.Actor == AggroTarget)
				return true;
		}

		return false;
	}

	bool IsTargetActorInRange(AActor TargetActor, float Range)
	{
		if (TargetActor == nullptr)
			return false;

		float DistanceToActorSquared = Owner.ActorLocation.DistSquared(TargetActor.ActorLocation);

		if (DistanceToActorSquared < FMath::Square(Range))
		{
			FVector Direction = (TargetActor.ActorLocation - Owner.ActorLocation).GetSafeNormal();

			if (Owner.ActorForwardVector.DotProduct(Direction) > 0.4f)
				return true;
		}

		return false;
	}

	UFUNCTION()
	bool LaunchSnowball(FSnowballFightTargetData TargetData)
	{
		if (!ProjectileClass.IsValid())
			return false;

		auto Projectile = Cast<ASnowballFightProjectile>(SpawnActor(ProjectileClass.Get(), Level = Owner.Level));

		if (Projectile == nullptr)
			return false;

		Projectile.MakeNetworked(this, NumSpawnedProjectiles++);
		Projectile.Deactivate(true);

		// Make projectile fire & forget; we don't want the pooling functionality
		Projectile.bAutoDestroy = true;

		FName AttachSocketName = n"RightAttach";
		Projectile.Activate(Snowfolk, AttachSocketName);

		FVector SocketLocation = Snowfolk.SkeletalMeshComponent.GetSocketLocation(AttachSocketName);
		Projectile.Launch(MaxRange, SocketLocation, TargetData);
		Projectile.OnSnowballHit.AddUFunction(this, n"HandleSnowballHit");

		// Apply cooldown
		CooldownEndTime = Time::GameTimeSeconds + Cooldown;

		return true;
	}

	UFUNCTION(BlueprintPure)
	bool HasCooldown()
	{
		return CooldownEndTime > Time::GameTimeSeconds;
	}

	UFUNCTION()
	private void HandleSnowballHit(FHitResult Hit)
	{
		if (Hit.Actor != AggroTarget)
			return;

		AggroTarget = nullptr;
		bRetaliationSuccess = true;
	}
};
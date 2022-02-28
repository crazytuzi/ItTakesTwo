import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunProjectile;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunCrosshairWidget;
import Vino.Camera.Components.BallSocketCameraComponent;
import Vino.Camera.Components.CameraMatchDirectionComponent;

import void PlungerGunPlayerEnter(AHazePlayerCharacter Player, APlungerGun Gun) from 'Cake.LevelSpecific.Tree.PlungerGun.PlungerGunPlayerComponent';

class APlungerGun : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent YawRoot;

	UPROPERTY(DefaultComponent, Attach = YawRoot)
	USceneComponent PitchRoot;

	UPROPERTY(DefaultComponent, Attach = PitchRoot)
	USceneComponent RecoilRoot;

	UPROPERTY(DefaultComponent, Attach = RecoilRoot)
	USceneComponent SeatRoot;

	UPROPERTY(DefaultComponent, Attach = RecoilRoot)
	USceneComponent Muzzle;

	UPROPERTY(DefaultComponent, Attach = Muzzle)
	USceneComponent ChargeRoot;

	UPROPERTY(DefaultComponent)
	UCameraMatchDirectionComponent MatchDirection;

	UPROPERTY(DefaultComponent, Attach = MatchDirection)
	UBallSocketCameraComponent BallSocket;
	default BallSocket.bAllowCameraRelativeOffset = true;

	UPROPERTY(DefaultComponent, Attach = BallSocket)
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = SeatRoot)
	UInteractionComponent Interaction;

	UPROPERTY(DefaultComponent)
	USceneComponent JumpOffPoint;

	UPROPERTY(EditDefaultsOnly, Category = "Capability")
	UHazeCapabilitySheet PlayerSheet;

	UPROPERTY(EditDefaultsOnly, Category = "Capability")
	TSubclassOf<UPlungerGunCrosshairWidget> CrosshairWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	TSubclassOf<APlungerGunProjectile> ProjectileClass;

	TArray<APlungerGunProjectile> ProjectilePool;

	FHazeConstrainedPhysicsValue RecoilValue;
	default RecoilValue.bHasUpperBound = false;
	default RecoilValue.LowerBounciness = 0.6f;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter CurrentPlayer;

	float ReloadTimer = 0.f;
	float CurrentCharge = 0.f;
	const float ShakeSpeed = 50.f;
	const float ShakeIntensity = 4.f;
	const float RecoilImpulse = 500.f;

	float RecoilVelocity = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnActivated.AddUFunction(this, n"HandleInteraction");

		// Spawn projectiles in the pool
		for(int i=0; i<PlungerGun::ProjectilePoolSize; ++i)
		{
			auto Projectile = Cast<APlungerGunProjectile>(SpawnActor(ProjectileClass, Level = GetLevel()));
			Projectile.MakeNetworked(this, i);
			Projectile.DeactivateProjectile();

			ProjectilePool.Add(Projectile);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (ReloadTimer > 0.f)
		{
			ReloadTimer -= DeltaTime;

			float RetractAlpha = (ReloadTimer / PlungerGun::ShootCooldown);
			RetractAlpha = FMath::Pow(RetractAlpha, 2.f);
			ChargeRoot.RelativeLocation = -FVector::ForwardVector * RetractAlpha * 200.f;
			ChargeRoot.RelativeScale3D = FVector(1.f, 1.f - RetractAlpha, 1.f - RetractAlpha);

			if (ReloadTimer <= 0.f)
			{
				ChargeRoot.RelativeLocation = FVector::ZeroVector;
				ChargeRoot.RelativeScale3D = FVector::OneVector;
			}
		}

		FVector RecoilLocation;
		if (CurrentCharge > 0.f)
		{
			float SampleTime = Time::GameTimeSeconds * ShakeSpeed;
			float ShakeX = FMath::PerlinNoise2D(FVector2D(SampleTime, 0.f));
			float ShakeY = FMath::PerlinNoise2D(FVector2D(0.f, SampleTime));

			RecoilLocation = FVector(0.f, ShakeX, ShakeY) * CurrentCharge * ShakeIntensity;
		}

		RecoilValue.AccelerateTowards(0.f, 2500.f);
		RecoilValue.Update(DeltaTime);
		RecoilLocation.X = -RecoilValue.Value;

		RecoilRoot.RelativeLocation = RecoilLocation;
	}

	UFUNCTION()
	void HandleInteraction(UInteractionComponent Interaction, AHazePlayerCharacter Player)
	{
		PlungerGunPlayerEnter(Player, this);
	}

	void Fire(float Charge)
	{
		APlungerGunProjectile BestProjectile = nullptr;

		// We want to find the best projectile to recycle in the pool...
		for(int i=0; i<ProjectilePool.Num(); ++i)
		{
			auto Projectile = ProjectilePool[i];

			// If the projectile is disabled, then just choose that one!
			if (Projectile.IsActorDisabled())
			{
				BestProjectile = Projectile;
				break;
			}

			// Otherwise (if no projectiles are disabled), choose the one that's closest to _becoming_ disabled
			else
			{
				if (BestProjectile == nullptr || Projectile.StickTimer < BestProjectile.StickTimer)
					BestProjectile = Projectile;
			}
		}

		NetFireInternal(BestProjectile, Muzzle.WorldTransform, Charge);
	}

	UFUNCTION(NetFunction)
	void NetFireInternal(APlungerGunProjectile Projectile, FTransform Origin, float Charge)
	{
		// It might be recycled or in other ways not disabled yet, so do that now!
		if (!Projectile.IsActorDisabled())
			Projectile.DeactivateProjectile();

		Projectile.ActivateProjectile(CurrentPlayer, Origin, Charge);
		BP_OnFire();

		RecoilValue.AddImpulse(RecoilImpulse * Charge);

		CurrentCharge = 0.f;
		ReloadTimer = PlungerGun::ShootCooldown;
	}

	void SetCharge(float ChargePercent)
	{
		ChargeRoot.RelativeLocation = FVector(-ChargePercent * 100.f, 0.f, 0.f);
		CurrentCharge = ChargePercent;

		BP_Charging(ChargePercent);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFire() {}

	UFUNCTION(BlueprintEvent)
	void BP_StartCharging() {}

	UFUNCTION(BlueprintEvent)
	void BP_Charging(float Percentage) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartAiming() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnStopAiming() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnAim(float AimSpeed) {}
}
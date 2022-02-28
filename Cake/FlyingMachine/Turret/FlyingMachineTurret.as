import Cake.FlyingMachine.Turret.FlyingMachineTurretStatics;
import Cake.FlyingMachine.FlyingMachineFlakProjectile;
import Cake.FlyingMachine.FlyingMachineSettings;
import Vino.Camera.Components.CameraSpringArmComponent;

class AFlyingMachineTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSkeletalMeshComponentBase Mesh;
	default Mesh.bUpdateOverlapsOnAnimationFinalize = false;
	default Mesh.bUseAttachParentBound = true;

	UPROPERTY(DefaultComponent, AttachSocket = Turret)
	USceneComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = "CameraRoot")
	UCameraSpringArmComponent CameraArm;

	UPROPERTY(DefaultComponent, Attach = "CameraArm")
	UHazeCameraComponent Camera;

	UPROPERTY(DefaultComponent, Attach = "YawRoot")
	USceneComponent GunnerAttach;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CameraSettings;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset ZoomedCameraSettings;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase GunnerFeature;

	int ProjectileCount = 0;

	UPROPERTY(Category = "Projectile")
	TSubclassOf<AFlyingMachineFlakProjectile> ProjectileClass;

	UPROPERTY(Category = "ForceFeedback")
	UForceFeedbackEffect FireFeedbackEffect;

	UPROPERTY(BlueprintReadOnly, Category="Turret|Aiming")
	float AimYaw;
	UPROPERTY(BlueprintReadOnly, Category="Turret|Aiming")
	float AimPitch;

	FFlyingMachineGunnerSettings Settings;
	bool bShootRightMuzzle = true;

	FVector LastTurretLocation;
	FVector CurrentVelocity;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetControlSide(Game::GetMay());
		LastTurretLocation = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// When in the cutscene, we want to make sure our internal rotations are matching what they are in the cutscene
		if (bIsControlledByCutscene)
		{
			RotateToDirection(TurretForward);
		}

		if (DeltaTime > KINDA_SMALL_NUMBER)
		{
			FVector DeltaMove = ActorLocation - LastTurretLocation;
			CurrentVelocity = DeltaMove / DeltaTime;

			LastTurretLocation = ActorLocation;
		}
	}

	void SetRotations(float Yaw, float Pitch)
	{
		float ClampedPitch = FMath::Clamp(Pitch, Settings.MinPitch, Settings.MaxPitch);
		AimYaw = Yaw;
		AimPitch = Pitch;
	}

	void RotateToDirection(FVector WorldForward)
	{
		float Yaw = 0.f;
		float Pitch = 0.f;

		GetPitchYawDeltas(GetActorForwardVector(), WorldForward, GetActorUpVector(), Yaw, Pitch);
		SetRotations(Yaw, Pitch);
	}

	void RotateTowardsPosition(FVector WorldPosition)
	{
		FVector Diff = WorldPosition - TurretLocation;
		RotateToDirection(Diff.GetSafeNormal());
	}

	FVector GetTurretForward() property
	{
		return TurretTransform.Rotation.ForwardVector;
	}

	FVector GetTurretLocation() property
	{
		return TurretTransform.Location;
	}

	FTransform GetTurretTransform() property
	{
		return Mesh.GetSocketTransform(n"Turret");
	}

	FTransform GetMuzzleExitTransform(bool bRight)
	{
		FName SocketName = bRight ? n"RightMuzzle" : n"LeftMuzzle";
		FTransform MuzzleTransform = Mesh.GetSocketTransform(SocketName);

		return MuzzleTransform;
	}

	void FireAt(FVector WorldTarget, AFlyingMachineFlakProjectile Projectile)
	{
		FVector Direction = WorldTarget - TurretLocation;
		Direction.Normalize();

		Fire(Direction, Projectile);
	}

	void Fire(FVector Direction, AFlyingMachineFlakProjectile Projectile)
	{
		FTransform Origin = GetMuzzleExitTransform(bShootRightMuzzle);

		// Initialize
		Projectile.IgnoredOwner = RootComponent.AttachParent.Owner;
		Projectile.InitializeProjectile(Origin.Location, Direction, HasControl(), CurrentVelocity);

		BP_OnFire(bShootRightMuzzle, Origin, Direction);
		bShootRightMuzzle = !bShootRightMuzzle;
	}

	UFUNCTION(NotBlueprintCallable)
	void HandleProjectileHit(AHazeActor HitActor, FVector RelativeHitLocation)
	{
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetExplodeProjectile(AHazeActor HitActor, FVector RelativeHitLocation)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnFire(bool bRightMuzzle, FTransform Origin, FVector Direction)
	{
	}
}
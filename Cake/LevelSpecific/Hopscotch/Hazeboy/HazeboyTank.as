import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyCamera;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyReticle;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyProjectile;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyCollisionSolver;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyExplosion;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyHealthWidget;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTitleWidget;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Movement.PlaneLock.PlaneLockStatics;
import Peanuts.Movement.DefaultCharacterRemoteCollisionSolver;

import void HazeboyRegisterResetCallback(UObject Object, FName Function) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import void HazeboyRegisterVisibleActor(AActor Actor, int ExclusivePlayer) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';
import void HazeboyTankDie(AHazeboyTank Tank) from 'Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager';

class AHazeboyTank : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RecoilRoot;

	UPROPERTY(DefaultComponent, Attach = RecoilRoot)
	USceneComponent TurretRoot;

	UPROPERTY(DefaultComponent, Attach = TurretRoot)
	USceneComponent Muzzle;

	UPROPERTY(DefaultComponent, Attach)
	USpringArmComponent SpringArm;
	default SpringArm.TargetArmLength = 760.f;

	UPROPERTY(DefaultComponent, Attach = SpringArm)
	UHazeboyCameraAnimComponent CameraAnim;

	UPROPERTY(DefaultComponent, Attach = CameraAnim)
	UHazeboyCamera Camera;
	default Camera.FOVAngle = 60.f;

	UPROPERTY(DefaultComponent)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComp;
	default CrumbComp.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;
	default CrumbComp.UpdateSettings.OptimalCount = 2;

	UPROPERTY(EditDefaultsOnly, Category = "Visuals")
	TArray<UMaterialInterface> PlayerIndexMaterials;

	UPROPERTY(EditDefaultsOnly, Category = "Visuals")
	UMaterialParameterCollection ParameterCollection;

	UPROPERTY(EditInstanceOnly, Category = "Hazeboy")
	int PlayerIndex = 0;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	TSubclassOf<AHazeboyReticle> ReticleType;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	TSubclassOf<AHazeboyProjectile> ProjectileType;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	UForceFeedbackEffect ShootForceFeedback;

	UPROPERTY(EditDefaultsOnly, Category = "Gameplay")
	UForceFeedbackEffect HurtForceFeedback;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter OwningPlayer;

	AHazeboyReticle Reticle;

	FTransform RespawnTransform;

	// Hurt stuff
	int Health = 3;
	float HurtTimer = 0.f;
	float ImmuneTimer = 0.f;

	// Widget stuff
	UPROPERTY(EditDefaultsOnly, Category = "Widget")
	TSubclassOf<UUserWidget> HealthWidgetClass;

	UPROPERTY(EditDefaultsOnly, Category = "Widget")
	TSubclassOf<AHazeboyTitleWidget> TitleWidgetClass;

	// Recoil stuff
	FVector Recoil;
	FVector RecoilVelocity;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		// Apply player material
		if (PlayerIndexMaterials.Num() == 0)
			return;

		UMaterialInterface Material = PlayerIndexMaterials[PlayerIndex];
		TArray<UPrimitiveComponent> Primitives;
		GetComponentsByClass(Primitives);

		for(auto Primitive : Primitives)
		{
			if (Cast<UStaticMeshComponent>(Primitive) == nullptr)
				continue;

			int NumMaterials = Primitive.GetNumMaterials();
			for(int i=0; i<NumMaterials; ++i)
			{
				Primitive.SetMaterial(i, Material);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Debug::RegisterActorLogger(this);
		HazeboyRegisterResetCallback(this, n"Respawn");

		// Create reticle actor
		Reticle = Cast<AHazeboyReticle>(SpawnActor(ReticleType, Level = GetLevel()));
		HazeboyRegisterVisibleActor(Reticle, PlayerIndex);

		// Movement stuff
		MoveComp.Setup(BoxCollision);
		MoveComp.UseCollisionSolver(UHazeboyTankSolver::StaticClass(), UHazeboyTankSolver::StaticClass());

		FPlaneConstraintSettings PlaneLockSettings;
		PlaneLockSettings.Origin = ActorLocation;
		PlaneLockSettings.Normal = FVector::UpVector;
		StartPlaneLockMovement(this, PlaneLockSettings);

		// Capabilities!
		AddCapability(n"HazeboyTankAimCapability");
		AddCapability(n"HazeboyTankShootCapability");
		AddCapability(n"HazeboyTankDamageCapability");
		AddCapability(n"HazeboyTankMovementCapability");
		AddCapability(n"HazeboyTankRecoilCapability");
		AddCapability(n"HazeboyTankImmuneCapability");
		AddCapability(n"HazeboyTankHealthCapability");
		AddCapability(n"HazeboyTankTitleCapability");

		RespawnTransform = ActorTransform;
	}

	FVector GetAimForward() property
	{
		return SpringArm.ForwardVector;
	}

	FVector GetAimRight() property
	{
		return SpringArm.RightVector;
	}

	FVector TransformInputRelativeToWorld(FVector RelativeInput)
	{
		return AimForward * RelativeInput.X + AimRight * RelativeInput.Y;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	}

	FVector GetMuzzleLocation() property
	{
		return Muzzle.WorldLocation;
	}

	void AddTorqueInWorldDir(FVector InForce)
	{
		FVector Force = InForce;

		// Transform into local space
		Force = Root.WorldTransform.InverseTransformVector(Force);

		// Then get the local rotational axis
		Force = -Force.CrossProduct(FVector::UpVector);
		Force.Normalize();

		AddRelativeTorque(Force * InForce.Size());
	}

	void AddRelativeTorque(FVector InTorque)
	{
		FVector Torque = InTorque;

		// We don't want diagonal recoil, so just take the biggest axis
		if (FMath::Abs(Torque.X) > FMath::Abs(Torque.Y))
			Torque.Y = 0.f;
		else
			Torque.X = 0.f;

		// The tank is longer that it is wide, so scale it a bit along the long-side
		Torque.Y *= 0.7f;

		RecoilVelocity += Torque;
		Recoil += RecoilVelocity * 0.005f;
	}

	UFUNCTION(NetFunction)
	void NetFire(FVector Origin, FVector TargetLocation)
	{
		if (OwningPlayer == nullptr)
			return;

		OwningPlayer.PlayForceFeedback(ShootForceFeedback, false, true, n"HazeboyShoot");

		auto Projectile = Cast<AHazeboyProjectile>(SpawnActor(ProjectileType));
		Projectile.InitProjectile(OwningPlayer, Origin, TargetLocation);

		BP_OnFire();

		// Calculate recoil
		FVector ShootDir = (TargetLocation - Origin);
		ShootDir = ShootDir.ConstrainToPlane(FVector::UpVector);
		ShootDir.Normalize();

		AddTorqueInWorldDir(-ShootDir * 3.f);
	}

	void TakeDamage(FVector Origin)
	{
		Health = FMath::Max(Health - 1, 0);
		HurtTimer = Hazeboy::HurtDuration;
		ImmuneTimer = Hazeboy::ImmuneDuration;

		if (OwningPlayer != nullptr)
			OwningPlayer.PlayForceFeedback(HurtForceFeedback, false, true, n"HazeboyShoot");

		// Add recoil from the explosion
		FVector RecoilDir = ActorLocation - Origin;
		RecoilDir.Normalize();
		AddTorqueInWorldDir(RecoilDir * 4.f);

		if (!IsAlive())
			Kill();
		else
			BP_OnTakeDamage();
	}

	void Kill()
	{
		BP_OnDie();
		HazeboyTankDie(this);

		UpdateOcclusionParams();
	}

	bool IsAlive()
	{
		return Health > 0;
	}

	UFUNCTION()
	void Respawn()
	{
		CleanupCurrentMovementTrail();
		TriggerMovementTransition(this, n"Respawn");

		SetActorTransform(RespawnTransform);
		SpringArm.RelativeRotation = FRotator();
		TurretRoot.RelativeRotation = FRotator();

		HurtTimer = 0.f;
		ImmuneTimer = 0.f;
		Recoil = RecoilVelocity = 0;

		Health = 3;

		BP_OnReset();

		CameraAnim.PlayAnimation();
		UpdateOcclusionParams();
	}

	void UpdateOcclusionParams()
	{
		bool bFirstTank = PlayerIndex == 0;

		if (!IsAlive())
		{
			Material::SetVectorParameterValue(ParameterCollection, bFirstTank ? n"Tank0Pos" : n"Tank1Pos", FLinearColor(BIG_NUMBER, 0.f, 0.f, 0.f));
		}
		else
		{
			FVector Loc = RecoilRoot.WorldLocation;
			FVector Forw = RecoilRoot.ForwardVector;
			FVector Right = RecoilRoot.RightVector;
			Material::SetVectorParameterValue(ParameterCollection, bFirstTank ? n"Tank0Pos" : n"Tank1Pos", FLinearColor(Loc.X, Loc.Y, Loc.Z, 0.f));
			Material::SetVectorParameterValue(ParameterCollection, bFirstTank ? n"Tank0Forw" : n"Tank1Forw", FLinearColor(Forw.X, Forw.Y, Forw.Z, 0.f));
			Material::SetVectorParameterValue(ParameterCollection, bFirstTank ? n"Tank0Right" : n"Tank1Right", FLinearColor(Right.X, Right.Y, Right.Z, 0.f));
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_BeginMovement() {}

	UFUNCTION(BlueprintEvent)
	void BP_EndMovement() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnReset() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnStartCharging() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnCharge(float ChargePercent) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnFire() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnTakeDamage() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDie() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnMoveForward(float Speed) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnTurn(float TurnSpeed) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnAim(float AimSpeed) {}
}
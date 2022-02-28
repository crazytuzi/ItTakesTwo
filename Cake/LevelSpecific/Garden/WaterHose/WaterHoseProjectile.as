
event void FOnWaterHoseProjectileImpact(AWaterHoseProjectile Projectile, FHitResult Impact);
//delegate void FOnWaterDecalDeactivated(AWaterHoseProjectileImpactDecal Decal);


UCLASS(Abstract)
class AWaterHoseProjectile : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = false;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");
	default Mesh.SetCastShadow(false);

	UPROPERTY(Category = "Effect")
	float ImpactNoRotationAngle = 45.f;

	UPROPERTY(Category = "Effect")
	UNiagaraSystem ImpactEffect;

	UPROPERTY(Category = "Effect")
	UNiagaraSystem ImpactEffect_Goop;

	UPROPERTY(Category = "Effect")
	UNiagaraSystem ImpactEffect_SapWall;

	int ArrayIndex = -1;
	FVector LastWorldPosition;
	FOnWaterHoseProjectileImpact OnWaterImpact;
	bool bIsMoving = false;
	FVector Velocity = FVector::ZeroVector;
	FVector PlayerVelocity = FVector::ZeroVector;
	float CurrentLifeTimeLeft = 0;
	FVector WorldUp = FVector::UpVector;
	float GravityMagnitude = 0;
	int ParentIndex = -1;
	FVector OriginalScale;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalScale = Mesh.GetRelativeScale3D();
	}

	void UpdateProjectile(float DeltaTime)
	{
		LastWorldPosition = GetActorLocation();

		CurrentLifeTimeLeft -= DeltaTime;

		// Apply current velocity
		FVector DeltaMove = Velocity * DeltaTime;
		DeltaMove += PlayerVelocity * DeltaTime;

		// Predict gravity
		FVector Acceleration = -WorldUp * GravityMagnitude;
		DeltaMove += Acceleration * 0.5f * FMath::Square(DeltaTime);

		WorldUp = Math::SlerpVectorTowards(WorldUp, FVector::UpVector, DeltaTime * 0.5f);

		// Apply acceleration
		Velocity += Acceleration * DeltaTime;

		AddActorWorldOffset(DeltaMove);
		if(Velocity.SizeSquared() > 1)
			SetActorRotation(FRotator::MakeFromZ(Velocity));

	}

	void GetWaterOverlaps(FHazeTraceParams TraceTemplate, FHitResult WaterImpact, TArray<FOverlapResult>& OutFoundOverlaps)
	{
		if(!WaterImpact.bBlockingHit)
			return;

		FHazeTraceParams Trace = TraceTemplate;

	#if EDITOR
		Trace.DebugDrawTime = bHazeEditorOnlyDebugBool ? 0.f : -1.f;	
	#endif

		Trace.From = WaterImpact.Location;
		Trace.To = Trace.From;

		Trace.Overlap(OutFoundOverlaps);
	}

	// Called everytime the projectile hits something
	UFUNCTION(BlueprintEvent)
    void OnDestroyedFromImpact(FHitResult Impact)
    {

    }
}

UCLASS(Abstract)
class AWaterHoseProjectileImpactDecal : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeDecalComponent DecalComponent;

	// If an impact is inside this radius, no new decal will spawn
	UPROPERTY(EditDefaultsOnly)
	float RetriggerImpactRadius = 250.f;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bActorIsVisualOnly = true;

	UPROPERTY(NotVisible)
	UMaterialInstanceDynamic DynamicMaterial;

	float ActivationGameTime;
	bool bIsShowingEffect = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DynamicMaterial = DecalComponent.CreateDynamicMaterialInstance();
	}

	UFUNCTION(BlueprintEvent)
	void OnStartAndShowEffect(bool bIsRetrigger)
	{
		if(bIsRetrigger)
			DecalComponent.ResetFade();

		ActivationGameTime = Time::GetGameTimeSeconds();
		bIsShowingEffect = true;
		DynamicMaterial.SetScalarParameterValue(n"animationface", FMath::RandRange(0, 2));
	}
	
	UFUNCTION(BlueprintEvent)
	void OnEndAndHideEffect()
	{
		bIsShowingEffect = false;
	}

}
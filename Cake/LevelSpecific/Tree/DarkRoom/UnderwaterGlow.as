/*class AUnderwaterGlow : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent SceneRoot;

	UPROPERTY(DefaultComponent, Attach = SceneRoot)
	UPointLightComponent Pointlight;
	default Pointlight.Mobility = EComponentMobility::Stationary;

	UPROPERTY(DefaultComponent, Attach = SceneRoot)
	USphereComponent CollisionSphere;

	bool bPointLightActivated;

	UPROPERTY()
	FHazeTimeLike PointLightTimeLike;
	default PointLightTimeLike.Curve.ExternalCurve = Asset("/Game/Blueprints/LevelSpecific/Tree/DarkRoom/Curve_UnderwaterLight.Curve_UnderwaterLight");
	default PointLightTimeLike.Duration= 7.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CollisionSphere.OnComponentBeginOverlap.AddUFunction(this, n"DoTheFancyStuff");
		PointLightTimeLike.BindUpdate(this, n"UpdatePointLightTimeLike");
	}


	UFUNCTION()
	void DoTheFancyStuff(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr && !bPointLightActivated)
		{
			bPointLightActivated = true;
			PointLightTimeLike.PlayFromStart();
		}
	}

	UFUNCTION()
	void UpdatePointLightTimeLike(float FloatValue)
	{
		Pointlight.SetIntensity(25000 * FloatValue);
	}


}*/
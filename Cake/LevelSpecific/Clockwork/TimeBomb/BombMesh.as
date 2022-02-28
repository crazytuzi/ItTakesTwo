class ABombMesh : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	//Skeletal mesh later for animations??
	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);

	UPROPERTY(Category = "Naigara Systems")
	UNiagaraSystem Explosion;

	UPROPERTY(Category = "Naigara Systems")
	UNiagaraSystem Puff;

	UPROPERTY(DefaultComponent, Attach = Root)
	UPointLightComponent PointLightComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION()
	void BombDisappears()
	{
		MeshComp.SetHiddenInGame(true);
		System::SetTimer(this, n"DestroyBomb", 2.f, false);
	}

	UFUNCTION()
	void BombExplodes()
	{
		Niagara::SpawnSystemAtLocation(Explosion, ActorLocation, ActorRotation);
		
		MeshComp.SetHiddenInGame(true);
		System::SetTimer(this, n"DestroyBomb", 2.f, false);
	}

	UFUNCTION()
	void ActivateLight(float TimeToTurnOff)
	{
		PointLightComp.SetHiddenInGame(false);
		System::SetTimer(this, n"TurnOffLight", TimeToTurnOff, false);
	}

	UFUNCTION()
	void ActivateLightPermanently()
	{
		PointLightComp.SetHiddenInGame(false);
	}

	UFUNCTION()
	void TurnOffLight()
	{
		PointLightComp.SetHiddenInGame(true);
	}

	UFUNCTION()
	void DestroyBomb()
	{
		DestroyActor();
	}
}
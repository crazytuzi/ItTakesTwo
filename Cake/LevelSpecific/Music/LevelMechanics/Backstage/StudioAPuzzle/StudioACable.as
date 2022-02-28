import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;

event void FStudioACableSignature();

class AStudioACable : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkelMesh;
	default SkelMesh.PhysicsAssetOverride = DefaultPhysAsset;
	default SkelMesh.SetSimulatePhysics(true);

	UPROPERTY()
	UPhysicsAsset DefaultPhysAsset;
	
	UPROPERTY()
	UPhysicsAsset CutPhysAsset;

	UPROPERTY(DefaultComponent, Attach = SkelMesh)
	USceneComponent ImpulseLocation;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	UAutoAimTargetComponent AutoAimComponent;

	UPROPERTY(DefaultComponent, Attach = CymbalImpactComp)
	USphereComponent SphereCollision;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 128.0f;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FX01;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FX02;

	UPROPERTY(DefaultComponent, Attach = SkelMesh, AttachSocket = TopCable7)
	UPhysicsConstraintComponent PhysConstraintComp;

	UPROPERTY(DefaultComponent, Attach = PhysConstraintComp)
	UNiagaraComponent SparkFX;
	default SparkFX.bAutoActivate = false;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CableSparkAudioEvent;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CableHitAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CableHitLastTimeAudioEvent;
	
	UPROPERTY()
	FStudioACableSignature CableSnapped;

	UPROPERTY()
	UCurveFloat WiggleCurve;

	UPROPERTY()
	TArray<AStaticMeshActor> CableMeshArray;

	int ImpactCounter = 0;
	bool bHasBeenSnapped = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalHit");

		TArray<AActor> Actors;
		GetAttachedActors(Actors);
		for (auto Actor : Actors)
		{
			Actor.AttachToComponent(PhysConstraintComp, n"", EAttachmentRule::KeepWorld);
		}
	}

	UFUNCTION(CallInEditor)
	void GetAttachedCables()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (auto Actor : AttachedActors)
		{
			AStaticMeshActor Mesh = Cast<AStaticMeshActor>(Actor);
			if (Mesh != nullptr)
				CableMeshArray.AddUnique(Mesh);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{

	}

	UFUNCTION()
	void ActivateSparks()
	{
		FX01.Activate(true);
		FX02.Activate(true);
		UHazeAkComponent::HazePostEventFireForget(CableSparkAudioEvent, this.GetActorTransform());
	}

	UFUNCTION()
	void CymbalHit(FCymbalHitInfo HitInfo)
	{
		if (bHasBeenSnapped)
			return;

		ImpactCounter++;

		FVector HitDir = HitInfo.DeltaMovement;
		HitDir.Normalize();
		SparkFX.Activate(true);

		if (ImpactCounter >= 3)
		{
			UHazeAkComponent::HazePostEventFireForget(CableHitLastTimeAudioEvent, this.GetActorTransform());

			for(auto Cable : CableMeshArray)
				Cable.SetActorHiddenInGame(true);

			PhysConstraintComp.BreakConstraint();
			SkelMesh.SetPhysicsAsset(CutPhysAsset);
			SkelMesh.SetSimulatePhysics(true);
			SkelMesh.AddImpulseAtLocation(HitDir * 5000000.f, ImpulseLocation.WorldLocation, n"TopCable7");
			SkelMesh.AddImpulseAtLocation(HitDir * 5000000.f, ImpulseLocation.WorldLocation, n"BottomCable13");
			CymbalImpactComp.DestroyComponent(this);

			CableSnapped.Broadcast();	
			bHasBeenSnapped = true;
			return;
		}

		

		SkelMesh.AddImpulseAtLocation(HitDir * 5000000.f, ImpulseLocation.WorldLocation, n"TopCable7");


		if (ImpactCounter == 1)
		{
			UHazeAkComponent::HazePostEventFireForget(CableHitAudioEvent, this.GetActorTransform());
			for(int i = 0; i < 5; i++)
				CableMeshArray[i].SetActorHiddenInGame(true);
		}
			

		if (ImpactCounter == 2)
		{
			UHazeAkComponent::HazePostEventFireForget(CableHitAudioEvent, this.GetActorTransform());
			for(int i = 4; i < 9; i++)
				CableMeshArray[i].SetActorHiddenInGame(true);
		}
			
	}
}
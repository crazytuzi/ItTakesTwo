import Cake.LevelSpecific.Garden.LevelActors.WateringPlantActor;

event void FOnLeafGateFullyOpenedSignature();

class ATriggerableLeafGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftLeafRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftLeafRoot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftLeafRoot3;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightLeafRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightLeafRoot2;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightLeafRoot3;

	UPROPERTY(DefaultComponent, Attach = LeftLeafRoot)
	UStaticMeshComponent LeftLeafMesh;

	UPROPERTY(DefaultComponent, Attach = LeftLeafRoot2)
	UStaticMeshComponent LeftLeafMesh2;

	UPROPERTY(DefaultComponent, Attach = LeftLeafRoot3)
	UStaticMeshComponent LeftLeafMesh3;

	UPROPERTY(DefaultComponent, Attach = RightLeafRoot)
	UStaticMeshComponent RightLeafMesh;

	UPROPERTY(DefaultComponent, Attach = RightLeafRoot2)
	UStaticMeshComponent RightLeafMesh2;

	UPROPERTY(DefaultComponent, Attach = RightLeafRoot3)
	UStaticMeshComponent RightLeafMesh3;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeafVFXSpawnPosition;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollider;
	default BoxCollider.SetCollisionProfileName(n"InvisibleWall");
	default BoxCollider.bGenerateOverlapEvents = false;
	default BoxCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GateOpenAudioEvent;

	UPROPERTY(Category = "Setup")
	UNiagaraSystem LeafGateVFX;

	UPROPERTY(Category = "Setup")
	bool bShouldUnwitherGate = false;

	//Use the BoxComponent on actor to block while inactive (switch from false not using custom brush/BlockingVolume in levelBP).
	UPROPERTY(Category = "Setup")
	bool bUseDefaultBlockingVolume = false;

	UPROPERTY(Category = "Setup", meta = (EditCondition = bShouldUnwitherGate))
	AWateringPlantActor ConnectedWateringPlant;

	UPROPERTY(Category = "Setup")
	FHazeTimeLike OpeningTimelike;

	UPROPERTY(Category = "Settings")
	float OpenAngle = 70.f;

	UPROPERTY(Category = "Settings")
	float ClosedDistanceBetweenLeafs = 7.f;

	UPROPERTY()
	FOnLeafGateFullyOpenedSignature FullyOpenedEvent;

	float DefaultLeftRotation = 0.f;
	float DefaultLeft2Rotation = 0.f;
	float DefaultLeft3Rotation = 0.f;
	float DefaultRightRotation = 0.f;
	float DefaultRight2Rotation = 0.f;
	float DefaultRight3Rotation = 0.f;	

	UMaterialInstanceDynamic MaterialInstance;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(bUseDefaultBlockingVolume)
		{
			BoxCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
			BoxCollider.bGenerateOverlapEvents = true;
		}

		OpeningTimelike.BindUpdate(this, n"OnOpeningUpdate");
		OpeningTimelike.BindFinished(this, n"OnOpeningFinished");

		DefaultLeftRotation = LeftLeafRoot.RelativeRotation.Roll;
		DefaultLeft2Rotation = LeftLeafRoot2.RelativeRotation.Roll;
		DefaultLeft3Rotation = LeftLeafRoot3.RelativeRotation.Roll;
		DefaultRightRotation = RightLeafRoot.RelativeRotation.Roll;
		DefaultRight2Rotation = RightLeafRoot2.RelativeRotation.Roll;
		DefaultRight3Rotation = RightLeafRoot3.RelativeRotation.Roll;

		if(bShouldUnwitherGate)
		{
			if(ConnectedWateringPlant == nullptr)
			{
				bShouldUnwitherGate = false;
				return;
			}

			MaterialInstance = (LeftLeafMesh.CreateDynamicMaterialInstance(0));
			LeftLeafMesh2.SetMaterial(0, MaterialInstance);
			LeftLeafMesh3.SetMaterial(0, MaterialInstance);
			RightLeafMesh.SetMaterial(0, MaterialInstance);
			RightLeafMesh2.SetMaterial(0, MaterialInstance);
			RightLeafMesh3.SetMaterial(0, MaterialInstance);

			ConnectedWateringPlant.OnWateringPlantFinished.AddUFunction(this, n"TriggerOpening");
			SetActorTickEnabled(true);
		}
		else
		{
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldUnwitherGate)
		{
			MaterialInstance.SetScalarParameterValue(n"BlendValue", ConnectedWateringPlant.WaterAmount);
		}
	}

	UFUNCTION(BlueprintCallable)
	void TriggerOpening()
	{
		if(bShouldUnwitherGate)
		{
			ConnectedWateringPlant.WaterHoseComp.DecaySpeed = 0.f;
			ConnectedWateringPlant.WaterHoseComp.CurrentDecaySpeed = 0.f;
			ConnectedWateringPlant.WaterHoseComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
			ConnectedWateringPlant.VineImpactComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		}
		OpeningTimelike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(GateOpenAudioEvent, this.GetActorTransform());
		Niagara::SpawnSystemAtLocation(LeafGateVFX, LeafVFXSpawnPosition.WorldLocation);
	}

	UFUNCTION()
	void OnOpeningUpdate(float Value)
	{
		FRotator NewRotation = FRotator(0.f, 0.f, OpenAngle * Value);

		LeftLeafRoot.SetRelativeRotation(NewRotation * -1.f);

		if(NewRotation.Roll > FMath::Abs(LeftLeafRoot2.RelativeRotation.Roll) - ClosedDistanceBetweenLeafs)
		{
			FRotator NewLeftRotation = FRotator(NewRotation.Pitch, NewRotation.Yaw, NewRotation.Roll + ClosedDistanceBetweenLeafs);
			LeftLeafRoot2.SetRelativeRotation(NewLeftRotation * -1.f);
		}
		if(NewRotation.Roll > FMath::Abs(LeftLeafRoot3.RelativeRotation.Roll) - (ClosedDistanceBetweenLeafs * 2))
		{
			FRotator NewLeftRotation = FRotator(NewRotation.Pitch, NewRotation.Yaw, NewRotation.Roll + (ClosedDistanceBetweenLeafs * 2));
			LeftLeafRoot3.SetRelativeRotation(NewLeftRotation * -1.f);
		}

		RightLeafRoot.SetRelativeRotation(NewRotation);

		if(NewRotation.Roll > RightLeafRoot2.RelativeRotation.Roll - ClosedDistanceBetweenLeafs)
		{
			FRotator NewRightRotation = FRotator(NewRotation.Pitch, NewRotation.Yaw, NewRotation.Roll + ClosedDistanceBetweenLeafs);
			RightLeafRoot2.SetRelativeRotation(NewRightRotation);
		}
		if(NewRotation.Roll > RightLeafRoot3.RelativeRotation.Roll - (ClosedDistanceBetweenLeafs * 2))
		{
			FRotator NewRightRotation = FRotator(NewRotation.Pitch, NewRotation.Yaw, NewRotation.Roll + (ClosedDistanceBetweenLeafs * 2));
			RightLeafRoot3.SetRelativeRotation(NewRightRotation);
		}
	}

	UFUNCTION()
	void OnOpeningFinished()
	{
		BoxCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		
		if(FullyOpenedEvent.IsBound())
			FullyOpenedEvent.Broadcast();
	}

	UFUNCTION(BlueprintCallable)
	void SetToDefaultState()
	{

		LeftLeafRoot.SetRelativeRotation(FRotator(0.f, 0.f, DefaultLeftRotation));
		LeftLeafRoot2.SetRelativeRotation(FRotator(0.f, 0.f, DefaultLeft2Rotation));
		LeftLeafRoot3.SetRelativeRotation(FRotator(0.f, 0.f, DefaultLeft3Rotation));
		RightLeafRoot.SetRelativeRotation(FRotator(0.f, 0.f, DefaultRightRotation));
		RightLeafRoot2.SetRelativeRotation(FRotator(0.f, 0.f, DefaultRight2Rotation));
		RightLeafRoot3.SetRelativeRotation(FRotator(0.f, 0.f, DefaultRight3Rotation));

		BoxCollider.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);

		if(bShouldUnwitherGate && MaterialInstance != nullptr)
		{
			SetActorTickEnabled(false);
			MaterialInstance.SetScalarParameterValue(n"BlendValue", 0.f);
		}
	}

	UFUNCTION(BlueprintCallable)
	void SetToCompletedState()
	{
		BoxCollider.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		LeftLeafRoot.SetRelativeRotation(FRotator(0.f, 0.f, -OpenAngle));
		LeftLeafRoot2.SetRelativeRotation(FRotator(0.f, 0.f, -OpenAngle));
		LeftLeafRoot3.SetRelativeRotation(FRotator(0.f, 0.f, -OpenAngle));
		RightLeafRoot.SetRelativeRotation(FRotator(0.f, 0.f, -OpenAngle));
		RightLeafRoot2.SetRelativeRotation(FRotator(0.f, 0.f, -OpenAngle));
		RightLeafRoot3.SetRelativeRotation(FRotator(0.f, 0.f, -OpenAngle));
	}
}
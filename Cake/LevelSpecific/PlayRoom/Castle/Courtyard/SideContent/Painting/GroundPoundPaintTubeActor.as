import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Cake.Environment.GPUSimulations.PaperPainting;

//Add Cooldown/bind to timelike duration, block groundpound attempts while cooling down

//
class AGroundPoundPaintTubeActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent PhysicsOverlap;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GroundPoundWidgetLocation;
	default GroundPoundWidgetLocation.RelativeLocation = FVector(0.f,0.f,100.f);

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY(DefaultComponent)
	UGroundPoundGuideComponent GroundPoundGuideComp;
	default GroundPoundGuideComp.ActivationRadius = 250.f;
	default GroundPoundGuideComp.TargetRadius = 30.f;
	default GroundPoundGuideComp.MinHeightAboveActor = 100.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent GroundPoundPaintSplashEvent;

	UPROPERTY()
	UNiagaraSystem PaintTubeEffect;

	UPROPERTY()
	UNiagaraSystem PaintPoolEffect;

	UPROPERTY(DefaultComponent)
	USceneComponent TubeEffectLocation;
	default TubeEffectLocation.RelativeLocation = FVector(280,0,55);

	FHazeConstrainedPhysicsValue PhysicsValue;

	UPROPERTY(EditInstanceOnly,Category = "Setup")
	APaperPainting PaintActor;

	UPROPERTY(EditInstanceOnly, meta = (MakeEditWidget))
	FTransform PaintTransform;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	UMaterialInstance MeshColorMaterial;

	UPROPERTY(Category = "Settings")
	FLinearColor EffectColor;

	UPROPERTY(EditDefaultsOnly, Category = "Settings")
	FHazeTimeLike DeformTimeLike;

	UPROPERTY(Category = "Settings")
	float DeformXScale = 1.25f;

	UPROPERTY(Category = "Settings")
	float DeformYScale = 1.25f;

	UPROPERTY(Category = "Settings")
	float DeformZScale = .75f;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeUserWidget> GroundPoundWidget;

	TPerPlayer<UHazeUserWidget> GPWidgets;

	UPROPERTY(EditInstanceOnly, Category = "Settings")
	float PaintRadius = 0.5f;

	UPROPERTY(Category = "Settings")
	bool bUseRandomRangeRadius = false;
	UPROPERTY(Category = "Settings")
	float MinRadius = 0.25f;
	UPROPERTY(Category = "Settings")
	float MaxRadius = 0.5f;

	UPROPERTY(Category = "Settings")
	bool bUseRandomRotation = false;
	UPROPERTY(Category = "Settings")
	float MinRotation = 0.f;
	UPROPERTY(Category = "Settings")
	float MaxRotation = 359.f;

	UPROPERTY(Category = "Settings")
	bool bUseRandomTexture = false;

	bool IsPressed = false;
	bool bShouldUpdateSpring = true;

	TPerPlayer<bool> bShowGPWidget;
	float WidgetRadius = 600.f;

	int OverlappingPlayers = 0;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(MeshColorMaterial != nullptr)
			Mesh.SetMaterial(2, MeshColorMaterial);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// WidgetSphere.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		// WidgetSphere.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");

		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");

		DeformTimeLike.BindUpdate(this, n"OnDeformUpdate");
		DeformTimeLike.BindFinished(this, n"OnDeformFinished");

		PhysicsValue.LowerBound = 0.9f;
		PhysicsValue.UpperBound = 1.f;
		PhysicsValue.LowerBounciness = 0.f;
		PhysicsValue.UpperBounciness = 1.f;
		PhysicsValue.Friction = 5.f;

		PhysicsOverlap.OnComponentBeginOverlap.AddUFunction(this, n"OnPhysicsOverlap");
		PhysicsOverlap.OnComponentEndOverlap.AddUFunction(this, n"OnPhysicsEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldUpdateSpring)
			CalcDownForce(DeltaTime);

		CheckShowAndHideWidget();
	}

	void CalcDownForce(float DeltaTime)
	{
		PhysicsValue.SpringTowards(1, 50.f);

		if(IsPressed)
			PhysicsValue.AddAcceleration(-10.f);
		
		PhysicsValue.Update(DeltaTime);
		FVector NewScale = Mesh.WorldScale;
		NewScale.Z = PhysicsValue.Value;
		Mesh.SetWorldScale3D(NewScale);		
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		if(PaintTubeEffect != nullptr)
		{
			UNiagaraComponent VFXSystem = Niagara::SpawnSystemAtLocation(PaintTubeEffect, TubeEffectLocation.WorldLocation, TubeEffectLocation.WorldRotation);
			VFXSystem.SetColorParameter(n"Color", EffectColor);
		} 

		UHazeAkComponent::HazePostEventFireForget(GroundPoundPaintSplashEvent, this.GetActorTransform());

		DeformTimeLike.PlayFromStart();

		if(PaintActor == nullptr)
			return;
	}

	UFUNCTION()
	void OnDeformUpdate(float Value)
	{
		float XScale = FMath::Lerp(1.f, DeformXScale, Value);
		float YScale = FMath::Lerp(1.f, DeformYScale, Value);
		float ZScale = FMath::Lerp(1.f, DeformZScale, Value);

		Mesh.SetWorldScale3D(FVector(XScale,YScale,ZScale));
	}

	UFUNCTION()
	void OnDeformFinished()
	{
		if(PaintPoolEffect != nullptr)
		{
			FVector Location = Root.RelativeTransform.TransformPosition(PaintTransform.Location);
			UNiagaraComponent VFXComp = Niagara::SpawnSystemAtLocation(PaintPoolEffect, Location, FRotator(0,90,0));
			VFXComp.SetColorParameter(n"Color", EffectColor);
		}

		FVector Location;
		Location = Root.RelativeTransform.TransformPosition(PaintTransform.Location);

		float RadiusToUse = bUseRandomRangeRadius ? FMath::RandRange(MinRadius, MaxRadius) : PaintRadius;
		float RotationToUse = bUseRandomRotation ? FMath::RandRange(MinRotation, MaxRotation) : 0.f;

		PaintActor.AddPaintToPool(Location, RadiusToUse, EffectColor, bUseRandomTexture, RotationToUse);
	}

	void CheckShowAndHideWidget()
	{
		TPerPlayer<float> PDistances;

		PDistances[0] = (Game::May.ActorLocation - ActorLocation).Size();
		PDistances[1] = (Game::Cody.ActorLocation - ActorLocation).Size();

		if (PDistances[0] <= WidgetRadius && !bShowGPWidget[0])
		{
			bShowGPWidget[0] = true;
			SetMayGPWidget(true);
		}
		else if (PDistances[0] > WidgetRadius && bShowGPWidget[0])
		{
			bShowGPWidget[0] = false;
			SetMayGPWidget(false);			
		}

		if (PDistances[1] <= WidgetRadius && !bShowGPWidget[1])
		{
			bShowGPWidget[1] = true;
			SetCodyGPWidget(true);
		}
		else if (PDistances[1] > WidgetRadius && bShowGPWidget[1])
		{
			bShowGPWidget[1] = false;
			SetCodyGPWidget(false);			
		}
	}

	void SetMayGPWidget(bool bValue)
	{
		if (bValue)
		{
			GPWidgets[0] = Game::May.AddWidget(GroundPoundWidget);
			GPWidgets[0].AttachWidgetToComponent(GroundPoundWidgetLocation);
		}
		else
		{
			RemoveWidget(Game::May);
		}
	}

	void SetCodyGPWidget(bool bValue)
	{
		if (bValue)
		{
			GPWidgets[1] = Game::Cody.AddWidget(GroundPoundWidget);
			GPWidgets[1].AttachWidgetToComponent(GroundPoundWidgetLocation);
		}
		else
		{
			RemoveWidget(Game::Cody);
		}
	}

	UFUNCTION()
	void OnPhysicsOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player;
		if((Player = Cast<AHazePlayerCharacter>(OtherActor)) != nullptr)
		{
			IsPressed = true;
			OverlappingPlayers++;
		}
	}

	UFUNCTION()
	void OnPhysicsEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		 UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player;
		if((Player = Cast<AHazePlayerCharacter>(OtherActor)) != nullptr)
		{
			OverlappingPlayers--;

			if(OverlappingPlayers <= 0)
				IsPressed = false;
		}
	}

	void RemoveWidget(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			Player.RemoveWidget(GPWidgets[0]);
		else
			Player.RemoveWidget(GPWidgets[1]);
	}
}
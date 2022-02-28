import Peanuts.Spline.SplineComponent;

struct FleeingCritter
{
	UStaticMeshComponent MeshComp;

	float CurrentFleetime = 0;

	bool Fleeing = false;
	
	float WalkTime = 0;

	FVector FleeOffset;

	float Angle;
}

class ACritterFleeing : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 4000.f;
	
    UPROPERTY(DefaultComponent)
	UHazeSplineComponent FleeSpline;
	default FleeSpline.AutoTangents = true;

    UPROPERTY(DefaultComponent)
	UHazeSplineComponent WalkSpline;
	default WalkSpline.AutoTangents = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent LoopingSoundComp;	
	default LoopingSoundComp.bIsStatic = true;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LoopingBeforeFleeingSoundEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent LoopingWhileFleeingSoundEvent;

	UPROPERTY(Category = "Audio Events")
	FHazeAudioEventInstance LoopingBeforeFleeingSoundInstance;

	UPROPERTY(Category = "Audio Events")
	FHazeAudioEventInstance LoopingWhileFleeingSoundInstance;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnStartFleeingSound;

    UPROPERTY()
	UStaticMesh Mesh;

    UPROPERTY()
	TArray<UMaterialInterface> RandomMaterials;
	
    UPROPERTY()
	float FleeTriggerDistance = 500;

    UPROPERTY()
	float FleeSpeed = 30;

    UPROPERTY()
	bool WalkAround = true;

    UPROPERTY()
	bool AlignWithFleeSpline = false;

    UPROPERTY()
	bool FleeSpeedIncreasesOverTime = true;

    UPROPERTY()
	float WalkAroundSpeed = 0.1f;

    UPROPERTY()
	int CritterCount = 4.0f;

    UPROPERTY()
	bool AnimateWhileFleeing = false;
	
    UPROPERTY()
	bool AnimateBeforeFleeing = true;

    UPROPERTY()
	bool BlendToPose2WhenFleeing = true;

	TArray<FleeingCritter> Critters;

    UPROPERTY()
    float Scale = 1;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		Critters = TArray<FleeingCritter>();
		for (int i = 0; i < CritterCount; i++)
		{
			auto NewMesh = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			Critters.Add(FleeingCritter());
			Critters[i].MeshComp = NewMesh;
			Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1", 0.0f);
			Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend2", 0.0f);
			Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
			if(AnimateBeforeFleeing)
				Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", 80.0f * WalkAroundSpeed);
			else
				Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", 0);

			Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1Animate", 1.0f);
			Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Random0to1", FMath::RandRange(0.0, 1.0));

			if(RandomMaterials.Num() > 0)
			{
				int index = FMath::RandRange(0, RandomMaterials.Num() - 1);
				auto RandomMaterial = RandomMaterials[index];
				Critters[i].MeshComp.SetMaterial(0, RandomMaterial);
			}
		}

		if(LoopingBeforeFleeingSoundEvent != nullptr)
			LoopingBeforeFleeingSoundInstance = LoopingSoundComp.HazePostEvent(LoopingBeforeFleeingSoundEvent);
    }

	UFUNCTION(CallInEditor)
	void FleeAll()
	{
		for (int i = 0; i < CritterCount; i++)
		{
			Flee(i);
		}
	}

	void Flee(int i)
	{
		Critters[i].Fleeing = true;
		FVector StartFleeOffset = Critters[i].MeshComp.GetRelativeLocation();
		Critters[i].MeshComp.SetWorldTransform(FleeSpline.GetTransformAtDistanceAlongSpline(0, ESplineCoordinateSpace::World));
		FVector EndFleeOffset = Critters[i].MeshComp.GetRelativeLocation();
		Critters[i].FleeOffset = StartFleeOffset - EndFleeOffset;
		
		UHazeAkComponent::HazePostEventFireForget(OnStartFleeingSound, FTransform(GetActorLocation()));
		
		if(AnimateWhileFleeing)
			Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", 80.0f * WalkAroundSpeed);
		else
			Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend1AnimateSpeed", 0);
			
		// If they all are fleeing, stop the looping sound.
		bool AllFleeing = true;
		for (int j = 0; j < CritterCount; j++)
		{
			if(!Critters[j].Fleeing)
			{
				AllFleeing = false;
				break;
			}
		}
		if(AllFleeing) // When the last critter flies away
		{
			if(LoopingBeforeFleeingSoundInstance.PlayingID != 0)
				LoopingSoundComp.HazeStopEventInstance(LoopingBeforeFleeingSoundInstance);

			if(LoopingWhileFleeingSoundEvent != nullptr)
				LoopingWhileFleeingSoundInstance = LoopingSoundComp.HazePostEvent(LoopingWhileFleeingSoundEvent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(CritterCount == 1)
		{
			if(Critters[0].MeshComp != nullptr)
			{
				LoopingSoundComp.SetWorldLocation(Critters[0].MeshComp.GetWorldLocation());
			}
		}

		for (int i = 0; i < CritterCount; i++)
		{
			if(Critters[i].MeshComp == nullptr)
				continue;

			if(!Critters[i].Fleeing)
			{
				for(AHazePlayerCharacter Player : Game::GetPlayers())
				{
					float dist = Critters[i].MeshComp.GetWorldLocation().Distance(Player.GetActorLocation());
					if(dist < FleeTriggerDistance)
					{
						Flee(i);
					}
				}
				
				if(WalkAround)
				{
					Critters[i].WalkTime += DeltaTime * WalkAroundSpeed;
					Critters[i].WalkTime = FMath::Frac(Critters[i].WalkTime);
					float WalkTime = FMath::Frac(Critters[i].WalkTime + float(i) / float(CritterCount));
					Critters[i].MeshComp.SetWorldTransform(WalkSpline.GetTransformAtTime(WalkTime, ESplineCoordinateSpace::World));
					Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));
				}

				Critters[i].Angle = Critters[i].MeshComp.GetWorldRotation().Yaw;
			}
			else
			{
				Critters[i].CurrentFleetime += DeltaTime * FleeSpeed;
				float FleeTimeSquared = Critters[i].CurrentFleetime;
				if(FleeSpeedIncreasesOverTime)
				{
					FleeTimeSquared = Critters[i].CurrentFleetime * Critters[i].CurrentFleetime;
				}
				Critters[i].MeshComp.SetWorldTransform(FleeSpline.GetTransformAtDistanceAlongSpline(FleeTimeSquared, ESplineCoordinateSpace::World));
				Critters[i].MeshComp.SetRelativeScale3D(FVector(Scale,Scale,Scale));

				if(!AlignWithFleeSpline)
					Critters[i].MeshComp.SetWorldRotation(FRotator(0, Critters[i].Angle, 0));

				Critters[i].MeshComp.AddRelativeLocation(Critters[i].FleeOffset);

				if(FleeTimeSquared > FleeSpline.GetSplineLength())
				{
					Critters[i].MeshComp.DestroyComponent(Critters[i].MeshComp);
					if(LoopingWhileFleeingSoundInstance.PlayingID != 0)
						LoopingSoundComp.HazeStopEventInstance(LoopingWhileFleeingSoundInstance);
				}

				if(BlendToPose2WhenFleeing)
				{
					float Blend = FMath::Clamp((Critters[i].CurrentFleetime / FleeSpeed) * 8.0f, 0.0f, 1.0f);
					Critters[i].MeshComp.SetScalarParameterValueOnMaterials(n"Blend2", Blend);
				}
			}
		}
    }
}
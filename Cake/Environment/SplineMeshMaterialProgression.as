import Peanuts.Spline.SplineComponent;
import Vino.Movement.Grinding.GrindSpline;
import Rice.Props.PropBaseActor;

class ASplineMeshMaterialProgression : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		CacheGrindSplines = BPGetGrindSplines();
		CacheTargetSplines = BPGetTargetSplines();

		if(BPGetScrollSurface())
		{
			for(auto comp : GetSplineMeshes(CurrentTargetSplineAS))
			{
				comp.SetScalarParameterValueOnMaterials(n"ConstantSpeed", BPGetConstantMoveSpeed());
			}
		}

		FollowSplineEffectComponent = Niagara::SpawnSystemAttached(
			FollowSplineEffect, 
			this.RootComponent, 
			NAME_None, 
			GetActorLocation(), 
			GetActorRotation(),
			EAttachLocation::KeepWorldPosition,
			true);
			
    }

    UPROPERTY(Category="Default")
	UNiagaraSystem FollowSplineEffect;

    //UPROPERTY()
	UNiagaraComponent FollowSplineEffectComponent;

    UPROPERTY()
	float SmallestVal = 9999;

    UFUNCTION()
	void SetToEndAS()
	{
		Tick(0.0f);
		if(CurrentTargetSplineAS == nullptr)
			return;

		auto SplineComp = GetSplineComponentAS(CurrentTargetSplineAS);
		if(SplineComp == nullptr)
			return;
		
		FVector WorldPos = SplineComp.GetLocationAtSplinePoint(SplineComp.GetNumberOfSplinePoints(), ESplineCoordinateSpace::World);
		if(FollowSplineEffectComponent != nullptr)
			FollowSplineEffectComponent.SetWorldLocation(WorldPos);
		SetActorLocation(WorldPos);
		for (auto a : GetSplineMeshes(CurrentTargetSplineAS))
		{
			a.SetScalarParameterValueOnMaterials(n"FillDistance", 1.0f);
		}
	}

	UFUNCTION()
	void SetToStartAS()
	{
		Tick(0.0f);
		if(CurrentTargetSplineAS == nullptr)
			return;

		auto SplineComp = GetSplineComponentAS(CurrentTargetSplineAS);
		if(SplineComp == nullptr)
			return;

		FVector WorldPos = SplineComp.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World);
		if(FollowSplineEffectComponent != nullptr)
			FollowSplineEffectComponent.SetWorldLocation(WorldPos);
		SetActorLocation(WorldPos);
		for (auto a : GetSplineMeshes(CurrentTargetSplineAS))
		{
			a.SetScalarParameterValueOnMaterials(n"FillDistance", 0.0f);
		}
	}

	TArray<AGrindspline> CacheGrindSplines;
	TArray<APropBaseActor> CacheTargetSplines;
	TArray<USplineMeshComponent> CacheCurrentSplineMeshes;
	UHazeSplineComponent CacheCurrentSplineComponent;

    UPROPERTY()
	AActor CurrentTargetSplineAS;

	AActor LastCurrentTargetSplineAS;

	FVector LastPosition;
	float LastOffset;

	// Timing
	TArray<double> timings = TArray<double>();
	int index = 0;
	
    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		// Timing
		//index++;
		//index %= 100;
		//while(timings.Num()<100){timings.Add(0);}
		//auto start = Time::GetPlatformTimeSeconds(); // Timing

		// if nothing changed, don't do anything.
		bool PositionChanged = LastPosition != GetActorLocation();
		LastPosition = GetActorLocation();
		bool OffsetChanged = LastOffset != BPGetOffset();
		LastOffset = BPGetOffset();
		if(PositionChanged || OffsetChanged)
		{
			if(CurrentTargetSplineAS == nullptr)
			{
				if(CacheTargetSplines.Num() > 0)
				{
					CurrentTargetSplineAS = (CacheTargetSplines[0]);
				}
				else
				{
					if(CacheGrindSplines.Num() > 0)
					{
						CurrentTargetSplineAS = (CacheGrindSplines[0]);
					}
				}
			}

			if(CacheTargetSplines.Num() == 0 && CacheGrindSplines.Num() == 0)
			{

			}
			else
			{
				SetTargetSplineAS();

				// current spline changed, update cached meshes
				if(LastCurrentTargetSplineAS != CurrentTargetSplineAS)
				{
					LastCurrentTargetSplineAS = CurrentTargetSplineAS;
					if(CurrentTargetSplineAS != nullptr)
					{
						CacheCurrentSplineMeshes = GetSplineMeshes(CurrentTargetSplineAS);
						CacheCurrentSplineComponent = GetSplineComponentAS(CurrentTargetSplineAS);
					}
				}
				
				if(CurrentTargetSplineAS != nullptr)
				{
					float blend = CacheCurrentSplineComponent.FindFractionClosestToWorldLocation(GetActorLocation());
					FVector WorldPos = CacheCurrentSplineComponent.GetLocationAtTime(blend, ESplineCoordinateSpace::World);
					if(FollowSplineEffectComponent != nullptr)
						FollowSplineEffectComponent.SetWorldLocation(WorldPos);
					float BlendValue = BPGetOffset() + (blend * CacheCurrentSplineMeshes.Num());

					//NewMacro0(CurrentTargetSplineAS, GetActorLocation(), BPGetOffset()); 
					float fraction = 1.0f;
					if(BPGetProgressContinuously())
						fraction = FMath::Frac(BlendValue);
					USplineMeshComponent PreviousMesh = GetValidSplineComponentFromFloat(BlendValue - 1.0f, CacheCurrentSplineMeshes);
					USplineMeshComponent CurrentMesh = GetValidSplineComponentFromFloat(BlendValue, CacheCurrentSplineMeshes);
					USplineMeshComponent NextMesh = GetValidSplineComponentFromFloat(BlendValue + 1.0f, CacheCurrentSplineMeshes);
					if(PreviousMesh != nullptr)
						PreviousMesh.SetScalarParameterValueOnMaterials(n"FillDistance", 1.0f);
					if(CurrentMesh != nullptr)
						CurrentMesh.SetScalarParameterValueOnMaterials(n"FillDistance", fraction);
					if(NextMesh != nullptr)
						NextMesh.SetScalarParameterValueOnMaterials(n"FillDistance", 0.0f);
					if(BPGetScrollSurface())
					{
						for(auto a : CacheCurrentSplineMeshes)
						{
							a.SetScalarParameterValueOnMaterials(n"PanDistance", BlendValue); // pretty expensive
						}
					}
				}
			}
		}


		// Timing
		//auto end = Time::GetPlatformTimeSeconds();
		//timings[index] = ((end - start) * 1000 * 1000);
		//double average = 0;
		//for (int i = 0; i < 100; i++)
		//{
		//	average += timings[i];
		//}
		//average /= 100.0f;
		//Print("" + average);
    }

	void SetTargetSplineAS()
	{
		SmallestVal = 9999;
		for(auto Comp : CacheGrindSplines)
		{
			if(Comp != nullptr)
				InternalSetTargetSpline(GetSplineComponentAS(Comp), Comp);
		}
	
		for(auto Comp : CacheTargetSplines)
		{
			if(Comp != nullptr)
				InternalSetTargetSpline(GetSplineComponentAS(Comp), Comp);
		}
	}

	void InternalSetTargetSpline(UHazeSplineComponent Spline, AActor Target)
	{
		if(Spline == nullptr)
			return;

		if(Target == nullptr)
			return;
			
		FVector SplinePos;
		float dist;
		Spline.FindDistanceAlongSplineAtWorldLocation(GetActorLocation(), SplinePos, dist);
		float distance = SplinePos.DistSquared(GetActorLocation());
		if(distance < SmallestVal)
		{
			CurrentTargetSplineAS = Target;
			SmallestVal = distance;
		}
	}

	float NewMacro0(AActor Target, FVector Location, float Offset) const
	{
		if(Target == nullptr)
			return 0;
		float fraction = CacheCurrentSplineComponent.FindFractionClosestToWorldLocation(Location);
		return Offset + (fraction * CacheCurrentSplineMeshes.Num());
	}
	
	UHazeSplineComponent GetSplineComponentAS(AActor Target) const
	{
		AGrindspline TargetAsGrindSpline = Cast<AGrindspline>(Target);
		if(TargetAsGrindSpline != nullptr)
		{
			return TargetAsGrindSpline.Spline;
		}
		APropBaseActor TargetAsBPSplineMesh = Cast<APropBaseActor>(Target);
		if(TargetAsBPSplineMesh != nullptr)
		{
			return TargetAsBPSplineMesh.BPSplineMeshGetSpline();
		}
		return nullptr;
	}

	TArray<USplineMeshComponent> GetSplineMeshes(AActor Target) const
	{
		AGrindspline TargetAsGrindSpline = Cast<AGrindspline>(Target);
		if(TargetAsGrindSpline != nullptr)
		{
			return TargetAsGrindSpline.GetSplineMeshComponents();
		}
		APropBaseActor TargetAsBPSplineMesh = Cast<APropBaseActor>(Target);
		if(TargetAsBPSplineMesh != nullptr)
		{
			return TargetAsBPSplineMesh.BPSplineMeshGetMeshComponents();
		}
		return TArray<USplineMeshComponent>();
	}

	USplineMeshComponent GetValidSplineComponentFromFloat(float A, TArray<USplineMeshComponent> Splines) const
	{
		if (Splines.IsValidIndex(A))
			return Splines[A];
		
		return nullptr;
	}

	
	// Implemented in BP for backwards compatability
	// TODO@MW for HAZE3: hoist this stuff up to AS completely.
    UFUNCTION(BlueprintEvent)
	float BPGetOffset(){return 0;}

    UFUNCTION(BlueprintEvent)
	TArray<AGrindspline> BPGetGrindSplines(){return TArray<AGrindspline>();}
	
    UFUNCTION(BlueprintEvent)
	TArray<APropBaseActor> BPGetTargetSplines(){return TArray<APropBaseActor>();}

    UFUNCTION(BlueprintEvent)
	bool BPGetScrollSurface(){return false;}
    
    UFUNCTION(BlueprintEvent)
	bool BPGetProgressContinuously(){return false;}
    
	UFUNCTION(BlueprintEvent)
	float BPGetConstantMoveSpeed(){return 0;}
    
}
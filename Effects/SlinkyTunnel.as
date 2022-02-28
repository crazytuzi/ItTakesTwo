import Peanuts.Spline.SplineComponent;

class ASlinkySpline : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent GuideSpline;

	UPROPERTY(Category="Settings")
	float StartPos = 0.1f;

	UPROPERTY(Category="Settings")
	float EndPos = 0.0f;

	UPROPERTY(Category="Settings")
	int Segments = 10;
	
	UPROPERTY(Category="Settings")
	float MoveSpeed = 0.5f;
	
	UPROPERTY(Category="Settings")
	UStaticMesh Mesh;
	
	UPROPERTY(Category="Simulation")
	float Speed = 0.1f;

	UPROPERTY(Category="Simulation")
	float Damping = 0.075f;

	UPROPERTY(Category="zzInternal")
	bool Moving = false;

	UPROPERTY(Category="zzInternal")
	TArray<USplineMeshComponent> SplinePhysicsMeshes;
	
	UPROPERTY(Category="zzInternal")
	TArray<float> SplinePhysicsPositions;

	UPROPERTY(Category="zzInternal")
	TArray<float> SplinePhysicsVelocities;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitializeSpringSimulation();
	}
	
	float TargetStart = 0.0f;
	float TargetEnd = 0.1f;

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateSpringSimulation(DeltaTime);
		UpdateSpringMeshes();

		if(Moving)
		{
			StartPos = MoveTowards(StartPos, TargetStart, DeltaTime * MoveSpeed);
			EndPos = MoveTowards(EndPos, TargetEnd, DeltaTime * MoveSpeed);
			if(StartPos == TargetStart && EndPos == TargetEnd)
				Moving = false;
		}
	}
	
	UFUNCTION()
	void SetSlinkyTarget(float Start, float End)
	{
		this.TargetStart = Start;
	 	this.TargetEnd = End;
		this.Moving = true;
	}
	
	UFUNCTION()
	void SetSlinky(float Start, float End)
	{
		this.TargetStart = Start;
	 	this.TargetEnd = End;
		this.StartPos = Start;
	 	this.EndPos = End;
		this.Moving = true;
		this.MoveSpeed = MoveSpeed;
		InitializeSpringSimulation();
	}


	//UFUNCTION(CallInEditor, Category="Settings")
	//void Test()
	//{
	//	SetSlinkyTarget(0.9, 1.0, 0.6);
	//}
	

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }

	void InitializeSpringSimulation()
	{
		float ActualStartPos = StartPos;
		float ActualEndPos = EndPos;
		if(StartPos > EndPos)
		{
			ActualStartPos = EndPos;
			ActualEndPos = StartPos;
		}

		for (int i = 0; i < Segments; i++)
		{
			SplinePhysicsPositions[i] = FMath::Lerp(ActualStartPos, ActualEndPos, float(i) / float(Segments - 1.0f));
		}
	}

	// Simple 1D spring simulation.
	void UpdateSpringSimulation(float DeltaTime)
	{
		float ActualStartPos = StartPos;
		float ActualEndPos = EndPos;
		if(StartPos > EndPos)
		{
			ActualStartPos = EndPos;
			ActualEndPos = StartPos;
		}
		SplinePhysicsPositions[0] = ActualStartPos;
		SplinePhysicsPositions[Segments - 1] = ActualEndPos;
		for (int i = 1; i < Segments-1; i++)
		{
			// Get the average location of our two neighbours
			float AveragePositionOfNeighbours = (SplinePhysicsPositions[i - 1] + SplinePhysicsPositions[i + 1]) * 0.5f;

			// Add velocity towards the average location of neighbours
			SplinePhysicsVelocities[i] += (AveragePositionOfNeighbours - SplinePhysicsPositions[i]);

			// Add velocity to position to update locations
			SplinePhysicsPositions[i] += SplinePhysicsVelocities[i] * Speed;
			SplinePhysicsVelocities[i] *= (1.0f - Damping);
		}
	}

	// Update meshes to match the simulation
	void UpdateSpringMeshes()
	{
		float last = SplinePhysicsPositions[0];
		for (int i = 0; i < Segments-1; i++)
		{
			float current = SplinePhysicsPositions[i+1];
			PlaceSplineMeshOnSpline(GuideSpline, SplinePhysicsMeshes[i], last, current);
			last = current;
		}
	}

	// Place a single mesh on a spline. Lots of bugs in this one, should be good enough for slinky though.
	void PlaceSplineMeshOnSpline(USplineComponent Spline, USplineMeshComponent SplineMesh, float Start, float End)
	{
		FVector StartLocation = Spline.GetLocationAtTime(Start, ESplineCoordinateSpace::Local);
		FVector EndLocation = Spline.GetLocationAtTime(End, ESplineCoordinateSpace::Local);

		FVector StartTangent = Spline.GetTangentAtTime(Start, ESplineCoordinateSpace::Local);
		FVector EndTangent = Spline.GetTangentAtTime(End, ESplineCoordinateSpace::Local);
		StartTangent.Normalize();
		EndTangent.Normalize();

		FVector StartUpVector = Spline.GetUpVectorAtTime(Start, ESplineCoordinateSpace::Local);
		FVector EndUpVector = Spline.GetUpVectorAtTime(End, ESplineCoordinateSpace::Local);
		StartUpVector.Normalize();
		EndUpVector.Normalize();
		float dist = StartLocation.Distance(EndLocation);
		SplineMesh.SetStartAndEnd(StartLocation, StartTangent*dist, EndLocation, EndTangent*dist);
		
		// Twist-correct.
		FVector c1 = EndTangent.CrossProduct(StartUpVector);
		FVector c2 = EndTangent.CrossProduct(EndUpVector);
		FVector c3 = c1.CrossProduct(c2);
		c1.Normalize();
		c2.Normalize();
		c3.Normalize();
		float a = c1.DotProduct(c2);
		float b = c3.DotProduct(EndTangent);
		float EndRoll = FMath::Acos(a) * FMath::Sign(b) * -1.0f;

		SplineMesh.SetStartRoll(0);
		SplineMesh.SetEndRoll(EndRoll);

		SplineMesh.SetSplineUpDir(StartUpVector);
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SplinePhysicsMeshes.Empty();
		SplinePhysicsPositions.Empty();
		SplinePhysicsVelocities.Empty();

		float NextI = 0;
		for (int i = 0; i < Segments; i++)
		{
			float S = Segments;
			float I = i;
			NextI = I + 1.0f;
			if(i > 0)
			{
				USplineMeshComponent SplineMesh = Cast<USplineMeshComponent>(CreateComponent(USplineMeshComponent::StaticClass()));
				SplineMesh.StaticMesh = Mesh;
				SplinePhysicsMeshes.Add(SplineMesh);
			}
			
			SplinePhysicsPositions.Add((I/S)*0.25f);
			SplinePhysicsVelocities.Add(0);
		}
		UpdateSpringMeshes();
	}
}
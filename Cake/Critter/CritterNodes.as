import Peanuts.Spline.SplineComponent;

struct CritterNodeCritter
{
	UPROPERTY()
	UStaticMeshComponent MeshComp;

	UPROPERTY()
	int TargetNode;

}

struct CritterNodeNode
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	TArray<int> ConnectedNodes;
}

struct CritterNodeBox
{
	UPROPERTY()
	UBoxComponent Box;

	UPROPERTY()
	int Nodes;

	UPROPERTY(Meta = (MakeEditWidget))
	FTransform Location;
}

class ACritterNodes : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000.f;
	
    UPROPERTY()
	UStaticMesh Mesh;

    UPROPERTY()
	float FleeTriggerDistance = 500;

    UPROPERTY()
	float NodeSearchDistance = 200;

    UPROPERTY()
	float CritterSpeed = 100.0f;
	
	UPROPERTY()
	int NumberOfCritters = 10;

	UPROPERTY()
	TArray<CritterNodeBox> Boxes;

	UPROPERTY(Meta = (MakeEditWidget), Category="zzInternal")
	TArray<FVector> ManualPoints;

	UPROPERTY(Category="zzInternal")
	TArray<CritterNodeNode> WSPoints;

	UPROPERTY(Category="zzInternal")
	TArray<CritterNodeCritter> Critters;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		System::FlushPersistentDebugLines();
		WSPoints.Empty();
		
		for (int i = 0; i < Boxes.Num(); i++)
		{
			auto NewBox =  Cast<UBoxComponent>(CreateComponent(UBoxComponent::StaticClass()));
			Boxes[i].Box = NewBox;
			NewBox.bIsEditorOnly = true;
			NewBox.SetRelativeTransform(Boxes[i].Location);
			for (int j = 0; j < Boxes[i].Nodes; j++)
			{
				auto NewNode = CritterNodeNode();
				float x = FMath::RandRange(-NewBox.BoxExtent.X, NewBox.BoxExtent.X);
				float y = FMath::RandRange(-NewBox.BoxExtent.Y, NewBox.BoxExtent.Y);
				float z = FMath::RandRange(-NewBox.BoxExtent.Z, NewBox.BoxExtent.Z);
				NewNode.Location = GetActorTransform().TransformPosition(Boxes[i].Location.TransformPosition(FVector(x, y, z)));
				WSPoints.Add(NewNode);
			}
		}
		
		for (int i = 0; i < ManualPoints.Num(); i++)
		{
			auto NewNode = CritterNodeNode();
			NewNode.Location = GetActorTransform().TransformPosition(ManualPoints[i]);
			WSPoints.Add(NewNode);
		}

		for (int i = 0; i < WSPoints.Num(); i++)
		{
			WSPoints[i].ConnectedNodes = GetNodesInRadius(WSPoints[i].Location, NodeSearchDistance);
			// Debugging
			for (int j = 0; j < WSPoints[i].ConnectedNodes.Num(); j++)
			{
				System::DrawDebugLine(WSPoints[i].Location, WSPoints[WSPoints[i].ConnectedNodes[j]].Location, FLinearColor::White, 10.0f);	
			}
		}

		Critters.Empty();
		for (int i = 0; i < NumberOfCritters; i++)
		{
			auto NewMesh = Cast<UStaticMeshComponent>(CreateComponent(UStaticMeshComponent::StaticClass()));
			NewMesh.StaticMesh = Mesh;
			NewMesh.CollisionEnabled = ECollisionEnabled::NoCollision;
			NewMesh.CollisionProfileName = n"NoCollision";
			CritterNodeCritter NewCritter = CritterNodeCritter();
			
			int index = FMath::RandRange(0, WSPoints.Num()-1);
			NewMesh.SetWorldLocation(WSPoints[index].Location);
			NewCritter.MeshComp = NewMesh;
			NewCritter.TargetNode = index;
			Critters.Add(NewCritter);
		}
	}

	//FVector FindClosestNode(FVector Pos, FVector IgnoreThis)
	//{
	//	FVector Result;
	//	float dist = 999999;
	//	for (int j = 0; j < WSPoints.Num(); j++)
	//	{
	//		if(Pos == WSPoints[j].Location) 
	//			continue;
	//		if(IgnoreThis == WSPoints[j].Location) 
	//			continue;
	//		float curdist = Pos.Distance(WSPoints[j].Location);
	//		if(curdist > dist)
	//			continue;
	//		dist = curdist;
	//		Result = WSPoints[j].Location;
	//	}
	//	return Result;
	//}

	TArray<int> GetNodesInRadius(FVector Pos, float Radius)
	{
		TArray<int> Result = TArray<int>();
		for (int j = 0; j < WSPoints.Num(); j++)
		{
			if(Pos.Distance(WSPoints[j].Location) > Radius)
				continue;

			Result.Add(j);
		}
		return Result;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
    }

	FVector MoveTowards(FVector Current, FVector Target, float StepSize)
    {
		FVector Delta = Target - Current;
		float Distance = Delta.Size();
		float ClampedDistance = FMath::Min(Distance, StepSize);
		FVector Direction = Delta / Distance;
        return Current + Direction * ClampedDistance;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = 0; i < NumberOfCritters; i++)
		{
			FVector CurrentPos = Critters[i].MeshComp.GetWorldLocation();
			if(CurrentPos == WSPoints[Critters[i].TargetNode].Location)
			{
				TArray<int> Targets = WSPoints[Critters[i].TargetNode].ConnectedNodes;
				Critters[i].TargetNode = Targets[FMath::RandRange(0, Targets.Num()-1)];
			}
			else
			{
				FVector TargetPos = WSPoints[Critters[i].TargetNode].Location;
				FVector NewPos = MoveTowards(CurrentPos, TargetPos, DeltaTime * CritterSpeed);
				Critters[i].MeshComp.SetWorldLocation(NewPos);
				Critters[i].MeshComp.SetWorldRotation(FRotator::MakeFromXZ(TargetPos - CurrentPos, FVector::UpVector));
			}
		}
    }
}
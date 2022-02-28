import Cake.LevelSpecific.Tree.Waternado.WaternadoNode;

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class UWaternadoMovementComponent : UActorComponent
{
	// How fast the waterspout should move towards the nodes
	UPROPERTY(Category = "Nado Movement")
	float LinearSpeed = 2300.f;

	/* linear speed used when attacking player. 
	 	values >= 0 will enable this. */
	UPROPERTY(Category = "Nado Movement")
	float LinearSpeedAttackPlayer = -1.f;

	/* linear speed used when going for the escape node, after attacking the player
	 	values >= 0 will enable this. */
	UPROPERTY(Category = "Nado Movement")
	float LinearSpeedPostAttack = -1.f;

	/* Can be seen as the start node initially. It will 
		automatically find the nearest if this is left unassgined */
	UPROPERTY(Category = "Nado Movement")
	AWaternadoNode CurrentNode = nullptr;

	/* */
	UPROPERTY(Category = "Nado Movement")
	AWaternadoNode StartReferenceActor = nullptr;

	// will trace against this actor to figure out water height
	UPROPERTY(Category = "Nado Movement")
	ALandscapeProxy WaterSurfaceActor;

	/* Node which the nado goes to after attacking the player */
	UPROPERTY(Category = "Nado Movement")
	TArray<AWaternadoNode> PostAttackNodes;

	/* Shows/hides debug meshes on the nodes so that
	 you can edit them in runtime */
	UPROPERTY(Category = "Nado Debug")
	const bool bHideNodesActors = true;

	/* Draws lines between the node for the chain which
	 the tornado is currently following */
	UPROPERTY(Category = "Nado Debug")
	const bool bDrawConnectionArrows = false;

	// Draws the locations which the spout has taken 
	UPROPERTY(Category = "Nado Debug")
	const bool bDrawLocationHistory = false;

	int LoopIndex = -1;
	float SplineAlpha = 0.f;
	float SplineAlphaSpeed = 0.f;
	float PrevMoveSpeed = 0.f;
	bool bLoopingSpline = false;
	TArray<FVector> NodeLocations;
	TArray<AWaternadoNode> Nodes;
	FVector InitSplineStartLocation = FVector::ZeroVector;
	FVector StartLocation = FVector::ZeroVector;
	FHazeAcceleratedFloat WaterSurfaceZ;

	void DebugDrawCurrentLocation()
	{
		if(!bDrawLocationHistory)
			return;

		const float SplineLen = CalcSplineLength();
		const float CurrentLinearSpeed = GetSpeed();
		const float TimeToLoopSpline = CurrentLinearSpeed == 0.f ? 0.f : SplineLen / CurrentLinearSpeed;
		System::DrawDebugPoint(Owner.GetActorLocation(), 10.f, FLinearColor::Red, TimeToLoopSpline);
		// PrintToScreen("Spline length: " + SplineLen);
		// PrintToScreen("TimeToLoopSpline: " + TimeToLoopSpline);
	}

	void DebugHideNodes()
	{
		for(auto Node : Nodes)
		{
			Node.SetActorHiddenInGame(bHideNodesActors);
		}
	}

	void DebugDrawNodePath()
	{
		if(!bDrawConnectionArrows)
			return;

		// Use floyds cycle-finding algo
		AWaternadoNode SlowNode = CurrentNode;
		AWaternadoNode FastNode = CurrentNode;

		int LoopCounter = 0;

		while(SlowNode.Next != nullptr)
		{
			//System::DrawDebugLine(
			System::DrawDebugArrow(
				SlowNode.GetActorLocation(),
				SlowNode.Next.GetActorLocation(),
				10000.f,
				FLinearColor::Yellow,
				0.f,
				40.f
			);

			SlowNode = SlowNode.Next;

			if(FastNode != nullptr && FastNode.Next != nullptr)
				FastNode = FastNode.Next.Next;

			// Cycle detected
			if(SlowNode == FastNode)
				break;

			// just in case..
			++LoopCounter;
			if(LoopCounter > 100)
			{
				ensure(false);
				break;
			}
		}
	}

	void UpateWaterSurfaceHeight(const float Dt)
	{

		float DesiredWaterHeight = Owner.GetActorLocation().Z;

		if (WaterSurfaceActor != nullptr)
		{
			const bool bHit = WaterSurfaceActor.GetHeightAtLocation(
				Owner.GetActorLocation(),
				DesiredWaterHeight
			);
		}

		//WaterSurfaceZ.SnapTo(DesiredWaterHeight);

		// WaterSurfaceZ.SnapTo(
		// 	FMath::FInterpConstantTo(
		// 		WaterSurfaceZ.Value,
		// 		DesiredWaterHeight,
		// 		Dt,
		// 		1.f
		// 	)
		// );

		// WaterSurfaceZ.AccelerateTo(
		// 	DesiredWaterHeight,
		// 	12.f,
		// 	Dt
		// );

		WaterSurfaceZ.SpringTo ( DesiredWaterHeight, 1.f, 0.6f, Dt );

		// PrintToScreen("Z: " + WaterSurfaceZ);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();
	}

	void Initialize()
	{
		if(CurrentNode == nullptr)
			CurrentNode = FindClosestNode();

		if(StartReferenceActor == nullptr)
			StartLocation = Owner.GetActorLocation();
		else
			StartLocation = StartReferenceActor.GetActorLocation();

		WaterSurfaceZ.SnapTo(StartLocation.Z);

		if(CurrentNode != nullptr)
			InitSplineMovement();
	}

	void DebugDrawDisableAttackRadius()
	{
		AWaternadoNode DebugStartNode = CurrentNode;

		if(DebugStartNode == nullptr)
		{
			DebugStartNode = FindClosestNode();
			if(DebugStartNode == nullptr)
				return;
		}

		TArray<AWaternadoNode> DebugNodes;
		int LoopIdx = DebugStartNode.GetNodeChainList(DebugNodes);
		// if(LoopIdx != -1)
		// {
		// 	for (int i = DebugNodes.Num() - 1; i >= 0 ; i--)
		// 	{
		// 		if(i < LoopIdx)
		// 		{
		// 			DebugNodes.RemoveAt(i);
		// 		}
		// 	}
		// }

		FVector DebugCOM = FVector::ZeroVector;

		for(auto DebugNode : DebugNodes)
			DebugCOM += DebugNode.GetActorLocation();
		DebugCOM /= DebugNodes.Num();

		float FurthestDistanceFromCOM = 0.f;
		for(auto DebugNode : DebugNodes)
		{
			const float Dist = DebugNode.GetActorLocation().Distance(DebugCOM);
			if(Dist > FurthestDistanceFromCOM)
				FurthestDistanceFromCOM = Dist;
		}

		System::DrawDebugSphere(DebugCOM, FurthestDistanceFromCOM, 16, FLinearColor::LucBlue, 3.f, 10.f);
	}

	AWaternadoNode FindClosestNode() const
	{
		TArray<AWaternadoNode> AllNodes;
		GetAllActorsOfClass(AllNodes);

		if(AllNodes.Num() <= 0)
			return nullptr;

		float ClosestDistanceSQ = BIG_NUMBER;
		AWaternadoNode ClosestNode = nullptr;

		for(AWaternadoNode Node : AllNodes)
		{
			const float DistanceSQ = Node.GetSquaredDistanceTo(Owner);
			if(DistanceSQ < ClosestDistanceSQ)
			{
				ClosestDistanceSQ = DistanceSQ;
				ClosestNode = Node;
			}
		}

		return ClosestNode;
	}

	AWaternadoNode FindClosestNodePostAttack() const
	{
		if(PostAttackNodes.Num() <= 0)
			return nullptr;

		float ClosestDistanceSQ = BIG_NUMBER;
		AWaternadoNode ClosestNode = nullptr;

		for(AWaternadoNode Node : PostAttackNodes)
		{
			const float DistanceSQ = Node.GetSquaredDistanceTo(Owner);
			if(DistanceSQ < ClosestDistanceSQ)
			{
				ClosestDistanceSQ = DistanceSQ;
				ClosestNode = Node;
			}
		}

		return ClosestNode;
	}

	void EndPlayerAttackMovement()
	{
		if (PostAttackNodes.Num() == 0)
			CurrentNode = FindClosestNode();
		else
			CurrentNode = FindClosestNodePostAttack();

		InitSplineMovement();
		SplineAlpha = 0.f;
	}

	void InitSplineMovement()
	{
		Nodes.Reset();
		LoopIndex = CurrentNode.GetNodeChainList(Nodes);

		InitSplineStartLocation = Owner.GetActorLocation();

		bLoopingSpline = LoopIndex != -1;

		UpdateSplineLocations();

		// need to update the lerp speed as the spline length changes 
		UpdateSplineAlphaSpeed();
	}

	void UpdateSplineMovement(const float Dt)
	{

		if(NodeLocations.Num() < 2)
		{
			UpdateLinearMovement(Dt);
			return;
		}

		// project all nodes locations onto the waterplane
		if(WaterSurfaceActor != nullptr)
		{
			for(FVector& NodePos : NodeLocations)
			{
				NodePos.Z = WaterSurfaceZ.Value;
			}
		}

// 		// update params that might be changed during runtime
// #if EDITOR
// 		UpdateSplineLocations();
// 		const float CurrentLinearSpeed = GetSpeed();
// 		if(CurrentLinearSpeed != PrevMoveSpeed)
// 		{
// 			PrevMoveSpeed = CurrentLinearSpeed;
// 			UpdateSplineAlphaSpeed();
// 		}
// #endif

		SplineAlpha += SplineAlphaSpeed * Dt;

		//FVector SplineLocation = Math::GetLocationOnCRSpline(
		FVector SplineLocation = Math::GetLocationOnCRSplineConstSpeed(
			NodeLocations.Last(1),
			NodeLocations,
			NodeLocations[1],
			FMath::Clamp(SplineAlpha, 0.f, 1.f)
		);

		if(SplineAlpha >= 1.f && bLoopingSpline)
		{
			SplineAlpha %= 1.f;

			if(LoopIndex != -1)
			{
				// how far have we moved on the next loop?
				const float SplineLength = CalcSplineLength();
				const float DeltaMoveMag = SplineLength * SplineAlpha;

				for (int i = Nodes.Num() - 1; i >= 0 ; i--)
				{
					if(i < LoopIndex)
					{
						Nodes.RemoveAt(i);
					}
				}

				LoopIndex = -1;

				UpdateSplineLocations();
				UpdateSplineAlphaSpeed();

				// increment spline alpha based on how much we overstepped
				const float NewSplineLength = CalcSplineLength();
				SplineAlpha = DeltaMoveMag / NewSplineLength;
				if(!FMath::IsWithin(SplineAlpha, 0.f, 1.f))
				{
					ensure(false);
					SplineAlpha = FMath::Clamp(SplineAlpha, 0.f, 1.f);
				}
			}
		}

		// Update CurrentNode
		if(CurrentNode.Next != nullptr)
		{
			// We want to figure out how far we'll move this frame
			// and use that magnitude as a threshold 
			const FVector WaternadoPos = Owner.GetActorLocation();
			const float DeltaMoveMagnitude = (SplineLocation - WaternadoPos).Size();

			// How far is it to the next node
			FVector NextNodePos = CurrentNode.Next.GetActorLocation();
			if(WaterSurfaceActor != nullptr)
				NextNodePos.Z = WaterSurfaceZ.Value;
			const FVector ToNextNode = NextNodePos - WaternadoPos;
			const float ToNextNodeDistance = ToNextNode.Size();

			// switch to next node when close enough
			if(FMath::IsNearlyZero(ToNextNodeDistance, DeltaMoveMagnitude))
				CurrentNode = CurrentNode.Next;

			// System::DrawDebugPoint(CurrentNode.GetActorLocation(), 50.f, FLinearColor::Blue);
			// PrintToScreenScaled("CurrentNode: " + MoveComp.CurrentNode.GetName());
		}

		Owner.SetActorLocation(SplineLocation);
	}

	void UpdateLinearMovement(const float Dt)
	{
		const FVector WaternadoPos = Owner.GetActorLocation();

		// follow next node as long as we have more then 1 node
		AWaternadoNode NodeToFollow  = CurrentNode;
		if(CurrentNode.Next != nullptr)
			NodeToFollow = CurrentNode.Next;

		FVector NextNodePos = NodeToFollow.GetActorLocation();

		// Project all nodes onto the waterplane
		if(WaterSurfaceActor != nullptr)
			NextNodePos.Z = WaterSurfaceZ.Value;

		const FVector ToNextNode = NextNodePos - WaternadoPos;
		const float ToNextNodeDistance = ToNextNode.Size();
		const float DeltaMoveMagnitude = GetSpeed() * Dt;

		// move towards next node
		if(ToNextNodeDistance > SMALL_NUMBER)
		{
			const FVector ToNextNodeNormalized = ToNextNode / ToNextNodeDistance;
			const FVector DeltaMove = ToNextNodeNormalized * DeltaMoveMagnitude;
			Owner.AddActorWorldOffset(DeltaMove);
		}

		// switch to next node when close enough
		// (note that we use deltamove as threshold here)
		if(CurrentNode.Next != nullptr && FMath::IsNearlyZero(ToNextNodeDistance, DeltaMoveMagnitude))
			CurrentNode = CurrentNode.Next;

	}

	void UpdateSplineLocations()
	{
		NodeLocations.Reset();
		for(auto Node : Nodes)
			NodeLocations.Add(Node.GetActorLocation());

		// Including start location makes sure that the tornado walks 
		// up to the spline before starting to follow it
		if(!bLoopingSpline || bLoopingSpline && LoopIndex != -1)
			NodeLocations.Insert(InitSplineStartLocation);

		// project all nodes locations onto the waterplane
		if(WaterSurfaceActor != nullptr)
		{
			for(FVector& NodePos : NodeLocations)
				NodePos.Z = WaterSurfaceZ.Value;
		}

	}

	void UpdateSplineAlphaSpeed()
	{
		const float SplineLength = CalcSplineLength();
		const float NewSplineAlphaSpeed = GetSpeed() / SplineLength;
		SplineAlphaSpeed = NewSplineAlphaSpeed;
	}

	float CalcSplineLength() const
	{
		return Math::GetCRSplineLengthConstSpeed(
			NodeLocations.Last(1),
			NodeLocations,
			NodeLocations[1]
		);
	}

	float GetSpeed() const
	{
		if (PostAttackNodes.Num() != 0 && 
			LinearSpeedPostAttack != -1.f &&
			PostAttackNodes.Contains(CurrentNode)
		)
		{
			return LinearSpeedPostAttack;
		}

		return LinearSpeed;
	}

	float GetAttackSpeed() const
	{
		return LinearSpeedAttackPlayer > 0.f ? LinearSpeedAttackPlayer : GetSpeed();
	}

}
















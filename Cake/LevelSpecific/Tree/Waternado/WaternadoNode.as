
/*
	Node which the waterspout follows
*/

event void FNodeConstructed();

UCLASS(Abstract)
class AWaternadoNode : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent DebugMesh;
	default DebugMesh.StaticMesh = Asset("/Engine/BasicShapes/Sphere");

	default DebugMesh.SetCollisionProfileName(n"NoCollision");
	default DebugMesh.SetGenerateOverlapEvents(false);

	// Actor will be hidden in game so it is fine
	default DebugMesh.SetHiddenInGame(false);
	default DebugMesh.SetComponentTickEnabled(false);

	UPROPERTY(DefaultComponent)
	UArrowComponent DebugNextNodeArrow;
	default DebugNextNodeArrow.ArrowSize = 30.f;
	default DebugNextNodeArrow.SetArrowColor(FLinearColor::Yellow);
	default DebugNextNodeArrow.SetHiddenInGame(true);

	default SetActorHiddenInGame(true);

	UPROPERTY(Category = "Node settings")
	AWaternadoNode Next;
	AWaternadoNode OldNext;

	UPROPERTY(Category = "Node settings")
	AWaternadoNode Prev;
	AWaternadoNode OldPrev;

 	UPROPERTY(Category = "Events", meta = (BPCannotCallEvent))
	FNodeConstructed OnNodeConstructed;

	// We tried using the normal constructor for this
	// but the actor location was == Zero vector...
	bool bNewlyCreated = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

#if EDITOR	
		if(bNewlyCreated)
		{
			AutoAssignCopyPastedNodes();
			bNewlyCreated = false;
		}
#endif

		// Only show debug arrow when we have a next node
		if(Next != nullptr)
		{
			DebugNextNodeArrow.SetVisibility(true);
			UpdateDebugArrowTransform();
		}
		else
		{
			DebugNextNodeArrow.SetVisibility(false);
		}

		// Update bindings for debug
		UpdateCallbackBindings();

		OnNodeConstructed.Broadcast();
	}

	/* yes this is dirty but it only happens once.
		And I couldn't find any better way to do it, in angelscript.
		Having a ThisNode reference doesn't work due to UE4 reflections system
		Updating all this ptrs when copy pasting  */ 
	void AutoAssignCopyPastedNodes()
	{
		// auto assign copy pasted nodes...
		TArray<AWaternadoNode> Nodes;
		GetAllActorsOfClass(Nodes);
		for(auto Node : Nodes)
		{
			if(Node == this)
				continue;

			if(Node.Next != nullptr)
				continue;
			
			if(Node.GetActorLocation().Equals(GetActorLocation()))
			{
				Node.HandleCopyPastedBy(this);
				Prev = Node;
				UpdateCallbackBindings();
				break;
			}
		}
	}

	// Other nodes might call this func when they are created by copying this node
	void HandleCopyPastedBy(AWaternadoNode InNode)
	{
		if(Next != nullptr)
			return;

		Next = InNode;
		DebugNextNodeArrow.SetVisibility(true);
		UpdateDebugArrowTransform();
		UpdateCallbackBindings();
	}

	void UpdateCallbackBindings()
	{
		// Update Next
		if(Next != OldNext)
		{
			if(OldNext != nullptr)
				OldNext.OnNodeConstructed.Unbind(this, n"HandleNextNodeConstructed");

			if(Next != nullptr)
				Next.OnNodeConstructed.AddUFunction(this, n"HandleNextNodeConstructed");

			OldNext = Next;
		}

		// Update Prev
		if(Prev != OldPrev)
		{
			if(OldPrev != nullptr)
				OldPrev.OnNodeConstructed.Unbind(this, n"HandlePrevNodeConstructed");

			if(Prev != nullptr)
				Prev.OnNodeConstructed.AddUFunction(this, n"HandlePrevNodeConstructed");

			OldPrev = Prev;
		}
	}

	UFUNCTION()
	void HandleNextNodeConstructed()
	{
		if(Next != nullptr)
			UpdateDebugArrowTransform();
	}

	UFUNCTION()
	void HandlePrevNodeConstructed()
	{
		if(Next != nullptr)
			UpdateDebugArrowTransform();
	}

	void UpdateDebugArrowTransform()
	{
		const FVector ToNext = Next.GetActorLocation() - GetActorLocation();
		const float ToNextDist = ToNext.Size();

		// Location
		FTransform NewTransform = DebugNextNodeArrow.GetWorldTransform();

		if(ToNextDist > SMALL_NUMBER)
		{
			// Rotation
			const FVector ToNextNormalized = ToNext / ToNextDist;
			const FQuat ToNextQuat = Math::MakeQuatFromX(ToNextNormalized);
			NewTransform.SetRotation(ToNextQuat);
		}

		// scale
		const float Thickness = 0.3f;
		const float DefaultArrowLenght = DebugNextNodeArrow.ArrowSize * 80.f;
		const FVector NewScale = FVector(ToNextDist / DefaultArrowLenght, Thickness, Thickness);
		NewTransform.SetScale3D(NewScale);

		DebugNextNodeArrow.SetWorldTransform(NewTransform);
	}

	// returns loop index
	int GetNodeChainList(TArray<AWaternadoNode>& OutNodes)
	{
		// Use floyds cycle-finding algo
		AWaternadoNode SlowNode = this;
		AWaternadoNode FastNode = this;

		int LoopCounter = 0;

		OutNodes.Add(this);

		while(SlowNode.Next != nullptr)
		{
			SlowNode = SlowNode.Next;

			OutNodes.Add(SlowNode);

			if(FastNode != nullptr && FastNode.Next != nullptr)
				FastNode = FastNode.Next.Next;

			// Cycle detected
			if(SlowNode == FastNode)
			{
				// No loop, ended with dead end.
				if(SlowNode.Next == nullptr)
					break;

				// We'll need 2 instances of the looping node at the end for this to work
				if(OutNodes.Contains(SlowNode.Next))
				{
					OutNodes.Add(SlowNode.Next);
					return OutNodes.FindIndex(OutNodes.Last());
				}
			}

			// just in case..
			++LoopCounter;
			if(LoopCounter > 100)
			{
				ensure(false);
				return -1;
			}
		}

		// PrintToScreen("" + LoopCounter, Duration = 0.f);
		return -1;
	}

}

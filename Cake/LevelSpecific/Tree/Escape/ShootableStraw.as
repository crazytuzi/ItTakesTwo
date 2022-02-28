import Cake.FlyingMachine.FlyingMachineFlakProjectile;
import Cake.LevelSpecific.Tree.Escape.EscapeManager;

class AShootableStraw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;

	FVector Velocity;
	FVector AngularVelocity;

	bool bIsLaunched = false;

	TArray<AShootableStraw> StrawNeighbours;
	bool bHasFoundNeighbours = false;

	AFlyingMachine TargetMachine;
	bool bActiveCollision = true;

	float GravityFactor = 1.f;

	float ExpireTimer = 7.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Manager = GetEscapeManager();
		TargetMachine = Manager.TargetMachine;

		GravityFactor = FMath::RandRange(0.8f, 1.2f);
	}

	UFUNCTION()
	void DeactivateStrawCollision()
	{
		bActiveCollision = false;
	}

	UFUNCTION()
	TArray<AShootableStraw> GetNeighbouringStraws()
	{
		// Cached neighbours, if we have them
		if (bHasFoundNeighbours)
		{
			// First clean the cache of invalid actors..
			for(int i=StrawNeighbours.Num() - 1; i>=0; --i)
			{
				if (StrawNeighbours[i] == nullptr)
					StrawNeighbours.RemoveAtSwap(i);

				else if (StrawNeighbours[i].IsActorBeingDestroyed())
					StrawNeighbours.RemoveAtSwap(i);
			}

			return StrawNeighbours;
		}

		TArray<AShootableStraw> Neighbours;
		AActor Parent = this;

		// Find top parent
		while(Parent.GetAttachParentActor() != nullptr)
			Parent = Parent.GetAttachParentActor();

		CollectNeighbourStrawsIterative(Neighbours, Parent);
		return Neighbours;
	}

	void CollectNeighbourStrawsIterative(TArray<AShootableStraw>& OutStraws, AActor Root)
	{
		TArray<AActor> Children;
		Root.GetAttachedActors(Children);

		for(auto Child : Children)
		{
			CollectNeighbourStrawsIterative(OutStraws, Child);

			auto Straw = Cast<AShootableStraw>(Child);
			if (Straw == nullptr || Straw == this)
				continue;

			float DistSqrd = Straw.ActorLocation.DistSquared(ActorLocation);
			if (DistSqrd < FMath::Square(3000.f))
				OutStraws.Add(Straw);
		}
	}

	UFUNCTION()
	void LaunchStraw(FVector LaunchVelocity)
	{
		Velocity = LaunchVelocity;
		AngularVelocity = Math::GetRandomPointOnSphere() * FMath::RandRange(0.5f, 5.f);
		DetachRootComponentFromParent();

		bIsLaunched = true;
		DisableComp.SetUseAutoDisable(false);

		BP_OnLaunched();
	}

	UFUNCTION()
	void DetachSelfAndChildren()
	{
		// Already detached...
		if (GetAttachParentActor() == nullptr)
			return;

		Velocity = Collision.GetPhysicsLinearVelocity();
		DetachRootComponentFromParent();

		TArray<AActor> Children;
		GetAttachedActors(Children);

		for(auto Child : Children)
		{
			auto Straw = Cast<AShootableStraw>(Child);
			if (Straw == nullptr)
				continue;

			Straw.DetachSelfAndChildren();
		}

		DisableComp.SetUseAutoDisable(false);
	}

	UFUNCTION()
	void DetachSelfAndCloseby()
	{
		// Already detached...
		if (GetAttachParentActor() == nullptr)
			return;

		Velocity = Collision.GetPhysicsLinearVelocity();
		DetachRootComponentFromParent();

		TArray<AActor> OverlappingActors;
		Collision.GetOverlappingActors(OverlappingActors);

		for(auto Actor : OverlappingActors)
		{
			auto Straw = Cast<AShootableStraw>(Actor);
			if (Straw == nullptr)
				continue;

			Straw.DetachSelfAndCloseby();
		}

		DisableComp.SetUseAutoDisable(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bHasFoundNeighbours)
		{
			StrawNeighbours = GetNeighbouringStraws();
			bHasFoundNeighbours = true;
		}

		// Distance check to flying machine
		if (bActiveCollision)
		{
			float DistSqrd = ActorLocation.DistSquared(TargetMachine.ActorLocation);
			if (DistSqrd < FMath::Square(2000.f))
				BP_FlyingMachineCollision(TargetMachine);
		}

		if (GetAttachParentActor() != nullptr)
			return;

		// Physics stuff!
		FVector Position = ActorLocation;
		FQuat Rotation = ActorQuat;

		Velocity -= FVector::UpVector * 980.f * GravityFactor * DeltaTime;

		Position += Velocity * DeltaTime;
		FQuat DeltaQuat(AngularVelocity.GetSafeNormal(), AngularVelocity.Size() * DeltaTime);
		Rotation = Rotation * DeltaQuat;

		SetActorLocationAndRotation(Position, Rotation.Rotator());

		ExpireTimer -= DeltaTime;
		if (ExpireTimer <= 0.f)
			DestroyActor();
	}

	UFUNCTION(BlueprintEvent)
	void BP_FlyingMachineCollision(AFlyingMachine Machine) {}

	UFUNCTION(BlueprintEvent)
	void BP_OnDetached() {}

	UFUNCTION(BlueprintEvent)
	void BP_OnLaunched() {}
}
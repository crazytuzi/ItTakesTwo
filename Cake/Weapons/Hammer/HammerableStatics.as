
import Cake.Weapons.Hammer.HammerableComponent;

TArray<AActor> GetHammerableActorsFromActorList(const TArray<AActor>& InActors)
{
	TArray<AActor> OutHammerableActors;
	for (int i = 0; i < InActors.Num(); ++i)
	{
		AActor InActor = InActors[i];
		if (InActor != nullptr)
		{
			UHammerableComponent HammerableComponent = Cast<UHammerableComponent>(InActor.GetComponentByClass(UHammerableComponent::StaticClass()));
			if (HammerableComponent != nullptr)
			{
				OutHammerableActors.AddUnique(HammerableComponent.GetOwner());
			}
		}
	}
	return OutHammerableActors;
}

TArray<AActor> GetHammerableActorsFromComponentList(const TArray<UPrimitiveComponent>& InComponents)
{
	TArray<AActor> OutHammerableActors;
	for (int i = 0; i < InComponents.Num(); ++i)
	{
		if (InComponents[i] == nullptr)
			continue;

		if (IsComponentHammerable(InComponents[i]))
			OutHammerableActors.AddUnique(InComponents[i].GetOwner());
	}
	return OutHammerableActors;
}

bool ConeCullSphereTraceResult(
	const FVector& Location,
	const FVector& Direction,
	const float ConeTraceAngle,
	const float ConeTraceLength,
	TArray<UPrimitiveComponent>& OutConePrims,
	const TArray<UPrimitiveComponent>& InSpherePrims
)
{
	const FVector Padding = Direction * ConeTraceLength;
	const float AngleThreshold_RAD = FMath::DegreesToRadians(ConeTraceAngle);
	for (int i = 0; i < InSpherePrims.Num(); ++i)
	{
		FVector ClosestPointOnCollision;
		InSpherePrims[i].GetClosestPointOnCollision(
			Location + Padding,
			ClosestPointOnCollision,
			NAME_None
		);
		FVector ToClosestPoint = ClosestPointOnCollision - Location;
		ToClosestPoint.Normalize();
		const float AngleToClosestPoint_RAD = FMath::Acos(Direction.DotProduct(ToClosestPoint));
		if (FMath::Abs(AngleToClosestPoint_RAD) < AngleThreshold_RAD)
		{
			OutConePrims.Add(InSpherePrims[i]);
		}
	}

	// FLinearColor DebugColor = OutConePrims.Num() > 0 ? FLinearColor::Yellow : FLinearColor::White;
	// Debug::DrawDebugConeInDegrees
	// (
	// 	Location,
	// 	Direction,
	// 	ConeTraceLength,
	// 	ConeTraceAngle,
	// 	ConeTraceAngle,
	// 	16.f,
	// 	DebugColor,
	// 	1.f,
	// 	4.f
	// );

	return OutConePrims.Num() > 0;
}

bool GetHammerablePrimitivesFromConeTrace(
	TArray<UPrimitiveComponent>& OutHammerablePrimitives,
	const TArray<AActor>& ActorsToIgnore,
	const FVector& Location,
	const FVector& Direction,
	const float ConeTraceAngle,
	const float ConeTraceLength,
	ETraceTypeQuery InTraceTypeQuery,
	bool bDrawDebug = false
)
{
	TArray<UPrimitiveComponent> HammerablePrimitivesWithinSphere;
	GetHammerablePrimitivesFromSphereTrace(
		HammerablePrimitivesWithinSphere,
		ActorsToIgnore,
		Location,
		ConeTraceLength,
		InTraceTypeQuery
	);

#if TEST

	if (bDrawDebug && HammerablePrimitivesWithinSphere.Num() == 0)
	{
		FLinearColor DebugColor = OutHammerablePrimitives.Num() > 0 ? FLinearColor::Yellow : FLinearColor::Red;
		Debug::DrawDebugConeInDegrees
		(
			Location,
			Direction,
			ConeTraceLength,
			ConeTraceAngle,
			ConeTraceAngle,
			16.f,
			DebugColor,
			1.f,
			4.f
		);
	}

#endif


	if (HammerablePrimitivesWithinSphere.Num() <= 0)
		return false;

	const float AngleThreshold_RAD = FMath::DegreesToRadians(ConeTraceAngle);
	const FVector Padding = Direction * ConeTraceLength;

	for (int i = 0; i < HammerablePrimitivesWithinSphere.Num(); ++i)
	{
		FVector ClosestPointOnCollision;
		HammerablePrimitivesWithinSphere[i].GetClosestPointOnCollision(Location + Padding, ClosestPointOnCollision, NAME_None);
		FVector ToClosestPoint = ClosestPointOnCollision - Location;
		ToClosestPoint.Normalize();
		const float AngleToClosestPoint_RAD = FMath::Acos(Direction.DotProduct(ToClosestPoint));
		if (FMath::Abs(AngleToClosestPoint_RAD) < AngleThreshold_RAD)
		{
			OutHammerablePrimitives.Add(HammerablePrimitivesWithinSphere[i]);
		}
	}

#if TEST

	if (bDrawDebug)
	{
		FLinearColor DebugColor = OutHammerablePrimitives.Num() > 0 ? FLinearColor::Yellow : FLinearColor::White;
		Debug::DrawDebugConeInDegrees
		(
			Location,
			Direction,
			ConeTraceLength,
			ConeTraceAngle,
			ConeTraceAngle,
			16.f,
			DebugColor,
			1.f,
			4.f
		);
	}

#endif

	return OutHammerablePrimitives.Num() > 0;
}

bool GetHammerablePrimitivesFromSphereTrace
(
	TArray<UPrimitiveComponent>& OutComponents,
	TArray<AActor> ActorsToIgnore,
	FVector Origin,
	float Radius,
	ETraceTypeQuery InTraceTypeQuery
)
{
	TArray<UPrimitiveComponent> OverlapComponents;
	bool bHit = Trace::SphereOverlapComponentsMultiByChannel
	(
		OverlapComponents,
		Origin,
		Radius,
		InTraceTypeQuery,
		ActorsToIgnore,
		UPrimitiveComponent::StaticClass()
	);

	if (bHit == false)
		return false;

	OutComponents = GetHammerablePrimitivesFromComponentList(OverlapComponents);

	return OutComponents.Num() > 0;
}

bool GetHammerableActorsFromSphereTrace
(
	TArray<AActor>& OutActors,
	TArray<AActor> ActorsToIgnore,
	FVector Origin,
	float Radius,
	ETraceTypeQuery InTraceTypeQuery
)
{
	TArray<UPrimitiveComponent> OverlapComponents;
	bool bHit = Trace::SphereOverlapComponentsMultiByChannel
	(
		OverlapComponents,
		Origin,
		Radius,
		InTraceTypeQuery,
		ActorsToIgnore,
		UPrimitiveComponent::StaticClass()
	);

	if (bHit == false)
		return false;

	OutActors = GetHammerableActorsFromComponentList(OverlapComponents);

	return OutActors.Num() > 0;
}

TArray<UPrimitiveComponent> GetHammerablePrimitivesFromComponentList(const TArray<UPrimitiveComponent>& InComponents)
{
	TArray<UPrimitiveComponent> OutHammerableComponents;
	for (int i = 0; i < InComponents.Num(); ++i)
	{
		if (InComponents[i] == nullptr)
			continue;

		if (IsComponentHammerable(InComponents[i]))
			OutHammerableComponents.AddUnique(InComponents[i]);
	}
	return OutHammerableComponents;
}

UFUNCTION(Category = "HammerableStatics")
bool IsActorHammerable(AActor InActor) 
{
	if (InActor == nullptr)
		return false;

	TArray<UPrimitiveComponent> Prims;
	InActor.GetComponentsByClass(Prims);
	for (int i = 0; i < Prims.Num(); ++i)
	{
		if (Prims[i].HasTag(ComponentTags::Hammerable))
			return true;
	}

	return false;
}

UFUNCTION(Category = "HammerableStatics")
bool IsComponentHammerable(UPrimitiveComponent InPrimitiveComponent)
{
	auto InCompActor = InPrimitiveComponent.GetOwner();
	if (InCompActor == nullptr)
	{
		// Primitive without actor? Probably a BSP. @TODO: test without this once we have tags.
		return false;
	}
	return InPrimitiveComponent.HasTag(ComponentTags::Hammerable);
}


void NotifyHammerableComponentsOfHit(AActor ActorDoingTheHammering, TArray<UPrimitiveComponent> HammerablePrimitives)
{
	if (HammerablePrimitives.Num() <= 0)
		return;

	// Find all unique owners
	TArray<AActor> HammerableActors;
	for (UPrimitiveComponent HammerablePrimitive : HammerablePrimitives)
	{
		AActor HammerableActor = HammerablePrimitive.GetOwner();
		if (HammerableActors.Contains(HammerableActor))
			continue;
		HammerableActors.Add(HammerableActor);
	}

	for (AActor HammerableActor : HammerableActors)
	{
		// Find primitives associated with actor
		TArray<UPrimitiveComponent> HammerablePrimitivesWithSameOwner;
		for (UPrimitiveComponent HammerablePrimitive : HammerablePrimitives)
		{
			if (HammerablePrimitive.GetOwner() == HammerableActor)
			{
				HammerablePrimitivesWithSameOwner.Add(HammerablePrimitive);
			}
		}

		// push event for that actor
		UHammerableComponent HammerableComp = UHammerableComponent::Get(HammerableActor);
		if (HammerableComp != nullptr)
		{
			HammerableComp.PushHammeredEvent(ActorDoingTheHammering, HammerableActor, HammerablePrimitivesWithSameOwner);
		}
	}
}







































